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
# ground truth.
#
# RESOLVED (Task 5, 2026-07-29): `realinfra.tftest.hcl`'s
# "real_apply_settles_name_format_and_proxied_null" run applied three records against
# the live API in the scratch zone grovesknows.com -- a short/bare name
# (`tofu-ci-realinfra-short-probe`), a full FQDN
# (`tofu-ci-realinfra-fqdn-probe.grovesknows.com`), and the `@` apex alias -- and
# asserted each came back from the API with its `name` unchanged. All three passed:
# https://github.com/603-Identity/terraform-cloudflare-dns/actions/runs/30482316455.
# The provider's own schema docs were the ones that held; the v5 upgrade guide's
# "requires a full FQDN" claim does not describe what the live API actually does. Short
# names and "@" are both confirmed to work, not merely expected to.
#
# RESOLVED (IAC-BL-26, 2026-09-08): whether an omitted `proxied` on a non-proxiable type
# (MX/TXT) round-trips as `null` or gets silently defaulted by the live API was left open
# by the run above -- its MX probe (`mx_proxied_null_probe`) asserted on `priority` but
# not `proxied`. A follow-up assertion on
# `cloudflare_dns_record.this["mx_proxied_null_probe"].proxied == false` settled it on the
# first merge-time run after being added:
# https://github.com/603-Identity/terraform-cloudflare-dns/actions/runs/34284364667.
# The live API substitutes `false` for the omitted value on CREATE, not `null` -- matching
# the read-side evidence from Sprint 05 Task 1 (existing records also read back `false`).
# `proxied` below stays nullable (no default) rather than defaulting to `false` in this
# module's own schema: leaving it unset lets the provider apply its own substitution
# rather than the module asserting a value on the consumer's behalf, even though the two
# now happen to agree.
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
