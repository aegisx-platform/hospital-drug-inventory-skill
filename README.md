# Hospital Drug Inventory Management — Claude Skill

[![validate](https://github.com/aegisx-platform/hospital-drug-inventory-skill/actions/workflows/validate.yml/badge.svg)](https://github.com/aegisx-platform/hospital-drug-inventory-skill/actions/workflows/validate.yml)
[![release](https://img.shields.io/github/v/release/aegisx-platform/hospital-drug-inventory-skill?sort=semver)](https://github.com/aegisx-platform/hospital-drug-inventory-skill/releases)
[![license](https://img.shields.io/badge/license-Proprietary-lightgrey)](LICENSE)

Claude Code skill สำหรับระบบบริหารจัดการคลังเวชภัณฑ์โรงพยาบาล (AegisX Platform)

ครอบคลุม supply chain 5 ขั้นตอนตามระเบียบกระทรวงสาธารณสุข:
**คัดเลือก → ประมาณการ → จัดซื้อ → เก็บสำรอง → กระจาย/จ่ายผู้ป่วย**

## Regulatory Foundation

1. พ.ร.บ.จัดซื้อจัดจ้าง 2560 + กฎกระทรวง 2563
2. ระเบียบ สธ. 2563 ว่าด้วยการบริหารจัดการด้านยาและเวชภัณฑ์
3. เกณฑ์จริยธรรม 2564 (ราคาสุทธิ, generic name primary)
4. ประกาศ สธ. 2568 — มาตรฐานข้อมูล DMSIC 5 แฟ้ม
5. ระบบราคาอ้างอิง DMSIC (อัพเดททุก 3–4 เดือน)
6. นโยบายพัฒนาประสิทธิภาพบริหารเวชภัณฑ์ (ตั้งแต่ 2542)

## Installation

### User scope (ใช้ได้ทุก project)
```bash
git clone https://github.com/aegisx-platform/hospital-drug-inventory-skill.git /tmp/hdi \
  && /tmp/hdi/scripts/install.sh --user \
  && rm -rf /tmp/hdi
```

### Project scope
```bash
./scripts/install.sh /path/to/your-project
```

### Claude Desktop
```bash
./scripts/install.sh --desktop
```

### จาก release tarball (pin version)
```bash
VERSION=v1.0.1
curl -L "https://github.com/aegisx-platform/hospital-drug-inventory-skill/archive/refs/tags/${VERSION}.tar.gz" | tar xz -C /tmp
/tmp/hospital-drug-inventory-skill-${VERSION#v}/scripts/install.sh --user
```

### Uninstall
```bash
./scripts/uninstall.sh --user     # หรือ <project-dir> / --desktop
```

### Verify

หลังติดตั้งเปิด Claude Code แล้วถามคำถามที่มี keyword เช่น "ออกแบบ stock journal สำหรับคลังยา" — skill จะ activate อัตโนมัติจาก trigger words ใน `SKILL.md`

## Structure

```
SKILL.md              — entry point (thin index, ~3KB)
references/           — domain deep-dives (อ่านเฉพาะที่เกี่ยวข้อง)
├── regulatory-framework.md   กรอบกฎหมาย + KPI 16 ตัว + timeline + แบบฟอร์ม
├── drug-master-data.md       TMT, unit conversion, ED/NED/VEN
├── budget-procurement.md     แผน/PR/PO, จัดซื้อร่วม, DMSIC reference price
├── warehouse-receiving.md    GR, lot/batch, stock adjustment
├── dispensing-substore.md    เบิกจ่าย, จ่ายผู้ป่วย, utilization
├── dmsic-5-file.md           ส่ง 5 แฟ้มรายเดือน (ประกาศ 2568)
├── prisma-schema.md          data model, enums, relations
└── patterns.md               stock journal, FEFO, RBAC — อ่านก่อนเขียนโค้ด
examples/             — Prisma / Fastify / Angular snippets พร้อม adapt
scripts/              — install.sh / uninstall.sh / validate.sh
```

## Key Business Rules

| Rule | Source |
|------|--------|
| ผู้จัดซื้อ ≠ ผู้ควบคุมคลัง | ระเบียบ สธ. 2563 ข้อ 11 |
| ราคาสุทธิเท่านั้น (ไม่มี rebate) | เกณฑ์จริยธรรม 2564 ข้อ 15(2) |
| สั่งยาด้วยชื่อสามัญ | เกณฑ์จริยธรรม 2564 ข้อ 13 |
| คงคลัง ≤ 2 เดือน | มาตรฐาน สธ. |
| Min stock = ใช้/ปี ÷ 12 | มาตรฐาน สธ. |
| ข้อมูลใช้ยา 3 ปีย้อนหลัง | ระเบียบ 2563 เอกสารแนบท้าย |
| ส่ง DMSIC 5 แฟ้มทุกเดือน | ประกาศ สธ. 2568 |

## Tech Stack (target consumer)

Angular 19 + Angular Material v3 + TailwindCSS / Fastify + Prisma ORM + PostgreSQL / 20+ multi-tenant hospital sites

## Contributing

ดู `CHANGELOG.md` ก่อนเพิ่ม reference ใหม่ — bump version ตาม SemVer (major เมื่อ workflow/schema เปลี่ยนจนกระทบ generated code)

## License

Proprietary — Internal use within AegisX Platform and affiliated hospitals (ดู `LICENSE`)
