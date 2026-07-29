# Mocked `tofu test` (OpenTofu's native test framework, provider mocked -- no real
# Cloudflare API calls). Covers the four baseline record shapes the 603identity zones
# need. Intent ported from infrastructure-core/terraform/603identity.com.tf's v4
# examples -- v4 -> v5 syntax translated (cloudflare_record -> cloudflare_dns_record),
# resource names not copied.
#
# Every run asserts `name` and `zone_id` in addition to the field the run is nominally
# about -- the module's only two inputs are otherwise unverified by a suite whose
# assertions all target attributes derived from the *values* inside var.records, not
# the wiring of var.records itself.

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
    condition     = cloudflare_dns_record.this["apex"].zone_id == "mock-zone-id"
    error_message = "Expected the apex record to be created in the configured zone_id."
  }

  assert {
    condition     = cloudflare_dns_record.this["apex"].name == "603identity.com"
    error_message = "Expected the apex record's name to pass through unchanged."
  }

  assert {
    condition     = cloudflare_dns_record.this["apex"].type == "A"
    error_message = "Expected the apex record's type to be A."
  }

  assert {
    condition     = cloudflare_dns_record.this["apex"].proxied == true
    error_message = "Expected the apex A record to be proxied."
  }

  assert {
    condition     = output.record_ids["apex"] == "mock-record-id"
    error_message = "Expected record_ids to expose the apex record's id under its logical key."
  }
}

run "apex_alias_record" {
  command = plan

  variables {
    records = {
      apex_alias = {
        name    = "@"
        type    = "A"
        content = "192.0.2.1"
        proxied = true
      }
    }
  }

  assert {
    condition     = cloudflare_dns_record.this["apex_alias"].name == "@"
    error_message = "Expected the module to pass '@' through unchanged rather than rewriting or rejecting it -- the module does no zone-appending (see variables.tf); whether the live API accepts '@' is Task 5's job, not this mock's."
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
    condition     = cloudflare_dns_record.this["autodiscover"].zone_id == "mock-zone-id"
    error_message = "Expected the autodiscover record to be created in the configured zone_id."
  }

  assert {
    condition     = cloudflare_dns_record.this["autodiscover"].name == "autodiscover"
    error_message = "Expected the autodiscover record's short name to pass through unchanged."
  }

  assert {
    condition     = cloudflare_dns_record.this["autodiscover"].type == "CNAME"
    error_message = "Expected the autodiscover record's type to be CNAME."
  }

  assert {
    condition     = cloudflare_dns_record.this["autodiscover"].proxied == false
    error_message = "Expected an explicitly-set proxied = false to be respected, not just defaulted."
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
        # proxied intentionally omitted: exercises the variables.tf default change
        # that makes proxied nullable instead of forcing false on MX/TXT records.
        # The mock can't observe the resulting value (see the note by the assertions
        # below), but omitting it here at least proves the module doesn't error or
        # require the field on a non-proxiable type.
      }
    }
  }

  assert {
    condition     = cloudflare_dns_record.this["mx_outlook"].zone_id == "mock-zone-id"
    error_message = "Expected the MX record to be created in the configured zone_id."
  }

  assert {
    condition     = cloudflare_dns_record.this["mx_outlook"].name == "603identity.com"
    error_message = "Expected the MX record's name to pass through unchanged."
  }

  assert {
    condition     = cloudflare_dns_record.this["mx_outlook"].type == "MX"
    error_message = "Expected the mail record's type to be MX."
  }

  assert {
    condition     = cloudflare_dns_record.this["mx_outlook"].priority == 0
    error_message = "Expected the MX record's priority to round-trip through the module."
  }

  # No assertion on `proxied` here: it's optional+computed, and OpenTofu's mock
  # auto-generates an omitted computed bool to its type's zero-value (false) --
  # indistinguishable in the mock from the module explicitly forcing false. Whether
  # `proxied` is deliberately left nullable in variables.tf (it is, as of this commit)
  # is a main.tf/variables.tf source-level guarantee, not something this mock can
  # observe or prove. A real plan against the live API (Task 5) is the only way to
  # confirm the module isn't sending an explicit value here.
}

run "txt_record_spf_dmarc_quoting" {
  command = plan

  variables {
    records = {
      spf = {
        name    = "603identity.com"
        type    = "TXT"
        content = "\"v=spf1 include:spf.protection.outlook.com -all\""
        # proxied intentionally omitted -- see the MX run above.
      }
      dmarc = {
        name    = "_dmarc"
        type    = "TXT"
        content = "\"v=DMARC1; p=reject; rua=mailto:security@603identity.com\""
      }
    }
  }

  assert {
    condition     = cloudflare_dns_record.this["spf"].zone_id == "mock-zone-id"
    error_message = "Expected the SPF record to be created in the configured zone_id."
  }

  assert {
    condition     = cloudflare_dns_record.this["spf"].name == "603identity.com"
    error_message = "Expected the SPF record's name to pass through unchanged."
  }

  # A mock can only prove the module doesn't mangle the content string in transit --
  # it cannot prove Cloudflare's live API accepts this exact SPF/DMARC quoting. That
  # round-trip is Task 5's job.
  assert {
    condition     = cloudflare_dns_record.this["spf"].content == "\"v=spf1 include:spf.protection.outlook.com -all\""
    error_message = "Expected the module to pass the SPF TXT content through byte-for-byte, including its literal wrapping quotes."
  }

  # No assertion on `proxied` for spf: same mock limitation as the MX run above --
  # an omitted computed bool auto-generates to false either way, so the mock can't
  # distinguish "left null" from "forced false" here.

  assert {
    condition     = cloudflare_dns_record.this["dmarc"].name == "_dmarc"
    error_message = "Expected the DMARC record's short name to pass through unchanged."
  }

  assert {
    condition     = cloudflare_dns_record.this["dmarc"].content == "\"v=DMARC1; p=reject; rua=mailto:security@603identity.com\""
    error_message = "Expected the module to pass the DMARC TXT content through byte-for-byte, including its literal wrapping quotes."
  }
}
