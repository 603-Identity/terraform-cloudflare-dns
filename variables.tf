variable "zone_id" {
  description = "Cloudflare Zone ID the records are managed in."
  type        = string
}

# `name` is passed through to the provider as given by the consumer. The v5 upgrade
# guide and the provider's own generated schema docs disagree on whether it must be a
# full FQDN or accepts a short name / "@" apex alias -- unresolved as of module init,
# to be settled empirically in Task 2/5 and documented here once decided.
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
