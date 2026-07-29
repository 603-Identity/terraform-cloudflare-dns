variable "zone_id" {
  description = "Cloudflare Zone ID the records are managed in."
  type        = string
}

# `name` is passed through to the provider as given by the consumer -- the module does
# no zone-appending, so it works under either eventual answer below.
#
# Task 2 update: introspecting the pinned 5.22.0 provider's own generated schema
# (`tofu providers schema -json`, a local plugin read -- no credentials, no network
# call) shows `name`'s description as "DNS record name (or @ for the zone apex) in
# Punycode" -- the installed binary's stated intent agrees with the provider's
# published schema docs, not the v5 upgrade guide's FQDN-only claim. Note this is one
# source read at a pinned version, not two independent witnesses -- the published
# schema docs are generated from this same embedded schema, so what the check buys is
# elimination of *staleness* as the explanation for the contradiction, not
# corroboration. It's also not infallible: this same schema dump gives `content` the
# description "A valid IPv4 address", which is flatly wrong for the MX/TXT records this
# module also supports -- these generated descriptions are shape-approximate, not
# ground truth. Full empirical confirmation (a real plan/apply against a live zone) is
# still Task 5's job; treat short names / "@" as expected to work, not yet proven to.
#
# Separately, whether an explicit `proxied = false` sent on a non-proxiable type
# (MX/TXT) round-trips cleanly or causes permanent plan drift is NOT visible in the
# schema at all -- `proxied` is `optional, computed` with no type-conditional
# validation exposed (though the schema JSON format has no way to represent a validator
# at all, so this absence is weak evidence either way). Still open, still Task 5's job.
# `proxied` below is deliberately left nullable (no default) rather than defaulting to
# `false`, specifically so a consumer CAN omit it on MX/TXT records -- forcing an
# explicit `false` on every record would have foreclosed the null arm of this same
# question before Task 5 ever got to test it.
variable "records" {
  description = "DNS records to manage, keyed by a stable logical name so adding a record cannot renumber and destroy/recreate its neighbours in state."
  type = map(object({
    name     = string
    type     = string
    content  = string
    ttl      = optional(number, 1)
    proxied  = optional(bool)
    priority = optional(number)
    comment  = optional(string)
  }))
  default = {}
}
