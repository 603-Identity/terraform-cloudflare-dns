# Threat model

Ground truth for `security-critic` (and any other reviewer) on this module's untrusted inputs,
dangerous sinks, credential holders, and the trust boundaries its design depends on holding. This
file names the **what** — its own scannable list, kept separate from `README.md` so a reviewer
never has to extract it from usage prose first. It points into `README.md` and this repo's
workflow files for the **why** and the mechanics of where each boundary is actually enforced,
rather than duplicating that detail here. Shape follows `terraform-microsoft365-entra`'s
`docs/threat_model.md` and `infrastructure-core`'s own — the two existing references in this
estate (infrastructure-core#476).

This module manages Cloudflare DNS records (`cloudflare_dns_record`) within a single zone via the
Cloudflare API. It declares no `provider` block itself — credentials are always the consuming
repo's responsibility. Its own CI reaches a Cloudflare API token indirectly, through an
AWS-OIDC-assumed role and SSM Parameter Store, rather than holding one directly. The property
everything below is organized around: this module's own CI must never be able to reach more than
the one zone (and, at merge time, the one disposable scratch zone) it is scoped to, and no
Cloudflare token may ever appear in a log, an environment dump, or a diff a reviewer sees.

## Untrusted / reviewer-unwitnessed inputs

- A consumer's own `records` map (`variables.tf`'s declared input): `name`, `type`, `content`,
  `ttl`, `proxied`, `priority`, `comment` all pass straight through to the provider with no
  `variable` `validation` block. This module trusts the consuming repo's own review process to
  catch a malformed record, not a guard here — see README's Inputs table for the full shape.
- PR comment and PR review bodies, once `architect-review-gate.yml` lands
  (infrastructure-core#476 step 3) — externally-authored content, matched only by literal,
  quoted `contains()` substring checks, never interpolated into a shell command or used to
  select which commit a status posts against (the workflow resolves that from the PR API
  itself, not from the comment).

## Credential holders

- `terraform-cloudflare-dns-cicd-test-read` (AWS IAM role, `infrastructure-core`'s
  `bootstrap/main.tf`), assumed via GitHub OIDC by `merge-real-infra-test.yml` on push to
  `main` (or a matching manual `workflow_dispatch`). Scoped to exactly `ssm:GetParameter` on
  two parameters plus `kms:Decrypt` on the one key protecting them — no standing Cloudflare
  token lives in this repo, no client secret, no long-lived AWS key.
- The Cloudflare API token itself, held only in AWS SSM Parameter Store
  (`/terraform-cloudflare-dns/cicd-test/*`), fetched once per merge-time run and never written
  to disk — see "Dangerous sinks" below for the one workflow that touches it.
- Every consuming repo's own `cloudflare` provider credential — entirely outside this module's
  control; this module only ever receives an already-authenticated provider.

## Dangerous sinks

- Every `cloudflare_dns_record` create/update/destroy this module or its tests issue against
  the real Cloudflare API.
- `merge-real-infra-test.yml`'s two SSM-fetch steps: the one place in this repo's CI where a
  live Cloudflare API token exists in a job's environment. Masked immediately
  (`::add-mask::`) the instant it's captured, and the AWS session itself is explicitly cleared
  from `$GITHUB_ENV` before `tofu init`/`tofu test` run, so neither a freshly-fetched provider
  plugin nor a test's own code ever executes with the AWS credential still live alongside it.
- `tofu init`/`tofu test` in PR-triggered CI (`pull-request.yml`) fetches and stages the
  pinned `cloudflare/cloudflare` provider binary from unmerged, unreviewed PR content, same as
  every OpenTofu-based repo in this org — mitigated by that provider being version-pinned
  (`versions.tf`) and this repo's mocked test (`main.tftest.hcl`) never touching a real
  credential.

## Boundaries meant to hold, and where each is enforced

- **No Cloudflare credential ever exists in PR-triggered CI.** `pull-request.yml` needs no
  credentials and cannot reach a real zone; the only workflow with any credential-bearing step
  is `merge-real-infra-test.yml`, gated to `push: branches: [main]` (its trusted OIDC subject
  is pinned to `ref:refs/heads/main`) plus a manually-triggered `workflow_dispatch` that
  authenticates under the same pin.
- **The merge-time test can only ever reach the disposable scratch zone.** `realinfra.tftest.hcl`
  takes its zone from `TF_VAR_zone_id`, sourced only from the
  `/terraform-cloudflare-dns/cicd-test/cloudflare_zone_id` SSM parameter — there is no code path
  in this module or its CI that lets a PR-supplied value reach a real zone ID.
- **A fetched secret is masked and cleared before it can reach untrusted code.** Both SSM
  fetches in `merge-real-infra-test.yml` reject an empty or non-printable value outright (a
  multi-line value could otherwise inject arbitrary `$GITHUB_ENV` entries), mask the token the
  instant it's captured, and blank the AWS session out of the job environment before `tofu
  init`/`tofu test` run — neither step needs AWS credentials, so this bounds how much of the
  job can reach them if either is later compromised.
- **`proxied` is left unset, not defaulted, on non-proxiable types.** `variables.tf` declares it
  `optional(bool)` with no default so a plan diff shows the provider's own substitution, not a
  value this module silently asserted — confirmed live (IAC-BL-26) that the API substitutes
  `false` on create either way, but the module doesn't get there by guessing on the consumer's
  behalf.
- **Every PR-time check runs against a mock.** `main.tftest.hcl`'s `mock_provider "cloudflare"`
  block means `pull-request.yml`'s `tofu-test` job makes zero live Cloudflare API calls; only
  `realinfra.tftest.hcl` — filtered out of every PR-triggered run via `-filter=main.tftest.hcl`
  — touches the real API, and only from the merge-time workflow above.
