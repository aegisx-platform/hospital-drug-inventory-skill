# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This repo is **not application code** — it is a Claude Code **skill package** (`hospital-drug-inventory`) that teaches Claude how to build/extend the hospital drug inventory module of the AegisX Platform (Angular 19 + Fastify + Prisma + PostgreSQL, multi-tenant across 20+ hospital sites). The whole "build/test/lint" loop lives in the consuming app, not here.

Layout:
- `SKILL.md` — entry point loaded by Claude when the skill activates. Contains architecture overview, regulatory foundation, common patterns, anti-patterns, and a router table that points to `references/*.md`.
- `references/*.md` — domain deep-dives. Read **only the file relevant to the task**, not all of them. Router lives in `SKILL.md` § "Domain Reference Files".
- `README.md` — human-facing summary + install instructions (`cp -r .` into a target project's `.claude/skills/`).
- `scripts/` — currently empty.

## Working in this repo

When editing skill content:
- Keep `SKILL.md` as a thin index. Push detail down into the matching `references/*.md` so Claude doesn't load 7 files when it only needs 1.
- The frontmatter `description:` in `SKILL.md` is the activation trigger — preserve the Thai keywords (คลังยา, เบิกจ่ายยา, จัดซื้อยา, DMSIC, TMT, FEFO, ...) when rewriting; removing them silently breaks discovery.
- Regulatory citations (พ.ร.บ.จัดซื้อจัดจ้าง 2560, ระเบียบ สธ. 2563 ข้อ 11, เกณฑ์จริยธรรม 2564 ข้อ 13/15(2), ประกาศ สธ. 2568 5 แฟ้ม) are load-bearing — they're how downstream code justifies design choices. Don't paraphrase away the article numbers.

## Non-negotiable domain rules (enforced wherever this skill is consumed)

These come from `SKILL.md` and must be respected in any code Claude generates from this skill:
1. **Append-only stock journal** — never `UPDATE` stock rows; insert journal entries with `direction: IN|OUT` in **base unit**.
2. **Separation of duties** — a user cannot simultaneously hold `PURCHASER` and `WAREHOUSE_KEEPER` roles (ระเบียบ สธ. 2563 ข้อ 11).
3. **Net price only** — no discount/rebate fields on PO lines (เกณฑ์จริยธรรม 2564 ข้อ 15(2)).
4. **Generic name primary** — generic name is the primary display; trade name is secondary (ข้อ 13).
5. **Multi-site isolation** — every query carries `hospitalId`; never cross-site.
6. **FEFO** — lot selection orders by `expiryDate asc`.
7. **DMSIC reference price check** — alert when PO unit price exceeds DMSIC reference.

## Distribution

There is no build step, no test runner, no lint config. Validation = the skill loads cleanly into a target project at `.claude/skills/hospital-drug-inventory/` and `SKILL.md` activates on the documented Thai/English triggers.
