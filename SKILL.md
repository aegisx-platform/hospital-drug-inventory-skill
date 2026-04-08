---
name: hospital-drug-inventory
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
┌─────────────┐    ┌──────────────┐    ┌───────────────┐    ┌──────────────┐    ┌──────────────┐
│ 1.Selection  │───▶│ 2.Estimation │───▶│ 3.Procurement │───▶│  4.Storage   │───▶│5.Distribution│
│  คัดเลือก    │    │  ประมาณการ    │    │   จัดซื้อ      │    │  เก็บสำรอง   │    │   กระจาย     │
│  PTC/บัญชียา │    │  3ปีย้อนหลัง  │    │  แผน→PR→PO→GR │    │  คลัง/FEFO   │    │  คลังย่อย→ผป.│
└─────────────┘    └──────────────┘    └───────────────┘    └──────────────┘    └──────────────┘
```

### Regulatory Foundation (6 ชั้น)
1. **พ.ร.บ.จัดซื้อจัดจ้าง 2560** + กฎกระทรวง 2563
2. **ระเบียบ สธ. 2563** ว่าด้วยการบริหารจัดการด้านยาและเวชภัณฑ์ที่มิใช่ยา
3. **เกณฑ์จริยธรรม 2564** การจัดซื้อจัดหาฯ (ราชกิจจานุเบกษา 15 พ.ค. 2564)
4. **นโยบายพัฒนาประสิทธิภาพบริหารเวชภัณฑ์** (ตั้งแต่ 2542) + หลักเกณฑ์ฯ 2563
5. **ระบบราคาอ้างอิง DMSIC** (อัพเดททุก 3-4 เดือน)
6. **ประกาศ สธ. 2568** มาตรฐานข้อมูลบริหารเวชภัณฑ์ (ยา) 5 แฟ้ม → ส่ง DMSIC ทุกเดือน

### Core Design Principles
1. **Regulation-First**: ทุก workflow สอดคล้องระเบียบ สธ. 2563 + เกณฑ์จริยธรรม 2564
2. **Append-Only Ledger**: stock + budget ใช้ journal pattern
3. **Separation of Duties**: ผู้จัดซื้อ ≠ ผู้ควบคุมคลัง (ข้อ 11)
4. **Net Price Only**: ราคาสุทธิ ห้ามส่วนลด/rebate (เกณฑ์จริยธรรม ข้อ 15(2))
5. **Generic Name Primary**: สั่งยาด้วยชื่อสามัญ (เกณฑ์จริยธรรม ข้อ 13)
6. **FEFO + Real-time Stock**: lot management + real-time deduction
7. **Quarterly Accountability**: รายงาน แผน vs จริง รายไตรมาส
8. **Full Audit Trail**: ทุก transaction traceable

### Tech Stack
- **Frontend**: Angular 19 + Angular Material v3 + TailwindCSS (ax- prefix)
- **Backend**: Fastify + Prisma ORM + PostgreSQL
- **Design**: Clean Clinical SaaS
- **Multi-site**: 20+ hospital sites with `hospital_id`

---

## Domain Reference Files

| Domain | File | เมื่อไหร่ควรอ่าน |
|--------|------|------------------|
| **Regulatory Framework** | `references/regulatory-framework.md` | กรอบกฎหมาย ระเบียบ คกก. ตัวชี้วัด 16 ตัว timeline แบบฟอร์ม |
| Drug Master Data | `references/drug-master-data.md` | drug catalog, TMT, unit conversion, classification |
| Budget & Procurement | `references/budget-procurement.md` | แผนจัดซื้อ ประมาณการ PR/PO สัญญา จัดซื้อร่วม ราคาอ้างอิง |
| Warehouse & Receiving | `references/warehouse-receiving.md` | GR, lot/batch, stock adjustment, separation of duties |
| Dispensing & Sub-Store | `references/dispensing-substore.md` | เบิกจ่าย จ่ายยาคนไข้ real-time utilization evaluation |
| **DMSIC 5-File Standard** | `references/dmsic-5-file.md` | **ส่งข้อมูล 5 แฟ้ม (ประกาศ สธ. 2568)**: DRUGLIST, PURCHASEPLAN, RECEIPT, DISTRIBUTION, INVENTORY |
| Prisma Schema | `references/prisma-schema.md` | data model, relations, enums |

**วิธีใช้**: อ่าน SKILL.md ก่อน → อ่าน reference ที่เกี่ยวข้อง (ไม่ต้องอ่านทั้งหมด)

---

## Common Patterns

### 1. Stock Journal (Append-Only Ledger)
```typescript
interface StockJournal {
  id: string; drugId: string; warehouseId: string; lotId: string;
  movementType: 'RECEIVE' | 'DISPENSE' | 'TRANSFER' | 'ADJUST' | 'RETURN';
  direction: 'IN' | 'OUT';
  quantity: number;        // base unit เสมอ
  baseUnitId: string;
  referenceType: string;   // PO | REQUISITION | PRESCRIPTION | ADJUSTMENT
  referenceId: string;
  hospitalId: string; createdBy: string; createdAt: DateTime;
}
```

### 2. Unit Conversion
```
Package Unit → Trade Unit → Base Unit
1 กล่อง = 10 แผง = 100 เม็ด
```
เก็บใน base unit เสมอ แปลงตอนแสดงผล

### 3. Separation of Duties (RBAC ข้อ 11)
```typescript
// ห้าม user มี role ทั้ง PURCHASER + WAREHOUSE_KEEPER พร้อมกัน
enum DrugRole { PURCHASER, WAREHOUSE_KEEPER, INSPECTOR, APPROVER, PHARMACIST }
```

### 4. Min/Max Stock Calculation
```
Min stock = ปริมาณใช้ต่อปี ÷ 12
Max stock = Min × 1.5
คงคลังไม่เกิน 2 เดือน
```

### 5. FEFO Lot Selection
```typescript
orderBy: { expiryDate: 'asc' } // ใกล้หมดอายุจ่ายก่อน
```

### 6. Multi-Site
```typescript
where: { hospitalId: ctx.hospitalId } // ทุก query
```

---

## Workflow Quick Reference

```
1. คัดเลือก ── PTC → บัญชียาร่วมจังหวัด → ED/NED/VEN → Generic name primary
2. ประมาณการ ── ข้อมูล 3 ปี → Min/Max → ราคาอ้างอิง DMSIC → วงเงิน
3. จัดซื้อ ── แผนจัดซื้อ → คกก. → สสจ. → e-GP → PR → PO (ราคาสุทธิ) → GR
4. เก็บสำรอง ── LOT/FEFO → คงคลัง ≤ 2 เดือน → ตรวจ stock สัปดาห์ → ผู้คลัง ≠ ผู้ซื้อ
5. กระจาย ── คลังใหญ่ → คลังย่อย → ผู้ป่วย → Utilization Evaluation → รายงานไตรมาส
```

---

## Anti-Patterns
1. อย่า UPDATE stock — ใช้ append-only journal
2. อย่าลืม hospital_id
3. อย่าเก็บ stock ใน dispensing unit — ใช้ base unit
4. อย่ารวมผู้จัดซื้อกับผู้คลัง — RBAC แยก (ข้อ 11)
5. อย่ามี discount/rebate — ราคาสุทธิเท่านั้น (เกณฑ์จริยธรรม)
6. อย่าแสดง trade name ก่อน generic — generic primary (ข้อ 13)
7. อย่าลืม DMSIC reference price — alert เมื่อซื้อแพงกว่า
8. อย่าลืมรายงานไตรมาส — แผน vs จริง ตามแบบฟอร์ม สธ.
