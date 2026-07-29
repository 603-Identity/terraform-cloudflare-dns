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
# published schema docs, not the v5 upgrade guide's FQDN-only claim. This is stronger
# evidence than either doc page (it's the exact pinned version, not a web page that may
# be stale), but it is still what the schema *says*, not a live API round-trip -- the
# schema can't rule out server-side rejection of a short name. Full empirical
# confirmation (a real plan/apply against a live zone) is still Task 5's job; treat
# short names / "@" as expected to work, not yet proven to.
#
# Separately, whether an explicit `proxied = false` sent on a non-proxiable type
# (MX/TXT) round-trips cleanly or causes permanent plan drift is NOT visible in the
# schema at all -- `proxied` is `optional, computed` with no type-conditional
# validation exposed, so this depends entirely on the live API's write/read behavior.
# Still open, still Task 5's job.
variable "records" {
  description = "DNS records to manage, keyed by a stable logical name so adding a record cannot renumber and destroy/recreate its neighbours in state."
  type = map(object({
    name     = string
    type     = string
    content  = string
    ttl      = optional(number, 1)
    proxied  = optional(bool, false)
    priority = optional(number)
    comment  = optional(string)
  }))
  default = {}
}
