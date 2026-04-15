---
name: hospital-drug-inventory
version: 1.0.0
description: >
  Comprehensive skill for building hospital drug inventory management systems covering the full
  pharmaceutical supply chain aligned with Thai MOPH regulations: drug selection (PTC/formulary),
  estimation (3-year historical), procurement (annual plan/PR/PO per พ.ร.บ.จัดซื้อจัดจ้าง 2560),
  storage (warehouse/lot/FEFO), and distribution (sub-store/patient dispensing). Incorporates
  ระเบียบ สธ. 2563, เกณฑ์จริยธรรม 2564, DMSIC reference pricing, and 16 KPIs from
  กองบริหารการสาธารณสุข. Built for AegisX Platform (Angular 19 + Fastify + Prisma + PostgreSQL).

  Use this skill whenever the user asks about: drug inventory, pharmacy systems, คลังยา,
  เบิกจ่ายยา, รับยาเข้าคลัง, จัดซื้อยา, งบประมาณยา, แผนจัดซื้อ, PR/PO ยา, drug master data,
  TMT, GPO codes, unit conversion, FEFO, lot management, requisition dispensing, sub-store stock,
  goods receiving, drug authorization, เกณฑ์จริยธรรม, ราคาอ้างอิง DMSIC, บัญชียาหลักแห่งชาติ,
  จัดซื้อร่วม, utilization evaluation, แผนปฏิบัติการจัดซื้อ, DMSIC 5 แฟ้ม, ส่งข้อมูล DMSIC,
  or anything related to hospital pharmaceutical supply chain management.
---

# Hospital Drug Inventory Management System

ระบบบริหารจัดการคลังเวชภัณฑ์โรงพยาบาล สำหรับ AegisX Platform
ออกแบบตามกรอบระเบียบกระทรวงสาธารณสุข พ.ศ. 2563

## Architecture — 5 กระบวนการตามมาตรฐาน สธ.

```
Selection → Estimation → Procurement → Storage → Distribution
คัดเลือก   ประมาณการ    จัดซื้อ       เก็บสำรอง  กระจาย
PTC/บัญชี  3ปีย้อนหลัง   แผน→PR→PO→GR คลัง/FEFO  คลังย่อย→ผป.
```

### Regulatory Foundation (6 ชั้น)
1. **พ.ร.บ.จัดซื้อจัดจ้าง 2560** + กฎกระทรวง 2563
2. **ระเบียบ สธ. 2563** ว่าด้วยการบริหารจัดการด้านยาและเวชภัณฑ์ที่มิใช่ยา
3. **เกณฑ์จริยธรรม 2564** (ราชกิจจานุเบกษา 15 พ.ค. 2564)
4. **นโยบายพัฒนาประสิทธิภาพบริหารเวชภัณฑ์** (ตั้งแต่ 2542)
5. **ระบบราคาอ้างอิง DMSIC** (อัพเดททุก 3-4 เดือน)
6. **ประกาศ สธ. 2568** มาตรฐานข้อมูลบริหารเวชภัณฑ์ 5 แฟ้ม

### Core Design Principles
1. **Regulation-First** — ทุก workflow สอดคล้องระเบียบ สธ. 2563
2. **Append-Only Ledger** — stock + budget เป็น journal
3. **Separation of Duties** — ผู้จัดซื้อ ≠ ผู้ควบคุมคลัง (ข้อ 11)
4. **Net Price Only** — ห้าม discount/rebate (ข้อ 15(2))
5. **Generic Name Primary** — สั่งยาด้วยชื่อสามัญ (ข้อ 13)
6. **FEFO + Real-time Stock**
7. **Quarterly Accountability** — แผน vs จริง ทุกไตรมาส
8. **Full Audit Trail**

### Tech Stack
Angular 19 + Material v3 + Tailwind (`ax-` prefix) / Fastify + Prisma + PostgreSQL / multi-site `hospitalId`

---

## Domain Reference Router

อ่าน `SKILL.md` ก่อน → อ่านเฉพาะ reference ที่เกี่ยวข้อง (ไม่ต้องอ่านทั้งหมด)

| Domain | File | เมื่อไหร่ควรอ่าน |
|--------|------|------------------|
| Regulatory Framework | `references/regulatory-framework.md` | กรอบกฎหมาย คกก. KPI 16 ตัว timeline แบบฟอร์ม |
| Drug Master Data | `references/drug-master-data.md` | drug catalog, TMT, unit conversion, classification |
| Budget & Procurement | `references/budget-procurement.md` | แผนจัดซื้อ PR/PO สัญญา จัดซื้อร่วม ราคาอ้างอิง |
| Warehouse & Receiving | `references/warehouse-receiving.md` | GR, lot/batch, stock adjustment |
| Dispensing & Sub-Store | `references/dispensing-substore.md` | เบิกจ่าย จ่ายยาผู้ป่วย utilization |
| DMSIC 5-File | `references/dmsic-5-file.md` | ส่ง 5 แฟ้ม (ประกาศ สธ. 2568) |
| Prisma Schema | `references/prisma-schema.md` | data model, relations, enums |
| **Code Patterns** | `references/patterns.md` | **Stock journal, unit conversion, FEFO, RBAC — อ่านก่อนเขียนโค้ด** |

## Workflow Quick Reference

```
1. คัดเลือก   PTC → บัญชียาร่วมจังหวัด → ED/NED/VEN → Generic name primary
2. ประมาณการ  ข้อมูล 3 ปี → Min/Max → ราคาอ้างอิง DMSIC → วงเงิน
3. จัดซื้อ    แผน → คกก. → สสจ. → e-GP → PR → PO (ราคาสุทธิ) → GR
4. เก็บสำรอง  LOT/FEFO → คงคลัง ≤ 2 เดือน → ตรวจ stock สัปดาห์ → ผู้คลัง ≠ ผู้ซื้อ
5. กระจาย    คลังใหญ่ → คลังย่อย → ผู้ป่วย → Utilization → รายงานไตรมาส
```

See `references/patterns.md` for stock-journal, unit-conversion, FEFO, RBAC, and anti-patterns.
