output "record_ids" {
  description = "Cloudflare record ID for each managed record, keyed by the same logical name as var.records."
  value       = { for k, r in cloudflare_dns_record.this : k => r.id }
}
