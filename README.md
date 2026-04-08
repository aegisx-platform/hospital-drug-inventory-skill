# Hospital Drug Inventory Management — Claude Skill

Claude Code skill สำหรับระบบบริหารจัดการคลังเวชภัณฑ์โรงพยาบาล (AegisX Platform)

ออกแบบตามกรอบระเบียบกระทรวงสาธารณสุข ครอบคลุมทั้ง supply chain ตั้งแต่คัดเลือกรายการยา → ประมาณการ → จัดซื้อ → เก็บสำรอง → กระจาย/จ่ายผู้ป่วย

## Regulatory Foundation (6 ชั้น)

1. **พ.ร.บ.จัดซื้อจัดจ้าง 2560** + กฎกระทรวง 2563
2. **ระเบียบ สธ. 2563** ว่าด้วยการบริหารจัดการด้านยาและเวชภัณฑ์ที่มิใช่ยา
3. **เกณฑ์จริยธรรม 2564** การจัดซื้อจัดหาและส่งเสริมการขายยาฯ
4. **นโยบายพัฒนาประสิทธิภาพบริหารเวชภัณฑ์** (ตั้งแต่ 2542)
5. **ระบบราคาอ้างอิง DMSIC** (อัพเดททุก 3-4 เดือน)
6. **ประกาศ สธ. 2568** มาตรฐานข้อมูลบริหารเวชภัณฑ์ 5 แฟ้ม

## Structure

```
SKILL.md                              — ภาพรวม skill (entry point)
references/
├── regulatory-framework.md           — กรอบกฎหมาย ระเบียบ คกก. ตัวชี้วัด timeline
├── budget-procurement.md             — แผนจัดซื้อ ประมาณการ PR/PO จัดซื้อร่วม
├── dispensing-substore.md            — คลังย่อย หน่วยเบิก เบิกจ่าย จ่ายยาผู้ป่วย
├── dmsic-5-file.md                   — ส่งข้อมูล 5 แฟ้ม DMSIC (ประกาศ 2568)
├── drug-master-data.md               — ข้อมูลหลักยา TMT unit classification
├── prisma-schema.md                  — data model enums relations
└── warehouse-receiving.md            — คลังใหญ่ GR lot/batch stock
```

## Tech Stack (AegisX)

- **Frontend**: Angular 19 + Angular Material v3 + TailwindCSS
- **Backend**: Fastify + Prisma ORM + PostgreSQL
- **Multi-site**: 20+ hospital sites

## Installation

### Claude Code
```bash
cp -r . /path/to/aegisx-platform/.claude/skills/hospital-drug-inventory/
```

### Claude Desktop (MCP)
```bash
cp -r . /path/to/skills/user/hospital-drug-inventory/
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

## License

Internal use — Khon Kaen Hospital Digital Health Group
