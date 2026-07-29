# terraform-cloudflare-dns

Reusable OpenTofu module for managing Cloudflare DNS records within a single zone.
Instantiated once per zone by a consuming tenant repo (`for_each` over zones), so a
multi-TLD tenant like `603identity` composes it multiple times rather than the module
trying to own more than one zone at a time.

## Usage

```hcl
module "dns_603identity_com" {
  source  = "git::https://github.com/603-Identity/terraform-cloudflare-dns.git?ref=v0.1.0"

  zone_id = var.zone_id_603identity_com
  records = {
    root_a = {
      name    = "603identity.com"
      type    = "A"
      content = "192.0.2.1"
      proxied = true
    }
    spf = {
      name    = "603identity.com"
      type    = "TXT"
      content = "\"v=spf1 include:spf.protection.outlook.com -all\""
    }
  }
}
```

> **Providers:** This module does not contain a `provider` block. The consuming
> repository must configure the `cloudflare` provider and supply credentials (e.g. via
> OIDC-federated identity in CI, not a static token).

## CNAME Flattening and Apex Collisions

Records placed at the zone apex (`@`) — such as `MX` or `TXT` — can collide with a
`CNAME` another module or consumer wants at the same apex (e.g. a Framer or Vercel
deployment). If composing this module alongside others that need an apex `CNAME`,
ensure Cloudflare's **CNAME Flattening** is enabled on the zone.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `zone_id` | Cloudflare Zone ID the records are managed in. | `string` | n/a | yes |
| `records` | DNS records to manage, keyed by a stable logical name. | `map(object({...}))` | `{}` | no |

Each `records` entry is `{ name, type, content, ttl, proxied, priority, comment }`:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `name` | `string` | n/a | Required. Short/bare names and the `@` apex alias are both confirmed to work against the live API (Task 5, 2026-07-29) -- see `variables.tf`'s comment. |
| `type` | `string` | n/a | Required. |
| `content` | `string` | n/a | Required. |
| `ttl` | `number` | `1` | `1` = Cloudflare "automatic". |
| `proxied` | `bool` | `null` | Only meaningful for proxiable types (`A`/`AAAA`/`CNAME`). Left unset (not forced to `false`) on other types so the provider owns the value -- see `variables.tf`. |
| `priority` | `number` | `null` | Only meaningful for types like `MX` that use it. |
| `comment` | `string` | `null` | Optional freeform note. |

## Outputs

| Name | Description |
|------|-------------|
| `record_ids` | Cloudflare record ID for each managed record, keyed by the same logical name as `var.records`. |
