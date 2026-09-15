resource "cloudflare_dns_record" "this" {
  for_each = var.records

  zone_id  = var.zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  ttl      = each.value.ttl
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
}

# Sprint 15 T6 -- live falsification fixture, planted deliberately to prove
# checkov-ledger.json's known_invisible entry turns red when the root
# directory starts producing Checkov results. Reverted in the next commit.
resource "aws_s3_bucket" "sprint15_t6_falsification_probe" {
  bucket = "checkov-ledger-t6-falsification-probe"
}
