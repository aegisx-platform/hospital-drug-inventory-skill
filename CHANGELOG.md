# Changelog

All notable changes to this skill are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); skill
versioning follows [SemVer](https://semver.org/) — bump **major** when
references/workflows change in a way that breaks generated code,
**minor** when adding a new reference or domain, **patch** for wording fixes.

## [Unreleased]

## [1.0.1] - 2026-04-15

### Changed
- Slimmed `SKILL.md` (6.2KB → ~3KB) for faster activation: moved Regulatory
  Foundation detail to `references/regulatory-framework.md` and Workflow Quick
  Reference to `references/patterns.md`. `SKILL.md` now holds only the
  non-negotiable rules + router.
- README: added CI/release/license badges, user-scope one-liner, pinned-tarball
  install, and uninstall section.

## [1.0.0] - 2026-04-15

### Added
- Initial skill package with 5-stage MOPH workflow (Selection → Distribution)
- 8 reference files: regulatory-framework, drug-master-data, budget-procurement,
  warehouse-receiving, dispensing-substore, dmsic-5-file, prisma-schema, patterns
- Example code: Prisma model, Fastify goods-receiving route, Angular dispensing
  component
- `scripts/install.sh`, `scripts/uninstall.sh`, `scripts/validate.sh`
- GitHub Actions validation workflow
- Proprietary LICENSE (internal use)

### Regulatory Foundation
- พ.ร.บ.จัดซื้อจัดจ้าง 2560
- ระเบียบ สธ. 2563
- เกณฑ์จริยธรรม 2564
- ประกาศ สธ. 2568 (DMSIC 5-file)
