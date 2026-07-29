# Mocked `tofu test` (OpenTofu's native test framework, provider mocked -- no real
# Cloudflare API calls). Covers the four baseline record shapes the 603identity zones
# need. Intent ported from infrastructure-core/terraform/603identity.com.tf's v4
# examples -- v4 -> v5 syntax translated (cloudflare_record -> cloudflare_dns_record),
# resource names not copied.

mock_provider "cloudflare" {
  mock_resource "cloudflare_dns_record" {
    defaults = {
      id = "mock-record-id"
    }
  }
}

variables {
  zone_id = "mock-zone-id"
}

run "proxied_a_record" {
  command = plan

  variables {
    records = {
      apex = {
        name    = "603identity.com"
        type    = "A"
        content = "192.0.2.1"
        proxied = true
      }
    }
  }

  assert {
    condition     = cloudflare_dns_record.this["apex"].type == "A"
    error_message = "Expected the apex record's type to be A."
  }

  assert {
    condition     = cloudflare_dns_record.this["apex"].proxied == true
    error_message = "Expected the apex A record to be proxied."
  }
}

run "unproxied_cname_record" {
  command = plan

  variables {
    records = {
      autodiscover = {
        name    = "autodiscover"
        type    = "CNAME"
        content = "autodiscover.outlook.com"
        proxied = false
      }
    }
  }

  assert {
    condition     = cloudflare_dns_record.this["autodiscover"].type == "CNAME"
    error_message = "Expected the autodiscover record's type to be CNAME."
  }

  assert {
    condition     = cloudflare_dns_record.this["autodiscover"].proxied == false
    error_message = "Expected the autodiscover CNAME to be unproxied."
  }
}

run "mx_record_with_priority" {
  command = plan

  variables {
    records = {
      mx_outlook = {
        name     = "603identity.com"
        type     = "MX"
        content  = "603identity-com.mail.protection.outlook.com"
        priority = 0
        proxied  = false
      }
    }
  }

  assert {
    condition     = cloudflare_dns_record.this["mx_outlook"].type == "MX"
    error_message = "Expected the mail record's type to be MX."
  }

  assert {
    condition     = cloudflare_dns_record.this["mx_outlook"].priority == 0
    error_message = "Expected the MX record's priority to round-trip through the module."
  }
}

run "txt_record_spf_dmarc_quoting" {
  command = plan

  variables {
    records = {
      spf = {
        name    = "603identity.com"
        type    = "TXT"
        content = "\"v=spf1 include:spf.protection.outlook.com -all\""
      }
      dmarc = {
        name    = "_dmarc"
        type    = "TXT"
        content = "\"v=DMARC1; p=reject; rua=mailto:security@603identity.com\""
      }
    }
  }

  assert {
    condition     = cloudflare_dns_record.this["spf"].content == "\"v=spf1 include:spf.protection.outlook.com -all\""
    error_message = "Expected the SPF TXT content to keep its literal wrapping quotes."
  }

  assert {
    condition     = cloudflare_dns_record.this["dmarc"].content == "\"v=DMARC1; p=reject; rua=mailto:security@603identity.com\""
    error_message = "Expected the DMARC TXT content to keep its literal wrapping quotes."
  }
}
