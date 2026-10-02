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
recorded in full in this section. A decision shared with another repo, or one that binds the
whole org, belongs in infrastructure-core's log as an `IAC-D` entry instead (CFDNS-D1,
applying IAC-D48).

### CFDNS-D decisions

#### CFDNS-D1: Repo-local decisions use `CFDNS-D`; shared and org-wide decisions stay `IAC-D`

**Resolved** 2026-09-28 by the repo owner, when this repo adopted the way-of-working v0.13.0
schema (#38).

**Context.** Before v0.13.0 this repo set `decisions.log: null` and `decisions.prefix: IAC-D`.
Every decision was numbered in infrastructure-core's series so that no competing series
existed. v0.13.0 no longer allows a null `decisions.log`, so this repo needs a log of its own.
A local log that used `IAC-D` numbers could collide with the hub's numbering.

**Decision.**
- A decision that affects only this repo is numbered `CFDNS-D<N>` and recorded in full in this
  file.
- A decision that affects more than one repo, or the whole org, is numbered `IAC-D<N>` and
  recorded in infrastructure-core's `docs/iac_migration_roadmap.md`. This file cites it in
  the table below and does not copy it.
- When a decision is unclear, ask whether any other repo would have to change because of it.
  If one would, the decision is `IAC-D`.

**Consequences.** Each series has a single numbering authority, so numbers cannot collide.
The other module repos face the same choice when they adopt v0.13.0, which makes the pattern
itself a shared decision. It is recorded org-wide as IAC-D48 (infrastructure-core#545). This
entry applies IAC-D48 to this repo.

### Org-wide IAC-D decisions that bind this repo

Each of these is recorded in full in infrastructure-core's log. They are cited here only.

| Id | Summary | Where it shows up here |
|----|---------|------------------------|
| IAC-D3 | Branch-protection rulesets need a paid plan on a private repo. This was resolved once the org moved to Team. | `ruleset` in `.ai/project.yml` |
| IAC-D13 | Gave this repo its Dependabot config. | `.github/dependabot.yml` |
| IAC-D14 | Work branches live on the org repo, not a personal fork, because fork PRs silently ran no CI. The "absent-check trap" that later text attributes to this decision is also why required-check names are read from each workflow's `name:` field and never typed from memory. | Branches on `603-Identity/terraform-cloudflare-dns`; `ruleset.required_checks` |
| IAC-D47 | Checkov accepted findings live in a human-reviewed ledger checked by `checkov-ledger-action`. | `checkov-ledger.json` |
| IAC-D48 | Each repo numbers its own decisions in a local series; shared and org-wide decisions stay `IAC-D`. Module repos keep a README-only `sprints/` because they plan sprints as milestones. | CFDNS-D1; `decisions` and `sprints_dir` in `.ai/project.yml`; `sprints/` |
