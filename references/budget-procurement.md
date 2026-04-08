# Budget & Procurement Reference

ระบบวางแผนงบประมาณยาประจำปีและจัดซื้อจัดจ้าง
ตามระเบียบ สธ. 2563 + พ.ร.บ.จัดซื้อจัดจ้าง 2560 + เกณฑ์จริยธรรม 2564

---

## 1. Annual Procurement Plan — แผนปฏิบัติการจัดซื้อประจำปี

### ที่มาตามระเบียบ
- **ข้อ 8 ระเบียบ สธ. 2563**: ให้หน่วยงานจัดทำแผนปฏิบัติการจัดซื้อยาและเวชภัณฑ์ที่มิใช่ยาประจำปี
  เสนอ คกก. ข้อ 6 + หัวหน้าหน่วยงาน/สสจ.
- **เอกสารแนบท้าย ลงวันที่ 18 พ.ย. 2563**: ขั้นตอนจัดทำแผน 4 ส่วน

### ขั้นตอนที่ 1 — จัดทำข้อมูลฐาน (ก.ค. - ส.ค.)

ข้อมูลที่ต้องรวบรวม 7 รายการ:

```typescript
interface ProcurementPlanData {
  // (1) โครงสร้างใช้ยา 3 ปีย้อนหลัง
  usageHistory: {
    drugId: string;
    year1Usage: number;  // ปี N-3
    year2Usage: number;  // ปี N-2
    year3Usage: number;  // ปี N-1
  }[];

  // (2) วิเคราะห์แนวโน้มเปลี่ยนแปลง
  trendAnalysis: string; // ยาใหม่เข้า/ยาออก/เปลี่ยนแปลง

  // (3) ประมาณการใช้ในช่วงปีงบประมาณต่อไป
  estimatedUsage: number; // = average(3 years) adjusted by trend

  // (4) ข้อมูลปริมาณยาคงเหลือปัจจุบัน (สำรวจ 1-15 ก.ค.)
  currentStock: number;

  // (5) กำหนดปริมาณขั้นต่ำสำรอง (ตามบัญชีรายการ)
  minStock: number; // = annualUsage / 12

  // (6) ข้อมูลราคา
  pricing: {
    dmiscReferencePrice: number;  // ราคาอ้างอิง DMSIC
    medianPrice: number;          // ราคากลาง
    lastPurchasePrice2Years: number; // ราคาจัดซื้อย้อน 2 ปี
  };

  // (7) กำหนดวงเงินจัดซื้อ
  estimatedBudget: number; // = estimatedPurchaseQty × price
}
```

### สูตรคำนวณหลัก

```typescript
// ประมาณการใช้ในปี (เฉลี่ย 3 ปี ปรับตามแนวโน้ม)
const avgUsage = (year1 + year2 + year3) / 3;
const estimatedUsage = avgUsage * trendFactor;

// ปริมาณที่ต้องจัดซื้อ = ประมาณการใช้ - คงคลัง + safety stock
const purchaseQty = estimatedUsage - currentStock + minStock;

// Min stock = ใช้/ปี ÷ 12 (เท่ากับ avg monthly usage)
const minStock = Math.ceil(annualUsage / 12);

// Max stock = Min × 1.5
const maxStock = Math.ceil(minStock * 1.5);

// คงคลังไม่เกิน 2 เดือน
const stockMonths = currentStock / (annualUsage / 12);
if (stockMonths > 2) alert("คงคลังเกิน 2 เดือน");
```

### ขั้นตอนที่ 2 — จัดทำแผนปฏิบัติการ

แผนประกอบด้วย:
1. **รายการยาและเวชภัณฑ์** ที่มิใช่ยาที่ต้องจัดซื้อ
2. **ประมาณการจัดซื้อประจำปี** (ปริมาณ + วงเงิน)
3. **ประเภทเงิน** ที่จะจัดซื้อ (เงินบำรุง/งบประมาณ)
4. **งวดการจัดซื้อ** แบ่ง 4 ไตรมาส

### Data Model — AnnualProcurementPlan

```typescript
model AnnualProcurementPlan {
  id              String   @id @default(cuid())
  fiscalYear      Int      // ปีงบ เช่น 2569
  hospitalId      String
  planType        PlanType // DRUG | NON_DRUG_MEDICAL

  status          PlanStatus // DRAFT | SUBMITTED | APPROVED | ACTIVE | CLOSED

  // Approval workflow
  submittedBy     String?
  submittedAt     DateTime?
  approvedBy      String?    // คกก.ข้อ 6 / ผอ.
  approvedAt      DateTime?
  ssjApprovedBy   String?    // สสจ. (ส่วนภูมิภาค)
  ssjApprovedAt   DateTime?
  eGPPublishedAt  DateTime?  // วันที่ประกาศใน e-GP

  items           ProcurementPlanItem[]
  revisions       PlanRevision[]
  quarterlyReports QuarterlyReport[]

  hospitalId      String
  hospital        Hospital @relation(fields: [hospitalId], references: [id])

  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  @@unique([fiscalYear, hospitalId, planType])
  @@index([hospitalId, fiscalYear])
}

enum PlanType { DRUG, NON_DRUG_MEDICAL }
enum PlanStatus { DRAFT, SUBMITTED, APPROVED, ACTIVE, CLOSED }
```

### Data Model — ProcurementPlanItem

ตามแบบฟอร์มแผนปฏิบัติการจัดซื้อยา:

```typescript
model ProcurementPlanItem {
  id              String   @id @default(cuid())
  planId          String
  plan            AnnualProcurementPlan @relation(fields: [planId], references: [id])

  drugId          String
  drug            DrugItem @relation(fields: [drugId], references: [id])

  // Classification
  gpuCode         String?   // GPU code
  edNed           EdNedType // ED | NED
  venClass        VenClass? // VITAL | ESSENTIAL | NON_ESSENTIAL

  // Package info
  packageSize     String    // ขนาดบรรจุ
  unitName        String    // หน่วยนับ

  // Historical usage (3 years)
  usageYear1      Decimal   // ปริมาณใช้ปีที่ 1
  usageYear2      Decimal   // ปริมาณใช้ปีที่ 2
  usageYear3      Decimal   // ปริมาณใช้ปีที่ 3
  usageYear1Label String    // "2566" etc.
  usageYear2Label String
  usageYear3Label String

  // Current stock
  currentStock    Decimal   // ปริมาณคงคลังยกมา

  // Estimation
  estimatedUsage  Decimal   // ประมาณการใช้ในปี
  estimatedPurchase Decimal // ประมาณการจัดซื้อ
  unitPrice       Decimal   // ราคาต่อหน่วยนับ
  totalBudget     Decimal   // มูลค่าจัดซื้อปี = estimatedPurchase × unitPrice

  // Quarterly breakdown (4 ไตรมาส ตามปีงบ)
  q1Budget        Decimal   // ต.ค. - ธ.ค.
  q2Budget        Decimal   // ม.ค. - มี.ค.
  q3Budget        Decimal   // เม.ย. - มิ.ย.
  q4Budget        Decimal   // ก.ค. - ก.ย.

  // Reference pricing
  dmiscRefPrice   Decimal?  // ราคาอ้างอิง DMSIC
  medianPrice     Decimal?  // ราคากลาง
  lastPurchasePrice Decimal? // ราคาจัดซื้อล่าสุด

  // Actual (filled during execution)
  actualPurchaseQty Decimal? @default(0)
  actualSpent     Decimal?  @default(0)

  @@index([planId])
  @@index([drugId])
}

enum EdNedType { ED, NED }
enum VenClass { VITAL, ESSENTIAL, NON_ESSENTIAL }
```

---

## 2. Approval Workflow — ขั้นตอนเสนอและพิจารณา

ตามข้อ 8 ระเบียบ 2563 + เอกสารแนบท้าย:

```
จัดทำแผน (กลุ่มงานเภสัชกรรม)
  │
  ▼
คกก.บริหารเวชภัณฑ์ (ข้อ 6) — พิจารณา/ปรับแก้
  │
  ▼
หัวหน้าหน่วยงาน / ผอ. — เห็นชอบ
  │
  ▼
สสจ. (ส่วนภูมิภาค) — รับแผน/อนุมัติ
  │
  ▼
ประกาศแผนใน e-GP — เผยแพร่สาธารณะ
  │
  ▼
ดำเนินการจัดซื้อ (เริ่ม ต.ค.)
```

---

## 3. Plan Revision — ปรับแผนระหว่างปี

### เหตุที่ต้องขออนุมัติปรับแผน (ข้อ 3 เอกสารแนบท้าย)

1. **รายการยาใหม่ที่ไม่ได้กำหนดอยู่ในแผน** — ต้องเพิ่มรายการ + วงเงิน
2. **อัตราใช้เพิ่มสูงกว่าที่ว่าไว้** หรือเงินรวมไม่เพียงพอ — ต้องขออนุมัติเพิ่มเงิน

### Data Model

```typescript
model PlanRevision {
  id              String   @id @default(cuid())
  planId          String
  plan            AnnualProcurementPlan @relation(fields: [planId], references: [id])

  revisionNumber  Int      // ครั้งที่ 1, 2, 3...
  revisionType    RevisionType

  // What changed
  description     String   // เหตุผลที่ต้องปรับ
  itemChanges     Json     // รายการที่เปลี่ยน + ก่อน/หลัง

  // Budget impact
  previousTotal   Decimal  // วงเงินก่อนปรับ
  newTotal        Decimal  // วงเงินหลังปรับ
  difference      Decimal  // ส่วนต่าง

  // Approval
  requestedBy     String
  requestedAt     DateTime
  approvedBy      String?  // สสจ./หัวหน้าส่วนราชการ
  approvedAt      DateTime?
  status          ApprovalStatus // PENDING | APPROVED | REJECTED

  @@index([planId])
}

enum RevisionType {
  ADD_ITEM          // เพิ่มรายการยาใหม่
  INCREASE_BUDGET   // เพิ่มวงเงิน
  CHANGE_ITEM       // เปลี่ยนรายการ (เช่น ยาขาดตลาด)
  PRICE_CHANGE      // ราคาเปลี่ยนแปลง
  EMERGENCY         // กรณีฉุกเฉิน (โรคระบาด)
}
```

### ขั้นตอนปรับแผน

```
หน่วยงานเสนอขอปรับ
  │ (ระบุเหตุผล + ผลกระทบวงเงิน)
  ▼
สสจ./หัวหน้าส่วนราชการ กำหนดช่วงระยะเวลา
  │
  ▼
หน่วยงานพิจารณาอนุมัติปรับแผนได้
  │
  ▼
แจ้ง สสจ. เมื่อปรับแผนเรียบร้อย
```

---

## 4. Quarterly Reporting — รายงานรายไตรมาส

### ตามแบบฟอร์ม สรุปแผนปฏิบัติการจัดซื้อยา

```typescript
model QuarterlyReport {
  id              String   @id @default(cuid())
  planId          String
  plan            AnnualProcurementPlan @relation(fields: [planId], references: [id])

  quarter         Int      // 1-4
  // Q1: ต.ค.-ธ.ค. | Q2: ม.ค.-มี.ค. | Q3: เม.ย.-มิ.ย. | Q4: ก.ค.-ก.ย.

  // Plan vs Actual (total)
  plannedAmount   Decimal  // แผน (บาท)
  actualAmount    Decimal  // จัดซื้อจริง (บาท)

  // แยกตามบัญชียาหลัก
  edPlannedItems  Int      // จำนวนรายการ ED แผน
  edPlannedAmount Decimal  // มูลค่า ED แผน
  edActualItems   Int
  edActualAmount  Decimal

  // ยานอกบัญชียาหลัก
  nedPlannedItems Int
  nedPlannedAmount Decimal
  nedActualItems  Int
  nedActualAmount Decimal

  reportedBy      String
  reportedAt      DateTime

  @@unique([planId, quarter])
}
```

### KPI ที่เกี่ยวข้องกับ Quarterly Report

```typescript
function calculateQuarterlyKPIs(planId: string, quarter: number) {
  return {
    // ร้อยละการจัดซื้อตามแผน
    planComplianceRate: (actualAmount / plannedAmount) * 100,

    // ร้อยละรายการยาในบัญชียาหลัก (ED ratio)
    edRatio: (edActualItems / totalActualItems) * 100,

    // ร้อยละมูลค่ายาในบัญชียาหลัก
    edValueRatio: (edActualAmount / totalActualAmount) * 100,

    // ราคาจัดซื้อเทียบ DMSIC
    priceComplianceRate: calculatePriceVsDMSIC(planId, quarter),
  };
}
```

---

## 5. Procurement Execution — PR/PO/GR

### Purchase Requisition (PR)

```typescript
model PurchaseRequisition {
  id              String   @id @default(cuid())
  prNumber        String   @unique  // เลขที่ใบขอซื้อ
  fiscalYear      Int
  planId          String?  // อ้างอิงแผนจัดซื้อ
  hospitalId      String

  requestedBy     String   // ผู้ขอซื้อ (role: PURCHASER)
  requestedAt     DateTime
  approvedBy      String?  // ผู้อนุมัติ (role: APPROVER)
  approvedAt      DateTime?
  status          PRStatus // DRAFT | PENDING | APPROVED | REJECTED | PO_CREATED

  items           PRItem[]
  totalAmount     Decimal

  @@index([hospitalId, fiscalYear])
}

model PRItem {
  id              String   @id @default(cuid())
  prId            String
  pr              PurchaseRequisition @relation(fields: [prId], references: [id])

  drugId          String
  quantity        Decimal  // จำนวน (ในหน่วยจัดซื้อ)
  unitId          String   // หน่วยจัดซื้อ (package unit)
  unitPrice       Decimal  // ราคาสุทธิต่อหน่วย (NET PRICE ONLY)
  totalPrice      Decimal

  // Reference pricing
  dmiscRefPrice   Decimal? // ราคาอ้างอิง DMSIC
  // Alert flag if unitPrice > dmiscRefPrice
  priceAboveRef   Boolean  @default(false)

  @@index([prId])
}
```

### Purchase Order (PO)

```typescript
model PurchaseOrder {
  id              String   @id @default(cuid())
  poNumber        String   @unique
  fiscalYear      Int
  prId            String?  // อ้างอิง PR
  contractId      String?  // อ้างอิงสัญญา
  vendorId        String
  hospitalId      String

  // Method — ตาม พ.ร.บ.จัดซื้อจัดจ้าง 2560
  procurementMethod ProcurementMethod
  // SPECIFIC (เฉพาะเจาะจง ≤500k)
  // E_BIDDING (ประกาศเชิญชวน)
  // SELECTION (คัดเลือก)
  // JOINT_PURCHASE (จัดซื้อร่วม)

  // Pricing — ราคาสุทธิเท่านั้น (เกณฑ์จริยธรรม ข้อ 15(2))
  totalNetAmount  Decimal  // NET PRICE — ไม่มี discount/rebate
  // *** ห้ามมี discountAmount, rebateAmount ***

  // Budget source
  fundSource      FundSource // HOSPITAL_REVENUE | BUDGET | OTHER

  status          POStatus // DRAFT | SENT | PARTIAL_RECEIVED | COMPLETED | CANCELLED
  deliveryDate    DateTime?
  sentAt          DateTime?

  items           POItem[]
  goodsReceivings GoodsReceiving[]

  createdBy       String   // role: PURCHASER
  createdAt       DateTime @default(now())

  @@index([hospitalId, fiscalYear])
  @@index([vendorId])
}

enum ProcurementMethod { SPECIFIC, E_BIDDING, SELECTION, JOINT_PURCHASE }
enum FundSource { HOSPITAL_REVENUE, BUDGET, OTHER }
```

### Contract / Agreement

```typescript
model ProcurementContract {
  id              String   @id @default(cuid())
  contractNumber  String
  fiscalYear      Int
  hospitalId      String
  vendorId        String

  // สัญญาราคาคงที่ (ข้อ 10 ระเบียบ 2563)
  contractType    ContractType // FIXED_PRICE_ANNUAL | FIXED_PRICE_PERIOD | BLANKET
  // *** ราคาคงที่เท่านั้น ***

  startDate       DateTime
  endDate         DateTime
  totalAmount     Decimal

  items           ContractItem[]
  purchaseOrders  PurchaseOrder[]

  status          ContractStatus // ACTIVE | COMPLETED | TERMINATED

  @@index([hospitalId, fiscalYear])
}
```

---

## 6. Pooled Procurement — จัดซื้อร่วม

ตามข้อ 9 ระเบียบ 2563:
- จัดซื้อร่วมระดับจังหวัด/เขต ได้
- ดำเนินการโดยอำนาจหัวหน้าส่วนราชการ ตาม พ.ร.บ.จัดซื้อจัดจ้าง 2560
- จัดซื้อร่วมระดับเขต ดำเนินการโดยเป็นอำนาจของ ปลัด สธ.

```typescript
model JointPurchaseGroup {
  id              String   @id @default(cuid())
  name            String   // เช่น "จัดซื้อร่วมจังหวัดขอนแก่น ปี 2569"
  fiscalYear      Int
  level           JointLevel // DISTRICT | PROVINCE | REGION
  provinceCode    String?
  regionCode      String?

  leadHospitalId  String   // รพ.แม่ข่าย
  memberHospitals String[] // รพ.สมาชิก

  items           JointPurchaseItem[]
  status          JointStatus // PLANNING | BIDDING | CONTRACTED | COMPLETED
}
```

---

## 7. DMSIC Reference Price Integration

```typescript
model DMSICReferencePrice {
  id              String   @id @default(cuid())
  drugId          String
  tmtCode         String?  // TMT 24-digit
  genericName     String
  tradeName       String?

  referencePrice  Decimal  // ราคาอ้างอิง
  medianPrice     Decimal? // ราคากลาง
  effectiveDate   DateTime // วันที่มีผล
  batchDate       DateTime // ชุดข้อมูล (อัพเดททุก 3-4 เดือน)

  source          String   @default("DMSIC")

  @@index([drugId])
  @@index([tmtCode])
  @@index([effectiveDate])
}

// Alert: ซื้อแพงกว่าราคาอ้างอิง
function checkPriceVsReference(drugId: string, purchasePrice: Decimal): PriceAlert | null {
  const ref = getLatestDMSICPrice(drugId);
  if (!ref) return null;
  if (purchasePrice > ref.referencePrice) {
    return {
      drugId,
      purchasePrice,
      referencePrice: ref.referencePrice,
      percentAbove: ((purchasePrice - ref.referencePrice) / ref.referencePrice * 100),
      requiresJustification: true,
    };
  }
  return null;
}
```

---

## 8. Thai Fiscal Year Utilities

```typescript
// ปีงบประมาณไทย: 1 ต.ค. — 30 ก.ย.
function getThaiFiscalYear(date: Date = new Date()): {
  start: Date; end: Date; year: number;
  quarters: { q: number; start: Date; end: Date }[];
} {
  const month = date.getMonth(); // 0-based
  const year = date.getFullYear();
  const fiscalYear = month >= 9 ? year + 1 : year; // ต.ค.+ = ปีงบถัดไป
  return {
    start: new Date(fiscalYear - 1, 9, 1),   // 1 ต.ค.
    end: new Date(fiscalYear, 8, 30),          // 30 ก.ย.
    year: fiscalYear,
    quarters: [
      { q: 1, start: new Date(fiscalYear - 1, 9, 1), end: new Date(fiscalYear - 1, 11, 31) },  // ต.ค.-ธ.ค.
      { q: 2, start: new Date(fiscalYear, 0, 1), end: new Date(fiscalYear, 2, 31) },            // ม.ค.-มี.ค.
      { q: 3, start: new Date(fiscalYear, 3, 1), end: new Date(fiscalYear, 5, 30) },            // เม.ย.-มิ.ย.
      { q: 4, start: new Date(fiscalYear, 6, 1), end: new Date(fiscalYear, 8, 30) },            // ก.ค.-ก.ย.
    ],
  };
}

// ปฏิทินจัดทำแผน
// ก.ค.-ส.ค.: จัดทำข้อมูลฐาน + ประมาณการ
// ส.ค.-ก.ย.: เสนอแผน → คกก. → สสจ. → e-GP
// ต.ค.: เริ่มปีงบใหม่ → ดำเนินการจัดซื้อ
// ทุกไตรมาส: รายงาน แผน vs จริง
// ต.ค. ปีถัดไป: ประเมินผลการดำเนินการ
```

---

## 9. Budget Journal (Ledger Pattern)

งบประมาณใช้ append-only journal เช่นเดียวกับ stock:

```typescript
model BudgetJournal {
  id              String   @id @default(cuid())
  planId          String
  plan            AnnualProcurementPlan @relation(fields: [planId], references: [id])

  entryType       BudgetEntryType
  amount          Decimal  // จำนวนเงิน (บวก = เพิ่มงบ, ลบ = ใช้งบ)
  description     String

  // Reference
  referenceType   String?  // PO | REVISION | GR
  referenceId     String?

  // ยอดงบ = SUM(amount) ของ journal ทั้งหมด
  // committed = SUM where entryType = COMMITTED
  // spent = SUM where entryType = SPENT
  // available = total - committed - spent

  createdBy       String
  createdAt       DateTime @default(now())

  @@index([planId])
}

enum BudgetEntryType {
  ALLOCATE      // จัดสรรงบต้นปี
  SUPPLEMENT    // งบเพิ่มเติม (revision)
  COMMITTED     // ผูกพันงบ (PO created)
  SPENT         // ใช้จริง (GR received)
  RELEASED      // ปลดผูกพัน (PO cancelled)
  ADJUSTMENT    // ปรับปรุงอื่นๆ
}

// Budget calculation
function getBudgetSummary(planId: string) {
  const journals = getAllJournals(planId);
  return {
    totalBudget: sum(journals, ['ALLOCATE', 'SUPPLEMENT', 'ADJUSTMENT']),
    committed: sum(journals, ['COMMITTED']),
    spent: sum(journals, ['SPENT']),
    released: sum(journals, ['RELEASED']),
    available: totalBudget - committed - spent + released,
  };
}
```

---

## 10. Key Business Rules Summary

| Rule | Source | Description |
|------|--------|-------------|
| ราคาสุทธิเท่านั้น | เกณฑ์จริยธรรม ข้อ 15(2) | ห้ามส่วนลด/rebate/ผลประโยชน์ต่างตอบแทน |
| ผู้ซื้อ ≠ ผู้คลัง | ระเบียบ ข้อ 11 | Separation of duties (RBAC) |
| สั่งยาชื่อสามัญ | เกณฑ์จริยธรรม ข้อ 13 | Generic name primary |
| คงคลัง ≤ 2 เดือน | มาตรฐาน สธ. | Stock months check |
| ข้อมูล 3 ปี | เอกสารแนบท้าย ข้อ 1.1 | ใช้ย้อนหลัง 3 ปีสำหรับประมาณการ |
| รายงานไตรมาส | เอกสารแนบท้าย ข้อ 1.4 | แผน vs จริง ทุก 3 เดือน |
| ราคาอ้างอิง DMSIC | นโยบาย ข้อ 3.4 / 5.2.1 | ตรวจสอบราคาจัดซื้อเทียบราคากลาง |
| สัญญาราคาคงที่ | ระเบียบ ข้อ 10 | Fixed price contract only |
| ปรับแผนต้องขออนุมัติ | เอกสารแนบท้าย ข้อ 3 | เพิ่มรายการ/เงิน ต้องผ่าน สสจ. |
| e-GP ประกาศแผน | พ.ร.บ.จัดซื้อฯ | ประกาศแผนจัดซื้อต่อสาธารณะ |
| บัญชียาร่วมจังหวัด | ระเบียบ ข้อ 7 | กรอบบัญชีร่วมโดย สสจ. |
| audit trail | เกณฑ์จริยธรรม ข้อ 15(5.4) | ระบบตรวจสอบภายใน |
