# Warehouse & Receiving Reference

ระบบจัดการคลังยาหลัก: รับยาเข้า (Goods Receiving), จัดการ LOT/Batch, Stock Adjustment

## Regulatory Compliance

- **ระเบียบ สธ. 2563 ข้อ 11**: **ผู้จัดซื้อ กับ ผู้ควบคุมคลัง ต้องเป็นคนละคน**
  → RBAC ต้อง enforce separation of duties (ดู SKILL.md pattern #5)
- **ระเบียบ สธ. 2563 ข้อ 10**: ตรวจรับโดย **กรรมการตรวจรับ** (ไม่ใช่ผู้จัดซื้อ)
  → GR approval ต้องผ่าน INSPECTOR role, ไม่ใช่ PURCHASER
- **มาตรฐาน สธ.**: คงคลังไม่เกิน **2 เดือน** + ตรวจ Min stock **รายสัปดาห์**
  → Stock months alert + weekly min stock report
- **สูตรคำนวณ**: Min stock = ใช้/ปี ÷ 12, Max stock = Min × 1.5
- **เกณฑ์จริยธรรม 2564 ข้อ 15(5.4)**: ระบบบริหารความเสี่ยงทุจริต + ตรวจสอบภายใน
  → Audit trail ครบทุก stock movement

## Table of Contents
1. [Warehouse Structure](#warehouse-structure)
2. [Goods Receiving (GR)](#goods-receiving)
3. [LOT/Batch Management](#lot-management)
4. [Stock Journal System](#stock-journal)
5. [Stock Adjustment](#stock-adjustment)
6. [Inventory Reports](#reports)

---

## Warehouse Structure {#warehouse-structure}

### ประเภทคลัง

```typescript
model Warehouse {
  id              String   @id @default(cuid())
  hospitalId      String
  code            String            // รหัสคลัง
  name            String            // ชื่อคลัง
  warehouseType   WarehouseType     // CENTRAL | SUB_STORE | EMERGENCY
  parentId        String?           // คลังแม่ (สำหรับ sub-store)
  parent          Warehouse? @relation("WarehouseHierarchy", fields: [parentId], references: [id])
  children        Warehouse[] @relation("WarehouseHierarchy")

  departmentId    String?           // แผนกที่ดูแล
  locationDesc    String?           // ที่ตั้ง
  isActive        Boolean @default(true)

  // Stock management
  stockJournals   StockJournal[]
  drugLots        DrugLot[]

  @@unique([hospitalId, code])
}

enum WarehouseType {
  CENTRAL     // คลังใหญ่/คลังกลาง ห้องยา
  SUB_STORE   // คลังย่อย หอผู้ป่วย/หน่วยบริการ
  EMERGENCY   // คลังฉุกเฉิน ER
}
```

### ตัวอย่างโครงสร้างคลัง

```
คลังกลาง (CENTRAL)
├── คลังย่อย OPD (SUB_STORE)
├── คลังย่อย IPD-อายุรกรรม (SUB_STORE)
├── คลังย่อย IPD-ศัลยกรรม (SUB_STORE)
├── คลังย่อย OR (SUB_STORE)
├── คลังย่อย ER (EMERGENCY)
├── คลังย่อย ICU (SUB_STORE)
└── คลังเคมีบำบัด (SUB_STORE)
```

---

## Goods Receiving (GR) {#goods-receiving}

### GR Workflow

```
PO ส่งให้ vendor → vendor ส่งของ → ตรวจรับ → บันทึก GR → Stock IN
```

```typescript
model GoodsReceiving {
  id              String   @id @default(cuid())
  grNumber        String   @unique     // เลขที่ใบรับ
  hospitalId      String

  poId            String
  po              PurchaseOrder @relation(fields: [poId], references: [id])
  warehouseId     String               // คลังที่รับเข้า (ปกติ = CENTRAL)
  warehouse       Warehouse @relation(fields: [warehouseId], references: [id])

  receivedDate    DateTime
  receivedBy      String               // ผู้รับ
  invoiceNumber   String?              // เลขที่ใบส่งของ
  invoiceDate     DateTime?

  status          GrStatus             // DRAFT | INSPECTING | COMPLETED | REJECTED
  inspectedBy     String?              // ผู้ตรวจรับ (กรรมการตรวจรับ)
  inspectedDate   DateTime?
  inspectionNotes String?

  items           GrItem[]
  stockJournals   StockJournal[]

  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}

model GrItem {
  id              String   @id @default(cuid())
  grId            String
  gr              GoodsReceiving @relation(fields: [grId], references: [id])
  poItemId        String               // อ้างอิง PO Item
  poItem          PoItem @relation(fields: [poItemId], references: [id])

  drugItemId      String
  drugItem        DrugItem @relation(fields: [drugItemId], references: [id])

  // Received info
  receivedQty     Float                // จำนวนที่รับ
  unitId          String               // package unit (pre-populated from PO)
  unitPrice       Decimal              // ราคาต่อหน่วย

  // LOT info
  lotNumber       String               // เลข LOT/Batch
  manufacturingDate DateTime?          // วันผลิต
  expiryDate      DateTime             // วันหมดอายุ

  // QC
  isAccepted      Boolean @default(true)
  rejectedQty     Float?               // จำนวนที่ reject
  rejectionReason String?

  hospitalId      String
}
```

### Pre-populate from PO

เมื่อสร้าง GR ระบบ pre-populate ข้อมูลจาก PO:

```typescript
// API: Create GR from PO
fastify.post('/api/v1/warehouse/goods-receiving', async (req) => {
  const { poId } = req.body;

  const po = await prisma.purchaseOrder.findUnique({
    where: { id: poId },
    include: {
      items: {
        include: {
          drugItem: { include: { tradeProduct: true } },
        },
        where: { remainingQty: { gt: 0 } }, // เฉพาะรายการที่ยังรับไม่ครบ
      },
    },
  });

  // Pre-populate GR items from PO items
  const grItems = po.items.map(poItem => ({
    poItemId: poItem.id,
    drugItemId: poItem.drugItemId,
    receivedQty: poItem.remainingQty, // default = จำนวนคงค้าง
    unitId: poItem.unitId,            // package unit from PO
    unitPrice: poItem.unitPrice,
    lotNumber: '',                    // ผู้รับกรอกเอง
    expiryDate: null,                 // ผู้รับกรอกเอง
  }));

  return { poId, poNumber: po.poNumber, items: grItems };
});
```

### GR Completion — Create Stock Journal

เมื่อ GR สถานะ COMPLETED → สร้าง stock journal entries:

```typescript
async function completeGoodsReceiving(grId: string) {
  const gr = await prisma.goodsReceiving.findUnique({
    where: { id: grId },
    include: { items: true },
  });

  await prisma.$transaction(async (tx) => {
    for (const item of gr.items) {
      if (!item.isAccepted) continue;

      // Get conversion to base unit
      const conversion = await getConversionRatio(item.drugItemId, item.unitId);
      const baseQty = toBaseUnit(item.receivedQty, conversion.ratioToBase);

      // Find or create LOT
      const lot = await tx.drugLot.upsert({
        where: {
          drugItemId_warehouseId_lotNumber: {
            drugItemId: item.drugItemId,
            warehouseId: gr.warehouseId,
            lotNumber: item.lotNumber,
          },
        },
        create: {
          drugItemId: item.drugItemId,
          warehouseId: gr.warehouseId,
          lotNumber: item.lotNumber,
          expiryDate: item.expiryDate,
          manufacturingDate: item.manufacturingDate,
          currentStock: baseQty,
          hospitalId: gr.hospitalId,
        },
        update: {
          currentStock: { increment: baseQty },
        },
      });

      // Create stock journal entry
      await tx.stockJournal.create({
        data: {
          drugId: item.drugItemId,
          warehouseId: gr.warehouseId,
          lotId: lot.id,
          movementType: 'RECEIVE',
          direction: 'IN',
          quantity: baseQty,
          baseUnitId: conversion.toBaseUnitId,
          referenceType: 'GR',
          referenceId: gr.id,
          hospitalId: gr.hospitalId,
          createdBy: gr.receivedBy,
        },
      });
    }

    // Update PO received quantities
    for (const item of gr.items) {
      if (!item.isAccepted) continue;
      await tx.poItem.update({
        where: { id: item.poItemId },
        data: {
          receivedQty: { increment: item.receivedQty },
          remainingQty: { decrement: item.receivedQty },
        },
      });
    }

    // Update GR status
    await tx.goodsReceiving.update({
      where: { id: grId },
      data: { status: 'COMPLETED' },
    });
  });
}
```

---

## LOT/Batch Management {#lot-management}

```typescript
model DrugLot {
  id              String   @id @default(cuid())
  drugItemId      String
  drugItem        DrugItem @relation(fields: [drugItemId], references: [id])
  warehouseId     String
  warehouse       Warehouse @relation(fields: [warehouseId], references: [id])

  lotNumber       String             // เลข LOT
  manufacturingDate DateTime?        // วันผลิต
  expiryDate      DateTime           // วันหมดอายุ
  currentStock    Float              // stock ปัจจุบัน (base unit) — denormalized for query performance

  hospitalId      String

  @@unique([drugItemId, warehouseId, lotNumber])
  @@index([warehouseId, expiryDate])  // For FEFO queries
}
```

### Expiry Alert

```typescript
// Service: ตรวจยาใกล้หมดอายุ
async function getExpiringDrugs(hospitalId: string, daysAhead: number = 90) {
  const alertDate = new Date();
  alertDate.setDate(alertDate.getDate() + daysAhead);

  return prisma.drugLot.findMany({
    where: {
      hospitalId,
      currentStock: { gt: 0 },
      expiryDate: { lte: alertDate, gt: new Date() },
    },
    include: {
      drugItem: { include: { tradeProduct: { include: { gpu: { include: { gp: true } } } } } },
      warehouse: true,
    },
    orderBy: { expiryDate: 'asc' },
  });
}
```

---

## Stock Journal System {#stock-journal}

### Movement Types

```typescript
enum StockMovementType {
  RECEIVE     // รับยาเข้า (จาก GR)
  DISPENSE    // จ่ายยา (ให้คนไข้)
  TRANSFER    // โอนย้ายระหว่างคลัง
  ADJUST      // ปรับยอด (นับ stock)
  RETURN      // คืนยา (คนไข้คืน/คืน vendor)
  EXPIRE      // ยาหมดอายุ (ตัดออก)
  DAMAGE      // ยาเสียหาย
}
```

### Query Current Stock

```typescript
// Get current stock for a warehouse
async function getWarehouseStock(warehouseId: string, hospitalId: string) {
  return prisma.drugLot.findMany({
    where: {
      warehouseId,
      hospitalId,
      currentStock: { gt: 0 },
      expiryDate: { gt: new Date() },
    },
    include: {
      drugItem: {
        include: {
          tradeProduct: { include: { gpu: { include: { gp: true } } } },
        },
      },
    },
    orderBy: [
      { drugItem: { tradeProduct: { tradeName: 'asc' } } },
      { expiryDate: 'asc' },
    ],
  });
}

// Get total stock across all warehouses for a drug
async function getDrugTotalStock(drugItemId: string, hospitalId: string) {
  const result = await prisma.drugLot.aggregate({
    where: {
      drugItemId,
      hospitalId,
      currentStock: { gt: 0 },
      expiryDate: { gt: new Date() },
    },
    _sum: { currentStock: true },
  });
  return result._sum.currentStock || 0;
}
```

---

## Stock Adjustment {#stock-adjustment}

เมื่อนับ stock จริง ≠ stock ในระบบ:

```typescript
model StockAdjustment {
  id              String   @id @default(cuid())
  adjustmentNumber String  @unique
  hospitalId      String
  warehouseId     String

  adjustmentType  AdjustmentType    // COUNT | DAMAGE | EXPIRE | OTHER
  reason          String
  status          AdjustmentStatus  // DRAFT | APPROVED | COMPLETED

  items           StockAdjustmentItem[]
  approvedBy      String?
  approvedAt      DateTime?

  createdBy       String
  createdAt       DateTime @default(now())
}

model StockAdjustmentItem {
  id              String   @id @default(cuid())
  adjustmentId    String
  adjustment      StockAdjustment @relation(fields: [adjustmentId], references: [id])

  drugItemId      String
  lotId           String
  systemQty       Float            // จำนวนในระบบ
  actualQty       Float            // จำนวนนับจริง
  differenceQty   Float            // ผลต่าง (actual - system)

  hospitalId      String
}
```

---

## Inventory Reports {#reports}

### รายงานที่ต้องมี

1. **Stock Card (บัตรคลัง)** — ประวัติเข้า-ออกของยาแต่ละรายการ
2. **Stock Balance** — ยอดคงเหลือรวมทุกคลัง/แยกคลัง
3. **Expiry Alert** — ยาที่ใกล้/หมดอายุ (30/60/90/180 วัน)
4. **Slow Moving** — ยาที่ไม่เคลื่อนไหวนาน
5. **ABC Analysis** — จัดกลุ่มยาตามมูลค่า (A=80%, B=15%, C=5%)
6. **Stock Turnover** — อัตราหมุนเวียนยา

### Stock Card API

```typescript
fastify.get('/api/v1/warehouse/stock-card/:drugItemId', async (req) => {
  const { drugItemId } = req.params;
  const { warehouseId, startDate, endDate } = req.query;

  const journals = await prisma.stockJournal.findMany({
    where: {
      drugId: drugItemId,
      warehouseId,
      hospitalId: req.hospitalId,
      createdAt: {
        gte: new Date(startDate),
        lte: new Date(endDate),
      },
    },
    orderBy: { createdAt: 'asc' },
  });

  // Calculate running balance
  let balance = 0; // or get opening balance
  return journals.map(j => {
    balance += j.direction === 'IN' ? j.quantity : -j.quantity;
    return { ...j, runningBalance: balance };
  });
});
```
