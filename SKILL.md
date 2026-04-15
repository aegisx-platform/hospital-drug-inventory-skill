---
name: hospital-drug-inventory
version: 1.0.1
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

ระบบบริหารจัดการคลังเวชภัณฑ์โรงพยาบาล — AegisX Platform
ตามระเบียบ สธ. 2563 + เกณฑ์จริยธรรม 2564 + DMSIC + ประกาศ สธ. 2568

## 5-Stage Supply Chain

```
Selection → Estimation → Procurement → Storage → Distribution
คัดเลือก   ประมาณการ    จัดซื้อ        เก็บสำรอง  กระจาย
PTC/บัญชี  3ปีย้อนหลัง   แผน→PR→PO→GR  LOT/FEFO  คลังย่อย→ผป.
```

## Non-Negotiable Rules (โหลดทุก task)

1. **Append-Only Ledger** — ไม่ UPDATE stock; insert journal + direction IN/OUT ใน base unit
2. **Separation of Duties** — user เดียวกันมี PURCHASER + WAREHOUSE_KEEPER ไม่ได้ (ระเบียบ สธ. 2563 ข้อ 11)
3. **Net Price Only** — ห้าม discount/rebate (เกณฑ์จริยธรรม 2564 ข้อ 15(2))
4. **Generic Primary** — generic name แสดงก่อน trade name (ข้อ 13)
5. **Multi-site Isolation** — ทุก query ต้องมี `hospitalId`
6. **FEFO** — lot เลือกจาก `orderBy expiryDate asc`
7. **DMSIC Reference Price** — alert เมื่อซื้อแพงกว่า

## Tech Stack

Angular 19 + Material v3 + Tailwind (`ax-` prefix) / Fastify + Prisma + PostgreSQL / multi-tenant via `hospitalId`

## Reference Router

อ่านเฉพาะที่เกี่ยวข้อง ไม่ต้องอ่านทั้งหมด

| Domain | File | อ่านเมื่อ |
|--------|------|-----------|
| Regulatory & Timeline | `references/regulatory-framework.md` | กฎหมาย 6 ชั้น, KPI 16 ตัว, ปฏิทินงบประมาณ, แบบฟอร์ม |
| Drug Master | `references/drug-master-data.md` | TMT, GPU, unit conversion, ED/NED/VEN |
| Budget & Procurement | `references/budget-procurement.md` | แผนจัดซื้อ, PR/PO, จัดซื้อร่วม, DMSIC reference price |
| Warehouse & Receiving | `references/warehouse-receiving.md` | GR, lot/batch, stock adjustment |
| Dispensing & Sub-Store | `references/dispensing-substore.md` | เบิกจ่าย, จ่ายยาผู้ป่วย, utilization |
| DMSIC 5-File | `references/dmsic-5-file.md` | ส่ง 5 แฟ้มรายเดือน (ประกาศ สธ. 2568) |
| Prisma Schema | `references/prisma-schema.md` | data model, enums, relations |
| **Code Patterns** | `references/patterns.md` | **stock journal, FEFO, RBAC code — อ่านก่อนเขียนโค้ด** |

See `examples/` for ready-to-adapt Prisma/Fastify/Angular snippets.
