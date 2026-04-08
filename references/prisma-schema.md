# Prisma Schema Reference

ภาพรวม Data Model ทั้งระบบคลังยา — ใช้อ้างอิงเมื่อสร้าง migration หรือ Prisma schema

## Regulatory Compliance Notes

- Models ด้าน procurement ออกแบบตามแบบฟอร์มแนบท้ายระเบียบ สธ. 2563
- **ห้ามมี discount/rebate fields** ใน PO/Contract (เกณฑ์จริยธรรม ข้อ 15(2) — ราคาสุทธิเท่านั้น)
- DrugItem ต้องมี `edNedType`, `venClass`, `gpuCode` สำหรับแผนจัดซื้อ
- ต้องมี `DrugRole` enum สำหรับ separation of duties (PURCHASER ≠ WAREHOUSE_KEEPER)
- ดู data models ใหม่สำหรับ procurement plan ที่ `budget-procurement.md`
- ดู data models สำหรับ DMSIC reference price ที่ `budget-procurement.md` section 7

## Table of Contents
1. [Enums](#enums)
2. [Core Models](#core-models)
3. [Relationships Diagram](#relationships)
4. [Index Strategy](#indexes)
5. [Multi-tenant Pattern](#multi-tenant)

---

## Enums {#enums}

```prisma
// Drug Classification
enum VenClass {
  VITAL
  ESSENTIAL
  NON_ESSENTIAL
}

enum NedList {
  NED_A       // บัญชี ก
  NED_B       // บัญชี ข
  NED_C       // บัญชี ค
  NED_D       // บัญชี ง
  NED_E       // บัญชี จ (สมุนไพร)
  NON_NED     // นอกบัญชี
}

enum HighAlertCategory {
  LASA
  HIGH_RISK
  NARROW_TI
  CYTOTOXIC
}

enum UnitLevel {
  PACKAGE     // หน่วยสั่งซื้อ
  TRADE       // หน่วยเบิก
  BASE        // หน่วยจ่าย (smallest)
}

// Warehouse
enum WarehouseType {
  CENTRAL
  SUB_STORE
  EMERGENCY
}

// Stock
enum StockMovementType {
  RECEIVE
  DISPENSE
  TRANSFER
  ADJUST
  RETURN
  EXPIRE
  DAMAGE
}

// Budget/Plan (ใช้ PlanStatus แทน BudgetStatus — ดู budget-procurement.md)
// Legacy enum สำหรับ backward compatibility
enum BudgetStatus {
  DRAFT
  SUBMITTED
  APPROVED
  ACTIVE        // เพิ่มใหม่ — ดำเนินการจัดซื้อ
  CLOSED        // ปิดงบสิ้นปี
}

enum BudgetEntryType {
  ALLOCATE          // จัดสรรงบต้นปี
  SUPPLEMENT        // งบเพิ่มเติม (revision)
  COMMITTED         // ผูกพันงบ (PO created)
  SPENT             // ใช้จริง (GR received)
  RELEASED          // ปลดผูกพัน (PO cancelled)
  ADJUSTMENT        // ปรับปรุงอื่นๆ
}

// Budget Revision — ดู RevisionType ใน section ใหม่ด้านล่าง
// (ย้ายไปรวมกับ enums ตามระเบียบ 2563)

// Procurement
enum PrStatus {
  DRAFT
  PENDING
  APPROVED
  REJECTED
  PO_CREATED
}

enum PoStatus {
  DRAFT
  SENT
  PARTIAL_RECEIVED
  COMPLETED
  CANCELLED
}

enum GrStatus {
  DRAFT
  INSPECTING
  COMPLETED
  REJECTED
}

enum ContractType {
  FIXED_PRICE_ANNUAL    // สัญญาราคาคงที่รายปี (ข้อ 10 ระเบียบ 2563)
  FIXED_PRICE_PERIOD    // สัญญาราคาคงที่ตามระยะเวลา
  BLANKET               // สัญญาจะซื้อจะขาย
}

enum ProcurementMethod {
  SPECIFIC              // วิธีเฉพาะเจาะจง (≤500k)
  E_BIDDING             // ประกาศเชิญชวนทั่วไป
  SELECTION             // วิธีคัดเลือก
  JOINT_PURCHASE        // จัดซื้อร่วม (ข้อ 9 ระเบียบ 2563)
}

// NEW — ตามระเบียบ 2563
enum PlanType {
  DRUG                  // แผนจัดซื้อยา
  NON_DRUG_MEDICAL      // แผนจัดซื้อเวชภัณฑ์ที่มิใช่ยา
}

enum PlanStatus {
  DRAFT
  SUBMITTED             // เสนอ คกก.
  APPROVED              // คกก./ผอ. อนุมัติ
  ACTIVE                // ดำเนินการจัดซื้อ (เริ่ม ต.ค.)
  CLOSED                // ปิดงบสิ้นปี
}

enum EdNedType {
  ED                    // ยาในบัญชียาหลักแห่งชาติ
  NED                   // ยานอกบัญชียาหลัก
}

enum RevisionType {
  ADD_ITEM              // เพิ่มรายการยาใหม่
  INCREASE_BUDGET       // เพิ่มวงเงิน
  CHANGE_ITEM           // เปลี่ยนรายการ (ยาขาดตลาด)
  PRICE_CHANGE          // ราคาเปลี่ยน
  EMERGENCY             // กรณีฉุกเฉิน (โรคระบาด)
}

enum DrugRole {
  PURCHASER             // ผู้จัดซื้อ
  WAREHOUSE_KEEPER      // ผู้ควบคุมคลัง (≠ PURCHASER ตามข้อ 11)
  INSPECTOR             // กรรมการตรวจรับ
  APPROVER              // ผู้อนุมัติ
  PHARMACIST            // เภสัชกร
}

enum FundSource {
  HOSPITAL_REVENUE
  GOVERNMENT_BUDGET
  DONATION
  OTHER
}

enum ContractStatus {
  ACTIVE
  EXPIRED
  CANCELLED
}

// Requisition
enum ReqStatus {
  DRAFT
  SUBMITTED
  PROCESSING
  DISPENSED
  RECEIVED
  CANCELLED
}

// Prescription
enum EncounterType {
  OPD
  IPD
  ER
}

enum PrescriptionStatus {
  ORDERED
  VERIFIED
  DISPENSED
  PARTIALLY_DISPENSED
  CANCELLED
}

enum AuthLockType {
  DOCTOR
  DEPARTMENT
  SPECIALTY
}

enum AdjustmentType {
  COUNT
  DAMAGE
  EXPIRE
  OTHER
}

enum AdjustmentStatus {
  DRAFT
  APPROVED
  COMPLETED
}
```

---

## Core Models Summary {#core-models}

### Drug Master Data Layer

| Model | คำอธิบาย | Key Fields |
|-------|----------|------------|
| `GenericProduct` | ตัวยาสามัญ (GP) | gpCode, name, strength, dosageForm |
| `GenericProductUse` | GP + route (GPU) | gpuCode, routeOfAdmin |
| `TradeProduct` | ชื่อการค้า (TP) | tradeName, manufacturer |
| `TradeProductUse` | TP + route (TPU) | tpuCode |
| `TradeProductUnitUse` | TPU + unit (TPUU) | tpuuCode, unitId |
| `DrugUnit` | หน่วยนับ | name, nameEn, abbr |
| `DrugUnitConversion` | ตารางแปลงหน่วย | ratioToBase, unitLevel |
| `DrugItem` | ยาระดับ รพ. | venClass, nedList, costPrice, minStock |
| `DrugAuthLock` | จำกัดการสั่งยา | lockType, lockValue |

### Warehouse Layer

| Model | คำอธิบาย | Key Fields |
|-------|----------|------------|
| `Warehouse` | คลังยา | warehouseType, parentId |
| `DrugLot` | LOT/Batch | lotNumber, expiryDate, currentStock |
| `StockJournal` | บันทึกเข้า-ออก | movementType, direction, quantity |
| `StockAdjustment` | ปรับยอด | adjustmentType, reason |
| `StockAdjustmentItem` | รายละเอียดปรับ | systemQty, actualQty |

### Budget & Procurement Layer

| Model | คำอธิบาย | Key Fields |
|-------|----------|------------|
| `AnnualDrugBudget` | งบประจำปี (ไม่เก็บ totalAmount — คำนวณจาก journal) | fiscalYear, status |
| `BudgetItem` | รายการยาในงบ (ปรับได้ตลอดปี) | initialQty, currentQty, currentTotalPrice, isActive |
| `BudgetJournal` | บันทึกงบระดับวงเงินรวม (append-only) | entryType, amount, revisionId |
| `BudgetRevision` | ครั้งที่ปรับงบ (audit trail) | revisionType, title, reason, totalAmountChange |
| `BudgetItemJournal` | บันทึกเปลี่ยนแปลงระดับรายการยา | changeType, field, oldValue, newValue, amountImpact |
| `Vendor` | ผู้จำหน่าย | name, taxId, contact |
| `Contract` | สัญญา | contractType, procurementMethod |
| `ContractItem` | รายการในสัญญา | agreedQty, unitPrice |
| `PurchaseRequisition` | ใบขอซื้อ (PR) | prNumber, status |
| `PrItem` | รายการใน PR | genericProductId, quantity |
| `PurchaseOrder` | ใบสั่งซื้อ (PO) | poNumber, vendorId, totalAmount |
| `PoItem` | รายการใน PO | quantity, receivedQty |
| `GoodsReceiving` | ใบรับของ (GR) | poId, receivedDate |
| `GrItem` | รายการรับ | lotNumber, expiryDate, receivedQty |

### Dispensing Layer

| Model | คำอธิบาย | Key Fields |
|-------|----------|------------|
| `Requisition` | ใบเบิกยา | fromWarehouseId, toWarehouseId |
| `RequisitionItem` | รายการเบิก | requestedQty, dispensedQty |
| `RequisitionLotSelection` | เลือก LOT เบิก | lotId, quantity |
| `Prescription` | ใบสั่งยา | patientId, prescribedBy |
| `PrescriptionItem` | รายการสั่งยา | dosage, quantity |
| `DispenseLotSelection` | เลือก LOT จ่าย | lotId, quantity |

---

## Relationships Diagram {#relationships}

```
GenericProduct (GP)
  └── GenericProductUse (GPU)
        └── TradeProduct (TP)
              ├── TradeProductUse (TPU)
              │     └── TradeProductUnitUse (TPUU) ──── DrugUnit
              ├── DrugUnitConversion
              └── DrugItem
                    ├── DrugAuthLock
                    ├── BudgetItem ──── AnnualDrugBudget ──── BudgetJournal
                    ├── ContractItem ──── Contract ──── Vendor
                    ├── PrItem ──── PurchaseRequisition
                    ├── PoItem ──── PurchaseOrder ──── GoodsReceiving
                    │                                    └── GrItem ──── DrugLot
                    ├── RequisitionItem ──── Requisition
                    │     └── RequisitionLotSelection ──── DrugLot
                    ├── PrescriptionItem ──── Prescription
                    │     └── DispenseLotSelection ──── DrugLot
                    └── DrugLot ──── Warehouse
                          └── StockJournal
```

---

## Index Strategy {#indexes}

```prisma
// Performance-critical indexes

// Drug search
@@index([hospitalId, tradeName])           // on TradeProduct
@@index([hospitalId, name])                // on GenericProduct

// Stock queries (most frequent)
@@index([warehouseId, drugItemId])          // on DrugLot
@@index([warehouseId, expiryDate])          // on DrugLot (FEFO)
@@index([drugId, warehouseId, createdAt])   // on StockJournal (stock card)
@@index([hospitalId, movementType])         // on StockJournal (reports)

// Procurement
@@index([hospitalId, fiscalYear, status])   // on PurchaseOrder, PurchaseRequisition
@@index([hospitalId, vendorId])             // on PurchaseOrder
@@index([hospitalId, status])               // on Contract

// Dispensing
@@index([hospitalId, patientId])            // on Prescription
@@index([hospitalId, encounterType])        // on Prescription

// Budget
@@index([hospitalId, fiscalYear])           // on AnnualDrugBudget, BudgetJournal
```

---

## Multi-tenant Pattern {#multi-tenant}

ทุก model ต้องมี `hospitalId` — ใช้ Row-Level Security pattern:

```typescript
// Prisma middleware: Auto-inject hospitalId
prisma.$use(async (params, next) => {
  if (params.action === 'create' || params.action === 'createMany') {
    params.args.data.hospitalId = getCurrentHospitalId();
  }
  if (['findMany', 'findFirst', 'count', 'aggregate'].includes(params.action)) {
    params.args.where = {
      ...params.args.where,
      hospitalId: getCurrentHospitalId(),
    };
  }
  return next(params);
});
```

### Unique Constraints with hospitalId

```prisma
// All unique constraints should include hospitalId
@@unique([hospitalId, code])              // Warehouse
@@unique([hospitalId, prNumber])          // PurchaseRequisition  
@@unique([hospitalId, poNumber])          // PurchaseOrder
@@unique([hospitalId, tradeProductId])    // DrugItem
@@unique([drugItemId, warehouseId, lotNumber])  // DrugLot
```
