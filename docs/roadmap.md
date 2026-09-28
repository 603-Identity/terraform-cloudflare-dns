# terraform-cloudflare-dns — roadmap

This module's own record: where it stands, what comes next, and which decisions bind it.
The org-wide migration roadmap and the IAC-D decision log of record are in
[603-Identity/infrastructure-core `docs/iac_migration_roadmap.md`](https://github.com/603-Identity/infrastructure-core/blob/main/docs/iac_migration_roadmap.md).
This file points into that log and does not duplicate it.

## Status

The module is in use, with a required-checks ruleset (`main-required-checks`) and a
fresh-session review gate (`architect-review`) live on `main`. `.ai/project.yml` records
both.

## Next action

The next piece of work is set by the open milestone on this repo, since
`planning.kind: github_milestones`. With no open milestone, the next step is to run
`/way-of-working:plan-sprint` to triage open issues into one.

## Planning and backlog

- Findings are GitHub issues on this repo, cited `#N`.
- Each sprint is one milestone on this repo, and its issues are the task list.
- Findings recorded before this repo had its own tracker are `IAC-BL-N` items in
  infrastructure-core, cited by that id. Examples are IAC-BL-23, IAC-BL-24 and IAC-BL-26.

## Decisions

Decisions made for this repo alone are numbered `CFDNS-D1`, `CFDNS-D2`, and so on, and are
recorded in full in this section. A decision that binds every repo in the org belongs in
infrastructure-core's log as an `IAC-D` entry instead.

### CFDNS-D decisions

None yet.

### Org-wide IAC-D decisions that bind this repo

Each of these is recorded in full in infrastructure-core's log. They are cited here only.

| Id | Summary | Where it shows up here |
|----|---------|------------------------|
| IAC-D3 | Branch-protection rulesets need a paid plan on a private repo. This was resolved once the org moved to Team. | `ruleset` in `.ai/project.yml` |
| IAC-D13 | Gave this repo its Dependabot config. | `.github/dependabot.yml` |
| IAC-D47 | Checkov accepted findings live in a human-reviewed ledger checked by `checkov-ledger-action`. | `checkov-ledger.json` |
| IAC-D14 | The absent-check trap: required-check names are read from each workflow's `name:` field and never typed from memory. It also bars fork PRs. | `ruleset.required_checks` |
