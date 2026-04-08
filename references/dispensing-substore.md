# Dispensing & Sub-Store Reference

ระบบเบิกจ่ายยา: คลังใหญ่ → คลังย่อย (หน่วยเบิก) → จ่ายยาผู้ป่วย
ครอบคลุม OPD/IPD workflows, ยาสำรองหอผู้ป่วย (Floor Stock), real-time stock deduction

## Regulatory Compliance

- **ระเบียบ สธ. 2563 ข้อ 13**: คกก.ข้อ 6 ต้องจัดให้มี **Utilization Evaluation**
  ทั้งด้านประสิทธิผล คุณค่า ความปลอดภัย
- **เกณฑ์จริยธรรม 2564 ข้อ 13**: สั่งยาด้วย **ชื่อสามัญทางยา**
- **KPI กระจาย**: ร้อยละรายการยาที่ขาดขณะให้บริการผู้ป่วย (stockout at point of care)

---

## 1. โครงสร้างคลังใน รพ.ศูนย์/รพ.ทั่วไป

### ภาพรวมโครงสร้าง 2 ชั้น

```
คลังใหญ่ (Central Pharmacy / Medicine Main Store) ── 1 แห่ง
│
│   จัดเก็บยาตาม Category: ยาเม็ด, ยาน้ำ, ยาฉีด, ยาเคมีบำบัด,
│   ยาเย็น, วัตถุออกฤทธิ์ฯ, ยาเสพติดให้โทษ
│   เรียกยาด้วย Trade Name (ชื่อการค้า)
│
├── คลังย่อย: ห้องจ่ายยา (Dispensing Pharmacy) ────────────
│   ├── ห้องจ่ายยา OPD (ผู้ป่วยนอก) ← volume สูงสุด
│   ├── ห้องจ่ายยา IPD (ผู้ป่วยใน)
│   └── ห้องจ่ายยานอกเวลา / ER
│
├── คลังย่อย: หอผู้ป่วย (Ward Stock / Floor Stock) ──────
│   ├── อายุรกรรมชาย, อายุรกรรมหญิง
│   ├── ศัลยกรรมชาย, ศัลยกรรมหญิง
│   ├── สูตินรีเวช, กุมารเวชกรรม
│   ├── ออร์โธปิดิกส์, จักษุ, โสต-ศอ-นาสิก
│   ├── ICU (Medical/Surgical/Neuro/Cardiac)
│   ├── NICU, Nursery
│   ├── หอผู้ป่วยพิเศษ (ห้องพิเศษ)
│   └── ... (รวม 20-40 ward)
│
├── คลังย่อย: หน่วยบริการเฉพาะ ──────────────────────
│   ├── OR (ห้องผ่าตัด)
│   ├── ER (ห้องฉุกเฉิน)
│   ├── หน่วยเคมีบำบัด (Chemo)
│   ├── ไตเทียม (Hemodialysis)
│   ├── ทันตกรรม
│   ├── จิตเวช
│   └── คลินิกพิเศษ / หน่วยอื่นๆ
│
└── คลังย่อย: เครือข่าย ──────────────────────────────
    ├── รพ.สต. ในเครือข่าย (ตามระเบียบ สธ. 2563 ข้อ 7)
    └── PCU (Primary Care Unit)
```

### ความแตกต่างหลัก: คลังใหญ่ vs คลังย่อย

| | คลังใหญ่ (Main Store) | คลังย่อย (Sub-Store / หน่วยเบิก) |
|---|---|---|
| **จำนวน** | 1 แห่ง | 20-40 แห่ง (รพ.ศูนย์) |
| **จัดเก็บ** | ตาม Category (รูปแบบยา) | ตาม Pharmacology (กลุ่มอาการ) |
| **เรียกยา** | Trade Name (ชื่อการค้า) | **Generic Name (ชื่อสามัญ)** ← เกณฑ์จริยธรรม |
| **ที่มาของยา** | จัดซื้อจาก vendor (GR) | **เบิกจากคลังใหญ่** (Requisition) |
| **Min/Max** | ระดับ รพ. (stock months ≤ 2) | ระดับ ward (par level) |
| **ตรวจสอบ** | เภสัชกร/จพง.เภสัชกรรม | พยาบาล + เภสัชกรสุ่มตรวจ |
| **ผู้รับผิดชอบ** | หัวหน้ากลุ่มงานเภสัชกรรม | หัวหน้าหอ/หัวหน้าหน่วย |

### Data Model

```typescript
model Warehouse {
  id              String   @id @default(cuid())
  hospitalId      String
  code            String            // รหัสคลัง เช่น "CENTRAL", "OPD1", "WARD-MED-M"
  name            String            // เช่น "คลังยาใหญ่", "ห้องจ่ายยา OPD", "หอผู้ป่วยอายุรกรรมชาย"
  warehouseType   WarehouseType
  subStoreType    SubStoreType?     // ประเภทคลังย่อย (ถ้าเป็น SUB_STORE)

  parentId        String?           // → คลังใหญ่ (CENTRAL)
  parent          Warehouse? @relation("WarehouseHierarchy", fields: [parentId], references: [id])
  children        Warehouse[] @relation("WarehouseHierarchy")

  departmentId    String?           // แผนกที่ดูแล
  locationDesc    String?           // ที่ตั้ง เช่น "อาคาร 2 ชั้น 3"
  responsibleBy   String?           // หัวหน้าหอ/หน่วย

  isActive        Boolean @default(true)

  // Stock management
  stockJournals   StockJournal[]
  drugLots        DrugLot[]
  floorStockItems FloorStockItem[]  // บัญชียาสำรอง (ถ้าเป็น ward)

  @@unique([hospitalId, code])
}

enum WarehouseType {
  CENTRAL     // คลังใหญ่/คลังกลาง
  SUB_STORE   // คลังย่อย/หน่วยเบิก
}

enum SubStoreType {
  OPD_DISPENSING    // ห้องจ่ายยา OPD
  IPD_DISPENSING    // ห้องจ่ายยา IPD
  WARD              // หอผู้ป่วยใน (floor stock)
  ER                // ห้องฉุกเฉิน
  ICU               // หอผู้ป่วยวิกฤต
  OR                // ห้องผ่าตัด
  SPECIALTY         // หน่วยเฉพาะทาง (เคมีบำบัด, ไตเทียม, ทันตกรรม)
  NETWORK           // เครือข่าย (รพ.สต., PCU)
}
```

---

## 2. ยาสำรองหอผู้ป่วย (Floor Stock / Ward Stock)

### แนวคิด

หอผู้ป่วยแต่ละ ward มี **บัญชียาสำรอง** (Floor Stock List) ที่ PTC/คกก.บริหารเวชภัณฑ์ อนุมัติ:
- แต่ละ ward มีรายการยาที่อนุญาตให้สำรอง + จำนวน Min/Max (par level) ของแต่ละรายการ
- ทบทวนบัญชีทุก 1 ปี
- ขอเพิ่ม/ลดรายการต้องผ่าน คกก.
- ยาฉุกเฉินในรถ Emergency (Emergency Cart) มีรายการเฉพาะที่แยกต่างหาก

### Data Model

```typescript
model FloorStockItem {
  id              String   @id @default(cuid())
  warehouseId     String            // ward ไหน
  warehouse       Warehouse @relation(fields: [warehouseId], references: [id])
  drugId          String
  drug            DrugItem @relation(fields: [drugId], references: [id])

  // Par level — Min/Max สำหรับ ward นี้
  parMin          Decimal           // จำนวนขั้นต่ำที่ต้องมี
  parMax          Decimal           // จำนวนสูงสุดที่สำรองได้
  unitId          String            // หน่วยนับ (ปกติ = base unit)

  // Approval
  approvedBy      String?           // คกก. อนุมัติ
  approvedAt      DateTime?
  reviewDueDate   DateTime?         // วันที่ต้องทบทวนใหม่ (ทุก 1 ปี)

  isEmergencyCart Boolean @default(false) // ยาในรถ Emergency หรือไม่
  isActive        Boolean @default(true)

  @@unique([warehouseId, drugId])
  @@index([warehouseId])
}
```

### ปัญหาที่พบบ่อยในคลังย่อย (ระบบต้องแก้)

1. **ยอดคงเหลือไม่เป็นปัจจุบัน** — ต้องตัดยอดแบบ real-time เชื่อมกับ HIS
2. **ยาหมดอายุบน ward** — ต้อง alert ยาใกล้หมดอายุ < 6 เดือน + FEFO
3. **ยาไม่ครบ/จำนวนไม่ตรง** — ต้อง periodic stock check + reconciliation
4. **เบิกนอกวงรอบบ่อย** — ต้องปรับ par level ให้เหมาะสมตามการใช้จริง
5. **ยาที่ไม่ได้อยู่ในบัญชีสำรองปรากฏบน ward** — ต้อง enforce floor stock list

---

## 3. วงรอบการเบิก (Requisition Cycle)

### 3 แบบหลัก

```
แบบ 1: Schedule-based (เบิกตามวงรอบ) ── ส่วนใหญ่ ward ใช้แบบนี้
├── กำหนดวันเบิกประจำ (เช่น ทุกวันจันทร์-พุธ-ศุกร์)
├── ตรวจนับยาคงเหลือ → เทียบกับ par level
├── เบิกจำนวน = parMax - currentStock (top-up to max)
└── คลังใหญ่จัดยา → ส่ง ward → ward รับเข้า

แบบ 2: On-demand (เบิกเมื่อต้องการ) ── กรณีพิเศษ/ด่วน
├── ยาที่ไม่อยู่ในบัญชีสำรอง (non-floor-stock)
├── ยาที่ใช้หมดก่อนวงรอบ (ใช้มากกว่าปกติ)
├── ยาสำหรับผู้ป่วยเฉพาะราย (patient-specific)
└── ต้องมีใบเบิกพิเศษ + เหตุผล

แบบ 3: Per-prescription (จ่ายตามใบสั่ง) ── OPD ใช้แบบนี้
├── แพทย์สั่งยา → ส่งไปห้องจ่ายยา OPD
├── เภสัชกร screen → จัดยา → ตรวจสอบ → ส่งมอบ
├── ตัด stock จากคลังย่อย OPD ทันที (real-time)
└── คลังย่อย OPD เบิกเติม stock จากคลังใหญ่ตามวงรอบ
```

### Data Model — Requisition

```typescript
model Requisition {
  id              String   @id @default(cuid())
  reqNumber       String   @unique
  hospitalId      String

  fromWarehouseId String               // คลังที่จ่าย (CENTRAL)
  fromWarehouse   Warehouse @relation("ReqFrom", fields: [fromWarehouseId], references: [id])
  toWarehouseId   String               // คลังที่เบิก (SUB_STORE)
  toWarehouse     Warehouse @relation("ReqTo", fields: [toWarehouseId], references: [id])

  requisitionType RequisitionType      // SCHEDULED | ON_DEMAND | EMERGENCY
  status          ReqStatus            // DRAFT | SUBMITTED | PROCESSING | DISPENSED | RECEIVED | CANCELLED

  requestedBy     String               // ผู้เบิก (หัวหน้าหอ/เภสัชกร ward)
  requestedDate   DateTime
  processedBy     String?              // ผู้จัด (เจ้าหน้าที่คลังใหญ่)
  processedDate   DateTime?
  receivedBy      String?              // ผู้รับ (เจ้าหน้าที่ ward)
  receivedDate    DateTime?

  items           RequisitionItem[]
  note            String?

  @@index([hospitalId, toWarehouseId])
  @@index([status])
}

enum RequisitionType {
  SCHEDULED       // เบิกตามวงรอบ
  ON_DEMAND       // เบิกเมื่อต้องการ
  EMERGENCY       // เบิกฉุกเฉิน
}

model RequisitionItem {
  id              String   @id @default(cuid())
  requisitionId   String
  requisition     Requisition @relation(fields: [requisitionId], references: [id])

  drugId          String
  drug            DrugItem @relation(fields: [drugId], references: [id])

  // Request
  requestedQty    Decimal              // จำนวนที่ขอเบิก (base unit)
  parMax          Decimal?             // par max ของ ward (สำหรับ SCHEDULED)
  currentStock    Decimal?             // stock ปัจจุบัน (สำหรับ SCHEDULED)

  // Dispense (คลังใหญ่จัด)
  dispensedQty    Decimal?              // จำนวนที่จัดจริง (อาจน้อยกว่าที่ขอ)
  lotId           String?              // LOT ที่จ่าย (FEFO)
  expiryDate      DateTime?

  // Receive (ward รับ)
  receivedQty     Decimal?             // จำนวนที่รับจริง
  note            String?              // หมายเหตุ (เช่น "จัดน้อยกว่า เพราะ stock คลังใหญ่ไม่พอ")

  @@index([requisitionId])
}
```

---

## 4. OPD Dispensing Workflow

ห้องจ่ายยา OPD เป็นคลังย่อยที่มี volume สูงสุด (รพ.ขอนแก่น: 4,000+ คน/วัน)

### Workflow

```
แพทย์สั่งยา (Prescription)
  │  ชื่อสามัญทางยา (เกณฑ์จริยธรรม ข้อ 13)
  ▼
ส่งใบยาไปห้องจ่ายยา OPD
  │  ผ่านระบบ HIS (electronic)
  ▼
เภสัชกร Screen (Prescription Screening)
  │  ├── ตรวจ DI (Drug Interaction)
  │  ├── ตรวจ allergy
  │  ├── ตรวจ dose / frequency
  │  ├── ตรวจ LASA (Look-Alike Sound-Alike)
  │  └── ตรวจ High Alert Drug
  ▼
จัดยา (Drug Preparation)
  │  ├── จัดตาม FEFO
  │  ├── Barcode scan ยืนยันรายการ
  │  └── พิมพ์ฉลากยา (Sticker)
  ▼
ตรวจสอบยา (Verification)
  │  เภสัชกรคนที่ 2 ตรวจซ้ำ (double check)
  ▼
ส่งมอบยา (Dispensing)
  │  ├── เภสัชกร/จพง.ส่งมอบ + แนะนำการใช้ยา
  │  └── **ตัด stock จากคลังย่อย OPD ทันที (real-time)**
  ▼
Stock Journal Entry
  │  direction: OUT, referenceType: PRESCRIPTION
  └── คลังย่อย OPD เบิกเติม stock จากคลังใหญ่ตามวงรอบ
```

### Data Model — PatientDispensing (OPD)

```typescript
model PatientDispensing {
  id              String   @id @default(cuid())
  hospitalId      String
  prescriptionId  String   // อ้างอิง prescription/order
  patientId       String   // HN
  visitId         String   // VN (encounter)

  warehouseId     String   // คลังย่อย OPD ที่จ่าย
  warehouse       Warehouse @relation(fields: [warehouseId], references: [id])

  dispensedBy     String   // เภสัชกร/จพง.ที่จ่าย
  dispensedAt     DateTime
  screenedBy      String?  // เภสัชกร screen
  verifiedBy      String?  // เภสัชกร double check

  items           DispensingItem[]
  status          DispensingStatus // PENDING | DISPENSED | RETURNED | CANCELLED

  @@index([hospitalId, patientId])
  @@index([prescriptionId])
  @@index([warehouseId, dispensedAt])
}

model DispensingItem {
  id              String   @id @default(cuid())
  dispensingId    String
  dispensing      PatientDispensing @relation(fields: [dispensingId], references: [id])

  drugId          String
  drug            DrugItem @relation(fields: [drugId], references: [id])

  quantity        Decimal  // จำนวนที่จ่าย (base unit)
  unitId          String   // หน่วยจ่าย
  lotId           String   // LOT ที่จ่าย (FEFO)

  // Stock journal reference
  stockJournalId  String?  // อ้างอิง stock journal entry

  @@index([dispensingId])
}
```

---

## 5. IPD Dispensing Workflow

### 2 รูปแบบหลัก

```
รูปแบบ A: Individual Prescription (ส่วนใหญ่ใช้)
─────────────────────────────────────────────
แพทย์สั่งยาบน ward (Drug Order)
  │
  ▼
ส่งใบยาไป ห้องจ่ายยา IPD
  │  แยกประเภท: ใบยาปกติ / ใบยาด่วน / ใบยากลับบ้าน
  ▼
เภสัชกร Screen
  ▼
จัดยา (per patient per dose หรือ per day)
  ▼
ส่งยาไป ward → พยาบาลรับ → บริหารยาให้ผู้ป่วย
  │  ตัด stock จาก ห้องจ่ายยา IPD
  ▼
Stock Journal Entry


รูปแบบ B: Floor Stock (ยาสำรองหอผู้ป่วย)
─────────────────────────────────────────────
พยาบาลหยิบยาสำรองจาก ward stock → ให้ผู้ป่วย
  │
  ▼
บันทึกการใช้ในระบบ → ตัด stock จาก ward ทันที
  │  (real-time ผ่าน HIS)
  ▼
เมื่อ stock ≤ parMin → auto-generate ใบเบิกเติม
  │  (top-up to parMax)
  ▼
คลังใหญ่จัดยา → ส่ง ward → ward รับเข้า
```

---

## 6. Real-time Stock Deduction

### หลักการ

ทุกครั้งที่จ่ายยาให้ผู้ป่วย ต้อง:
1. **ตัด stock ทันที** จากคลังย่อยที่จ่าย
2. **เลือก LOT ตาม FEFO** (ใกล้หมดอายุก่อน)
3. **สร้าง stock journal entry** พร้อม reference (prescription/order)

```typescript
async function dispenseDrug(params: {
  warehouseId: string;
  drugId: string;
  quantity: number;      // base unit
  prescriptionId: string;
  dispensedBy: string;
  hospitalId: string;
}) {
  // 1. เลือก LOT ตาม FEFO
  const lots = await prisma.drugLot.findMany({
    where: {
      drugId: params.drugId,
      warehouseId: params.warehouseId,
      currentStock: { gt: 0 },
      expiryDate: { gt: new Date() },
    },
    orderBy: { expiryDate: 'asc' }, // FEFO
  });

  // 2. ตัด stock แบบ multi-lot (ถ้า lot เดียวไม่พอ)
  let remaining = params.quantity;
  const journalEntries = [];

  for (const lot of lots) {
    if (remaining <= 0) break;
    const deductQty = Math.min(remaining, lot.currentStock);

    journalEntries.push({
      drugId: params.drugId,
      warehouseId: params.warehouseId,
      lotId: lot.id,
      movementType: 'DISPENSE',
      direction: 'OUT',
      quantity: deductQty,
      referenceType: 'PRESCRIPTION',
      referenceId: params.prescriptionId,
      hospitalId: params.hospitalId,
      createdBy: params.dispensedBy,
    });

    remaining -= deductQty;
  }

  if (remaining > 0) {
    throw new Error(`STOCKOUT: ยาไม่พอจ่าย ขาดอีก ${remaining} หน่วย`);
    // → track stockout event สำหรับ KPI
  }

  // 3. Atomic transaction
  await prisma.$transaction([
    ...journalEntries.map(entry => prisma.stockJournal.create({ data: entry })),
    // update lot currentStock
    ...journalEntries.map(entry =>
      prisma.drugLot.update({
        where: { id: entry.lotId },
        data: { currentStock: { decrement: entry.quantity } },
      })
    ),
  ]);
}
```

### Auto-Requisition (เบิกเติมอัตโนมัติ)

```typescript
// เมื่อ stock คลังย่อยต่ำกว่า par min → auto-generate ใบเบิก
async function checkAndAutoRequisition(warehouseId: string) {
  const floorStockItems = await prisma.floorStockItem.findMany({
    where: { warehouseId, isActive: true },
  });

  for (const item of floorStockItems) {
    const currentStock = await getCurrentStock(item.drugId, warehouseId);
    if (currentStock <= item.parMin) {
      const reqQty = item.parMax - currentStock; // top-up to max
      await createAutoRequisitionItem(warehouseId, item.drugId, reqQty);
    }
  }
}
```

---

## 7. Drug Return (คืนยา)

### กรณีที่พบ

1. **ผู้ป่วย OPD ไม่มารับยา** — ยาค้างรับ → คืนเข้า stock
2. **แพทย์หยุดยา (IPD)** — ยาที่จัดแล้วยังไม่บริหาร → คืนห้องยา
3. **ยาหมดอายุบน ward** — คืนคลังใหญ่ → ตัดทำลาย
4. **เปลี่ยนยา (switch)** — คืนยาเดิม + จ่ายยาใหม่

```typescript
// Drug return = reverse stock journal
async function returnDrug(params: {
  warehouseId: string;
  drugId: string;
  lotId: string;
  quantity: number;
  reason: ReturnReason;
  originalDispensingId?: string;
  returnedBy: string;
}) {
  await prisma.stockJournal.create({
    data: {
      drugId: params.drugId,
      warehouseId: params.warehouseId,
      lotId: params.lotId,
      movementType: 'RETURN',
      direction: 'IN',  // กลับเข้า stock
      quantity: params.quantity,
      referenceType: 'RETURN',
      referenceId: params.originalDispensingId,
      createdBy: params.returnedBy,
    },
  });
}

enum ReturnReason {
  PATIENT_NO_SHOW     // ผู้ป่วยไม่มารับ
  DISCONTINUED        // แพทย์หยุดยา
  EXPIRED             // หมดอายุ
  DAMAGED             // เสียหาย
  DRUG_SWITCH         // เปลี่ยนยา
  RECALL              // เรียกคืน (manufacturer recall)
}
```

---

## 8. Utilization Evaluation (ข้อ 13 ระเบียบ 2563)

### ระบบประเมินการใช้ยา

คกก. เภสัชกรรมและการบำบัด (PTC) ต้อง monitor:

```typescript
interface UtilizationEvaluation {
  // 1. ประสิทธิผล
  drugUsageByGeneric: GenericUsageReport[];     // ปริมาณใช้ตามชื่อสามัญ
  edRatio: number;                              // ร้อยละยาในบัญชียาหลัก

  // 2. คุณค่า (cost-effectiveness)
  costPerDDD: Map<string, Decimal>;             // ต้นทุนต่อ DDD
  priceVsDMSIC: PriceComparisonReport[];        // ราคาจัดซื้อเทียบ DMSIC

  // 3. ความปลอดภัย
  adrReports: ADRReport[];                      // อาการไม่พึงประสงค์
  medicationErrors: MedicationErrorReport[];    // ความคลาดเคลื่อนทางยา
  highAlertDrugUsage: HighAlertUsageReport[];   // การใช้ยาเสี่ยงสูง

  // 4. Stockout tracking (KPI กระจาย)
  stockoutEvents: StockoutEvent[];              // รายการยาที่ขาดขณะให้บริการ
  stockoutRate: number;                         // ร้อยละ
}
```

### Stockout Event Tracking

```typescript
model StockoutEvent {
  id              String   @id @default(cuid())
  hospitalId      String
  warehouseId     String   // คลังย่อยที่เกิดเหตุ
  drugId          String
  prescriptionId  String?  // ใบสั่งยาที่จ่ายไม่ได้

  occurredAt      DateTime
  resolvedAt      DateTime?
  resolution      StockoutResolution?

  @@index([hospitalId, occurredAt])
  @@index([drugId])
}

enum StockoutResolution {
  TRANSFERRED     // โอนจาก ward อื่น
  BORROWED        // ยืมจาก รพ. อื่น
  SUBSTITUTED     // ใช้ยาทดแทน
  PURCHASED       // จัดซื้อฉุกเฉิน
  CANCELLED       // ยกเลิกการสั่ง
}
```

---

## 9. Key Business Rules สำหรับ Dispensing

| Rule | Description |
|------|-------------|
| **FEFO** | เลือก LOT ที่ใกล้หมดอายุก่อนเสมอ |
| **Generic Name** | ค้นหา/สั่งยาด้วยชื่อสามัญ (เกณฑ์จริยธรรม ข้อ 13) |
| **Real-time** | ตัด stock ทันทีที่จ่ายยา ไม่ batch process |
| **Double Check** | ยา High Alert ต้อง double check โดยเภสัชกร 2 คน |
| **Floor Stock List** | ward สำรองยาได้เฉพาะรายการที่ คกก. อนุมัติ |
| **Par Level** | เบิกเติมแบบ top-up to parMax เมื่อ stock ≤ parMin |
| **ทบทวนบัญชีประจำปี** | floor stock list ทบทวนทุก 1 ปี |
| **Stockout Tracking** | บันทึกทุกครั้งที่ยาขาดขณะจ่าย → KPI กระจาย |
| **Expiry Alert** | แจ้งเตือนยาใกล้หมดอายุ < 6 เดือน + แลกเปลี่ยนระหว่าง ward |
| **Emergency Cart** | รถ Emergency มีรายการเฉพาะ ตรวจสอบทุกเวร/ทุกวัน |
| **Narcotic Control** | ยาเสพติด/วัตถุออกฤทธิ์ มี SOP เบิกจ่ายเฉพาะ + รายงาน |
