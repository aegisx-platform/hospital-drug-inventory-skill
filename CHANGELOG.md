# Changelog

All notable changes to this skill are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); skill
versioning follows [SemVer](https://semver.org/) — bump **major** when
references/workflows change in a way that breaks generated code,
**minor** when adding a new reference or domain, **patch** for wording fixes.

## [Unreleased]

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
