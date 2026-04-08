# DMSIC 5-File Drug Administration Data Standard

ระบบส่งข้อมูลบริหารเวชภัณฑ์ (ยา) 5 แฟ้ม ไปยัง DMSIC ตามประกาศ สธ. พ.ศ. 2568
เริ่มส่งตั้งแต่ 20 ส.ค. 2568 | Endpoint: http://203.157.3.54/hssd1/ | JSON + Token auth

## Regulatory Reference
- ประกาศกระทรวงสาธารณสุข เรื่อง มาตรฐานข้อมูลบริหารเวชภัณฑ์ (ยา) พ.ศ. 2568
- ลงวันที่ 29 ก.ค. 2568
- บังคับใช้กับ รพ. ในสังกัด สธ. ทุกแห่ง

---

## 1. ภาพรวม 5 แฟ้ม

| # | แฟ้ม | ลักษณะ | รอบส่ง | Deadline |
|---|------|--------|--------|----------|
| 1 | **DRUGLIST** — บัญชียา รพ. | แฟ้มสะสม | ทุกเดือน | ไม่เกินวันที่ 15 ของเดือนถัดไป |
| 2 | **PURCHASEPLAN** — แผนจัดซื้อ | แฟ้มสะสม | ต้นปีงบ + เมื่อปรับแผน | เดือนที่ประกาศแผนใหม่ |
| 3 | **RECEIPT** — รับยาเข้าคลัง | รายเดือน | ทุกเดือน | ไม่เกิน 10 วัน หลังสิ้นเดือน |
| 4 | **DISTRIBUTION** — จ่ายยาออกจากคลัง | รายเดือน | ทุกเดือน | ไม่เกิน 10 วัน หลังสิ้นเดือน |
| 5 | **INVENTORY** — ยาคงคลัง | รายเดือน | ทุกเดือน | ไม่เกิน 10 วัน หลังสิ้นเดือน |

### Key Conventions ทุกแฟ้ม
- **ปีทั้งหมดเป็น ค.ศ.** (ไม่ใช่ พ.ศ.)
- HOSP_CODE = รหัสหน่วยบริการ 9 หลัก
- WORKING_CODE = รหัสยาภายใน รพ.
- GPUID = รหัส TMT ระดับ GPU (ไม่มี → "99")
- TPUID = รหัส TMT ระดับ TPU (ไม่มี → "99")
- BASE_UNIT = หน่วยนับเล็กที่สุด (DispUnit ตาม TMT)
- PACK_SIZE = จำนวน BASE_UNIT ต่อหีบห่อ
- PACK_COST = ราคาต่อหีบห่อ (ทศนิยม 2 ตำแหน่ง)
- **ส่งเฉพาะยา** (ไม่ส่งเภสัชเคมีภัณฑ์)

---

## 2. DRUGLIST — บัญชียาโรงพยาบาล

รายการยาที่มีใช้ใน รพ. ทุกรายการ (ทั้งที่ใช้อยู่ + ส่งต่อ)

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| HOSP_CODE | String(9) | Y | รหัส รพ. 9 หลัก |
| WORKING_CODE | String | Y | รหัสยาภายใน |
| GENERIC_NAME | String | Y | ชื่อสามัญ (ชื่อ+ความแรง+รูปแบบ) |
| GPUID | String | Y | TMT GPU code (ไม่มี→"99") |
| NLEM | "E"/"N" | N | ED=ยาหลัก, NED=นอกบัญชี |
| PRODUCT_CAT | "1"-"5" | Y | 1=ขึ้นอย.2=รพ.ผลิต 3=สมุนไพรอย.4=สมุนไพรรพ.5=อื่น |
| BASE_UNIT | String | N | หน่วยจ่ายเล็กสุด (DispUnit TMT) |
| STATUS | "1"-"4" | Y | 1=ใช้อยู่ 2=ตัดแต่มียาเหลือ 3=เฉพาะราย 4=ตัดออกหมด |
| DATE_STATUS | YYYYMMDD | Y | วันที่เปลี่ยนสถานะ |
| PERIOD_RPT | YYYYMM | Y | เดือนที่รายงาน (ค.ศ.) |
| DATE_SEND | YYYYMMDDHHMMSS | Y | วันเวลาที่ส่ง |

### AegisX Mapping
DRUGLIST ← DrugMaster: workingCode, genericName, tmtGpuId, nlemStatus, productCategory, dispensingUnit, status

---

## 3. PURCHASEPLAN — แผนปฏิบัติการจัดซื้อยา

แผนจัดซื้อทุกรายการยา แบ่ง 4 ไตรมาส

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| HOSP_CODE | String(9) | Y | |
| YEARBUDGET | YYYY | Y | ปีงบประมาณ (ค.ศ.) |
| WORKING_CODE | String | Y | |
| GENERIC_NAME | String | Y | |
| GPUID | String | Y | |
| NLEM | "E"/"N" | N | |
| QTY_USE_YEAR3 | Int | N | ใช้ย้อน 3 ปี (หน่วย PACK_SIZE) |
| QTY_USE_YEAR2 | Int | N | ใช้ย้อน 2 ปี |
| QTY_USE_YEAR1 | Int | N | ใช้ย้อน 1 ปี |
| QTY_THIS_YEAR | Int | Y | แผนจัดซื้อปีนี้ |
| PACK_SIZE | Int | N | จำนวน BASE_UNIT ต่อ pack |
| BASE_UNIT | String | N | |
| PACK_COST | Decimal(2) | Y | ราคาต่อ pack |
| VALUE_THIS_YEAR | Decimal(2) | Y | = QTY_THIS_YEAR x PACK_COST |
| QTY_PLAN_TRIMES1-4 | Int | Y | แผนซื้อรายไตรมาส |
| PERIOD_RPT | YYYYMM | Y | |
| DATE_SEND | YYYYMMDDHHMMSS | Y | |

### Cross-field Rules
- VALUE_THIS_YEAR = QTY_THIS_YEAR x PACK_COST
- SUM(QTY_PLAN_TRIMES1-4) ≈ QTY_THIS_YEAR

### AegisX Mapping
PURCHASEPLAN ← ProcurementPlan + ProcurementPlanItem

---

## 4. RECEIPT — การรับยาเข้าคลัง

ข้อมูลการรับยาจาก จัดซื้อ/ยืม/โอน/บริจาค

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| HOSP_CODE | String(9) | Y | |
| WORKING_CODE | String | Y | |
| TRADE_NAME | String | N | ชื่อการค้า |
| TPUID | String | Y | TMT TPU code |
| VENDOR_NAME | String | N | ผู้จัดจำหน่าย |
| VENDOR_TAX_ID | String | N | เลขผู้เสียภาษี |
| QTY_RCV | Int | Y | จำนวนรับ (PACK_SIZE) |
| PACK_SIZE | Int | Y | |
| BASE_UNIT | String | Y | |
| PACK_COST | Decimal(2) | Y | ราคาต่อ pack (ยาบริจาค→ใส่ราคาขายจริง) |
| TOTAL_VALUE | Decimal(2) | N | = QTY_RCV x PACK_COST |
| LOT_NO | String | Y | เลขที่ผลิต |
| EXPIRE_DATE | YYYYMMDD | Y | วันหมดอายุ |
| RCV_NO | String | Y | เลขที่ใบรับสินค้า |
| PO_NO | String | N | เลขที่ใบสั่งซื้อ |
| CNT_NO | String | N | เลขที่สัญญา |
| DATE_RCV | YYYYMMDD | Y | วันที่รับ |
| BUY_METHOD_ID | Int | Y | วิธีจัดหา (10-99) |
| CO_PURCHASE_ID | Int | Y | 1=ไม่ซื้อร่วม 2=จังหวัด 3=เขต 4=กรม 5=ประเทศ |
| RCV_FLAG | "1"-"9" | Y | 1=ซื้อ 2=ชดเชย/บริจาค 3=ผลิตเอง 4=ยืม 9=อื่น |

### BUY_METHOD_ID Reference
10=ประกาศเชิญชวน, 11=e-Market, 12=e-Bidding, 13=สอบราคา,
20=คัดเลือก, 30=เฉพาะเจาะจง, 32=ไม่เกิน 500k,
38=กฎกระทรวง(นวัตกรรม/GPO), 95=สปสช., 96=ปกส., 99=อื่น

### AegisX Mapping
RECEIPT ← GoodsReceiving + GoodsReceivingItem + PurchaseOrder + Vendor

---

## 5. DISTRIBUTION — การจ่ายยาออกจากคลัง

สรุปรายเดือน: 1 WORKING_CODE + 1 DIS_DEPT_GROUP + 1 TPUID = 1 record

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| HOSP_CODE | String(9) | Y | |
| WORKING_CODE | String | Y | |
| TRADE_NAME | String | N | |
| TPUID | String | Y | |
| QTY_DIS | Decimal | Y | จำนวนจ่าย (PACK_SIZE) |
| PACK_SIZE | Int | Y | |
| BASE_UNIT | String | Y | |
| VALUE | Decimal(2) | Y | มูลค่าจ่าย |
| DIS_DEPT_GROUP | "1"-"9" | Y | กลุ่มหน่วยเบิก |

### DIS_DEPT_GROUP Reference
| Code | กลุ่ม | ความหมาย |
|------|-------|---------|
| 1 | OPD+IPD | หน่วยเบิกทั้ง OPD/IPD สัดส่วนใกล้เคียง |
| 2 | OPD | บริการ OPD เป็นหลัก (>70%) |
| 3 | IPD | บริการ IPD เป็นหลัก (>70%) |
| 4 | อื่นใน รพ. | ห้องผ่าตัด, X-ray |
| 5 | รพ.สต. | ในเครือข่ายเดียวกัน |
| 6 | รพ.สต.ถ่ายโอน | ถ่ายโอนไป อปท. |
| 9 | อื่นนอก รพ. | รพ.อื่น ไม่ใช่ CUP |

### AegisX Mapping
DISTRIBUTION ← aggregate(RequisitionDispensing) group by month + dept_group
- ต้อง map Department/Warehouse → DIS_DEPT_GROUP

---

## 6. INVENTORY — ยาคงคลัง

สิ้นเดือน: 1 WORKING_CODE + 1 LOT_NO + 1 PACK_SIZE = 1 record
ส่งเฉพาะ QTY_ONHAND > 0

### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| HOSP_CODE | String(9) | Y | |
| WORKING_CODE | String | Y | |
| TRADE_NAME | String | N | |
| TPUID | String | Y | |
| VENDOR_NAME | String | N | |
| VENDOR_TAX_ID | String | N | |
| QTY_ONHAND | Int | Y | คงคลัง ณ สิ้นเดือน (PACK_SIZE) |
| PACK_SIZE | Int | Y | |
| BASE_UNIT | String | Y | |
| PACK_COST | Decimal(2) | Y | ราคาต่อ pack |
| VALUE_ONHAND | Decimal(2) | Y | = QTY_ONHAND x PACK_COST |
| LOT_NO | String | Y* | *required เมื่อ QTY > 0 |
| EXPIRE_DATE | YYYYMMDD | Y* | *required เมื่อ QTY > 0 |
| DATE_ONHAND | YYYYMMDD | Y | วันที่รายงาน |

### AegisX Mapping
INVENTORY ← Stock snapshot ณ สิ้นเดือน (DrugLot + StockJournal)

---

## 7. PACK_SIZE / PACK_COST (Critical)

จุดที่ผิดพลาดบ่อยที่สุด:

```
ตัวอย่าง: ยา Amoxicillin Injection
1 กล่อง = 20 ampoules, ราคากล่องละ 2,000 บาท

กรณี A: PACK_SIZE=20, BASE_UNIT=ampoule, PACK_COST=2000.00
  → 1 pack = 20 ampoules @ 2,000 บาท

กรณี B: PACK_SIZE=1, BASE_UNIT=ampoule, PACK_COST=100.00
  → 1 pack = 1 ampoule @ 100 บาท (2000/20)

ทั้ง 2 กรณีถูก แต่ต้องใช้ consistent ทั้ง 5 แฟ้ม
PACK_SIZE x PACK_COST ต้องสอดคล้องกับ TOTAL_VALUE / VALUE_ONHAND / VALUE_THIS_YEAR
```

---

## 8. Fiscal Year (ค.ศ.)

```typescript
// ปีงบ 2568 (พ.ศ.) = 2025 (ค.ศ.) = ต.ค. 2024 → ก.ย. 2025
// YEARBUDGET ใน PURCHASEPLAN = "2025" (ค.ศ.)
function thaiToChristianYear(thaiYear: number): number {
  return thaiYear - 543;
}
```

---

## 9. AegisX Implementation

### Prisma Tables ที่ต้องเพิ่ม
- DmsicDruglist, DmsicPurchasePlan, DmsicReceipt, DmsicDistribution, DmsicInventory
- DmsicBuyMethod (reference), DmsicDeptGroup (reference)
- ดู schema เต็มใน spec document

### API Routes
```
GET  /api/dmsic/export/:fileType/:periodRpt    → JSON ตาม format
POST /api/dmsic/validate/:fileType/:periodRpt  → ตรวจก่อนส่ง
POST /api/dmsic/submit/:fileType/:periodRpt    → ส่ง DMSIC
POST /api/dmsic/generate/:fileType/:periodRpt  → สร้างข้อมูลจาก AegisX
GET  /api/dmsic/status/:periodRpt              → สถานะการส่ง 5 แฟ้ม
```

### Validation 3 ชั้น
1. **File-level**: hosp_code, period_rpt, file_type ครบ
2. **Record-level**: required fields, format, enum values
3. **Cross-field**: VALUE = QTY x COST, SUM(Q1-Q4) = TOTAL, LOT required when QTY > 0

### Implementation Priority
Phase 1: Schema + Seed → Phase 2: Data generation → Phase 3: Validation + Export → Phase 4: UI Dashboard
