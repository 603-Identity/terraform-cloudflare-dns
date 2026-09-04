# REAL Cloudflare API test (Sprint 04 Task 5, merge-time only). Deliberately has NO
# mock_provider -- unlike main.tftest.hcl, this exercises the live v5 provider
# against the disposable scratch zone 603identity.site (IAC-D15, amended; IAC-D33).
# Authenticated via CLOUDFLARE_API_TOKEN in the environment (fetched from AWS SSM Parameter Store in
# CI via OIDC, see .github/workflows/merge-real-infra-test.yml) -- never a provider block, never a
# credential in this file, matching the module's own "no provider block, no
# credentials" design. zone_id comes from TF_VAR_zone_id in the environment, never
# hardcoded here.
#
# `command = apply` (unlike main.tftest.hcl's `command = plan`) is what makes this a
# REAL test: OpenTofu provisions each record against the live API, asserts on what
# the API actually returned, then destroys everything when the file finishes --
# built-in `tofu test` cleanup, no separate teardown step needed, and no persistent
# backend means each CI run starts and ends with zero state. Every record name is
# unambiguously CI/disposable so a human reading the zone never mistakes one for
# production DNS.
#
# This settles empirically what main.tftest.hcl's mock could only leave open (see
# variables.tf's comment): whether a short/bare `name` and the `@` apex alias are
# accepted by the live API (the v5 upgrade guide and the provider's own schema docs
# disagree), and how the live API actually returns `proxied` when a non-proxiable
# record (MX) omits it. Whatever this run block shows -- including a hard failure
# on one of the name arms -- IS the answer; update variables.tf's comment and the
# README with the settled result after the first real run.
#
# KNOWN LIMITATION: if a run's teardown does not complete (e.g. the runner is killed
# mid-job), a stale duplicate probe record could be left in 603identity.site until the
# next successful run's apply happens to collide with it. Check the zone's record
# list occasionally; nothing here can protect against a hard kill mid-destroy.

run "real_apply_settles_name_format_and_proxied_null" {
  command = apply

  variables {
    records = {
      # Short/bare name (no zone suffix). The v5 upgrade guide claims this is
      # rejected in favor of a full FQDN; the provider's own generated schema docs
      # claim the opposite (see variables.tf). If this arm fails outright, that
      # failure is the answer.
      short_name_probe = {
        name    = "tofu-ci-realinfra-short-probe"
        type    = "TXT"
        content = "\"terraform-cloudflare-dns CI real-infra probe (short name arm) -- Sprint 04 Task 5, safe to delete, recreated on every merge to main\""
        ttl     = 60
        comment = "CI-managed disposable probe (short name arm) -- do not hand-edit"
      }

      # Full FQDN form, as a control -- expected to work under either reading of
      # the contradiction above.
      fqdn_probe = {
        name    = "tofu-ci-realinfra-fqdn-probe.603identity.site"
        type    = "TXT"
        content = "\"terraform-cloudflare-dns CI real-infra probe (FQDN arm) -- Sprint 04 Task 5, safe to delete, recreated on every merge to main\""
        ttl     = 60
        comment = "CI-managed disposable probe (FQDN arm) -- do not hand-edit"
      }

      # `@` apex alias, mirroring main.tftest.hcl's mocked "apex_alias_record" run --
      # this is the live-API confirmation the mock could not provide.
      apex_alias_probe = {
        name    = "@"
        type    = "TXT"
        content = "\"terraform-cloudflare-dns CI real-infra probe (apex alias arm) -- Sprint 04 Task 5, safe to delete, recreated on every merge to main\""
        ttl     = 60
        comment = "CI-managed disposable probe (apex alias arm) -- do not hand-edit"
      }

      # MX with `proxied` intentionally omitted, mirroring main.tftest.hcl's mocked
      # "mx_record_with_priority" run -- settles what the live API actually returns
      # (null preserved, or silently substituted) where the mock could not observe
      # it at all.
      mx_proxied_null_probe = {
        name     = "tofu-ci-realinfra-mx-probe.603identity.site"
        type     = "MX"
        content  = "tofu-ci-realinfra-mx-target.603identity.site"
        priority = 50
        comment  = "CI-managed disposable probe (proxied-null arm) -- do not hand-edit"
      }
    }
  }

  assert {
    condition     = cloudflare_dns_record.this["short_name_probe"].name == "tofu-ci-realinfra-short-probe"
    error_message = "Live API rejected or rewrote the short/bare name -- if this fires, the v5 upgrade guide's FQDN-only claim is the one that held, not the schema docs. Record the settled answer in variables.tf and the README either way."
  }

  assert {
    condition     = cloudflare_dns_record.this["fqdn_probe"].name == "tofu-ci-realinfra-fqdn-probe.603identity.site"
    error_message = "Expected the FQDN-form name to round-trip unchanged."
  }

  assert {
    condition     = cloudflare_dns_record.this["apex_alias_probe"].name == "@"
    error_message = "Live API rejected or rewrote the '@' apex alias -- record the settled answer in variables.tf and the README."
  }

  assert {
    condition     = cloudflare_dns_record.this["mx_proxied_null_probe"].priority == 50
    error_message = "Expected the MX record's priority to round-trip through the live API."
  }
}
