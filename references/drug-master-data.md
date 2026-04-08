# Drug Master Data Reference

ข้อมูลหลักยา (Drug Master Data) เป็นหัวใจของระบบคลังยาทั้งหมด ทุก module อ้างอิงข้อมูลจากที่นี่

## Regulatory Compliance

- **เกณฑ์จริยธรรม 2564 ข้อ 13**: ต้องสั่งยาด้วย **ชื่อสามัญทางยา (generic name)**
  → Generic name เป็น primary display/search ทุก screen, trade name เป็น secondary
- **ระเบียบ สธ. 2563 ข้อ 7**: กรอบบัญชียาร่วมจังหวัด (สสจ. จัดทำ)
  → Drug formulary ต้องรองรับ provincial shared list
- **แบบฟอร์มแผนจัดซื้อ**: ใช้ GPU code + ED/NED classification เป็นคอลัมน์หลัก
  → DrugItem ต้องมี gpuCode, edNedType, venClass
- **DMSIC ราคาอ้างอิง**: ทุกรายการยาต้อง link กับราคาอ้างอิง DMSIC ได้
  → ดูรายละเอียดที่ `regulatory-framework.md` section 6

## Table of Contents
1. [Drug Hierarchy (TMT)](#drug-hierarchy)
2. [Drug Classification](#drug-classification)
3. [Unit Conversion System](#unit-conversion)
4. [Drug Attributes](#drug-attributes)
5. [Data Migration from iHospital G2](#migration)

---

## Drug Hierarchy (TMT) {#drug-hierarchy}

Thai Medicines Terminology (TMT) กำหนดลำดับชั้นของยา 6 ระดับ:

```
GP   (Generic Product)        = ตัวยาสามัญ เช่น "Paracetamol 500mg tablet"
GPU  (Generic Product Use)    = GP + วิธีใช้ เช่น "Paracetamol 500mg oral"
TP   (Trade Product)          = ยี่ห้อ เช่น "Sara 500mg tablet"
TPU  (Trade Product Use)      = TP + วิธีใช้
TPUU (Trade Product Unit Use) = TPU + หน่วยนับ เช่น "Sara 500mg tablet, 1 tablet"
```

### Mapping Pattern ใน AegisX

```typescript
// Drug hierarchy models
model GenericProduct {
  id          String   @id @default(cuid())
  gpCode      String   @unique  // TMT GP code (24 digits)
  name        String             // ชื่อสามัญ
  nameEn      String?
  strength    String?            // เช่น "500 mg"
  dosageForm  String?            // เช่น "tablet", "injection"
  gpuItems    GenericProductUse[]
  hospitalId  String
}

model GenericProductUse {
  id          String   @id @default(cuid())
  gpuCode     String   @unique
  gpId        String
  gp          GenericProduct @relation(fields: [gpId], references: [id])
  routeOfAdmin String?          // oral, injection, topical
  tradeProducts TradeProduct[]
  hospitalId  String
}

model TradeProduct {
  id          String   @id @default(cuid())
  tpCode      String?           // TMT TP code
  tradeName   String             // ชื่อการค้า
  gpuId       String
  gpu         GenericProductUse @relation(fields: [gpuId], references: [id])
  manufacturer String?
  distributor String?
  tpuItems    TradeProductUse[]
  hospitalId  String
}

model TradeProductUse {
  id          String   @id @default(cuid())
  tpuCode     String?
  tpId        String
  tp          TradeProduct @relation(fields: [tpId], references: [id])
  tpuuItems   TradeProductUnitUse[]
  hospitalId  String
}

model TradeProductUnitUse {
  id          String   @id @default(cuid())
  tpuuCode    String?          // TMT TPUU code
  tpuId       String
  tpu         TradeProductUse @relation(fields: [tpuId], references: [id])
  unitId      String           // base dispensing unit
  unit        DrugUnit @relation(fields: [unitId], references: [id])
  hospitalId  String
}
```

### Smart Search Pattern

ค้นหายาต้อง search ได้ทั้งชื่อสามัญและชื่อการค้า:

```typescript
// Backend: Fastify route
fastify.get('/api/v1/drugs/search', async (req) => {
  const { q, limit = 20 } = req.query;
  return prisma.tradeProduct.findMany({
    where: {
      hospitalId: req.hospitalId,
      OR: [
        { tradeName: { contains: q, mode: 'insensitive' } },
        { gpu: { gp: { name: { contains: q, mode: 'insensitive' } } } },
        { tpCode: { startsWith: q } },
      ],
    },
    include: {
      gpu: { include: { gp: true } },
      tpuItems: { include: { tpuuItems: { include: { unit: true } } } },
    },
    take: limit,
  });
});
```

---

## Drug Classification {#drug-classification}

### VEN Classification
จัดกลุ่มยาตามความจำเป็น — ใช้ในการวางแผนงบประมาณ:

| Code | Name | คำอธิบาย |
|------|------|----------|
| V | Vital | ยาช่วยชีวิต ขาดไม่ได้ |
| E | Essential | ยาจำเป็น ใช้บ่อย |
| N | Non-essential | ยาไม่จำเป็นมาก ทดแทนได้ |

### NED (National Essential Drug List)
บัญชียาหลักแห่งชาติ — กำหนดสิทธิเบิกได้:

| บัญชี | คำอธิบาย |
|--------|----------|
| ก (NED-A) | บัญชียาหลัก สั่งใช้ได้ทุกกรณี |
| ข (NED-B) | มีเงื่อนไขการสั่งใช้ |
| ค (NED-C) | ใช้เฉพาะผู้เชี่ยวชาญ |
| ง (NED-D) | ยาสำหรับโครงการพิเศษ |
| จ (NED-E) | ยาสมุนไพร |
| นอกบัญชี | ผู้ป่วยอาจต้องจ่ายเอง |

### HAD (High Alert Drug)
ยาที่ต้องระวังสูง — ต้องมี safety check พิเศษ:

```typescript
enum HighAlertCategory {
  LASA     = 'LASA',     // Look-Alike Sound-Alike
  HIGH_RISK = 'HIGH_RISK', // ยาเสี่ยงสูง
  NARROW_TI = 'NARROW_TI', // Narrow Therapeutic Index
  CYTOTOXIC = 'CYTOTOXIC', // ยาเคมีบำบัด
}
```

---

## Unit Conversion System {#unit-conversion}

### Unit Hierarchy

```
Package Unit (หน่วยสั่งซื้อ/บรรจุภัณฑ์)
  └── Trade Unit (หน่วยเบิก/จ่ายระหว่างคลัง)
      └── Base Unit (หน่วยจ่ายให้คนไข้ — smallest unit)

ตัวอย่าง: Paracetamol 500mg
  1 กล่อง (Box) = 10 แผง (Strip) = 100 เม็ด (Tablet)
  Package: กล่อง (ratioToBase = 100)
  Trade: แผง (ratioToBase = 10)
  Base: เม็ด (ratioToBase = 1)
```

### Prisma Model

```typescript
model DrugUnit {
  id       String @id @default(cuid())
  name     String    // เช่น "เม็ด", "แผง", "กล่อง", "ขวด"
  nameEn   String?   // "tablet", "strip", "box", "bottle"
  abbr     String?   // "tab", "str", "box", "bot"
}

model DrugUnitConversion {
  id          String @id @default(cuid())
  drugId      String         // อ้างอิง TradeProduct
  fromUnitId  String
  fromUnit    DrugUnit @relation("FromUnit", fields: [fromUnitId], references: [id])
  toBaseUnitId String
  toBaseUnit  DrugUnit @relation("ToBase", fields: [toBaseUnitId], references: [id])
  ratioToBase Float          // จำนวน base unit ต่อ 1 fromUnit
  unitLevel   UnitLevel      // PACKAGE | TRADE | BASE
  isDefault   Boolean @default(false)
}

enum UnitLevel {
  PACKAGE   // หน่วยสั่งซื้อ
  TRADE     // หน่วยเบิก
  BASE      // หน่วยจ่ายคนไข้ (smallest)
}
```

### Conversion Functions (Backend)

```typescript
// services/drug-unit.service.ts

async function getConversionRatio(drugId: string, fromUnitId: string) {
  const conversion = await prisma.drugUnitConversion.findFirst({
    where: { drugId, fromUnitId },
  });
  if (!conversion) throw new Error(`No conversion found for drug ${drugId}, unit ${fromUnitId}`);
  return conversion;
}

function toBaseUnit(qty: number, ratioToBase: number): number {
  return qty * ratioToBase;
}

function fromBaseUnit(baseQty: number, ratioToBase: number): number {
  return baseQty / ratioToBase;
}

// IMPORTANT: ratioToBase คือ "1 unit นี้ = กี่ base unit"
// เช่น 1 กล่อง = 100 เม็ด → ratioToBase = 100
// แปลง 3 กล่อง → toBaseUnit(3, 100) = 300 เม็ด
// แปลง 300 เม็ด → fromBaseUnit(300, 100) = 3 กล่อง
```

---

## Drug Attributes {#drug-attributes}

### Drug Item (ข้อมูลยาหลัก ระดับโรงพยาบาล)

```typescript
model DrugItem {
  id              String   @id @default(cuid())
  hospitalId      String
  tradeProductId  String
  tradeProduct    TradeProduct @relation(fields: [tradeProductId], references: [id])

  // Classification
  venClass        VenClass?        // V | E | N
  nedList         NedList?         // NED_A | NED_B | NED_C | NED_D | NED_E | NON_NED
  highAlertCat    HighAlertCategory?
  isNarcotic      Boolean @default(false)
  isPsychotropic  Boolean @default(false)
  isAntibiotic    Boolean @default(false)

  // Inventory settings
  minStock        Float?           // จุดสั่งซื้อ (reorder point)
  maxStock        Float?           // stock สูงสุด
  safetyStock     Float?           // safety stock

  // Pricing
  costPrice       Decimal?         // ราคาทุน
  sellingPrice    Decimal?         // ราคาขาย

  // Status
  isActive        Boolean @default(true)
  isFormulary     Boolean @default(true)  // อยู่ใน formulary รพ.

  // Authorization
  authLocks       DrugAuthLock[]   // ข้อจำกัดการสั่ง

  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  @@unique([hospitalId, tradeProductId])
}
```

### Drug Authorization Lock

ระบบ lock การสั่งยา — แพทย์/กลุ่มที่ได้รับอนุญาตเท่านั้นที่สั่งได้:

```typescript
model DrugAuthLock {
  id          String   @id @default(cuid())
  drugItemId  String
  drugItem    DrugItem @relation(fields: [drugItemId], references: [id])
  lockType    AuthLockType  // DOCTOR | DEPARTMENT | SPECIALTY
  lockValue   String        // doctor_id | dept_id | specialty_code
  isActive    Boolean @default(true)
  hospitalId  String
}

// Cascade logic:
// 1. ตรวจ DOCTOR lock → ถ้า match ผ่าน
// 2. ตรวจ SPECIALTY lock → ถ้าแพทย์มี specialty ตรง ผ่าน
// 3. ตรวจ DEPARTMENT lock → ถ้าอยู่แผนกตรง ผ่าน
// 4. ถ้าไม่มี lock เลย → ทุกคนสั่งได้
```

---

## Data Migration from iHospital G2 {#migration}

### Migration Strategy

```
iHospital G2 Tables → Transform → AegisX Prisma Models

drugitems        → DrugItem + TradeProduct + GP/GPU mapping
drugitems_unit   → DrugUnitConversion
drugitems_lot    → DrugLot
drugstock        → StockJournal (initial balance)
```

### Key Mapping Rules

1. `drugitems.drugname` → ใช้ fuzzy match กับ TMT database เพื่อสร้าง GP/GPU/TP mapping
2. `drugitems.unitprice` → `DrugItem.costPrice`
3. `drugitems.unit` → ต้อง normalize เป็น `DrugUnit` (เช่น "tab" → "เม็ด", "bot" → "ขวด")
4. `drugitems.min_stock` / `drugitems.max_stock` → `DrugItem.minStock` / `DrugItem.maxStock`
5. LOT data: ต้อง validate `expiryDate` — ถ้าหมดอายุแล้วไม่ migrate stock

### Migration Script Pattern

```typescript
// scripts/migrate-drug-master.ts
async function migrateDrugMaster(ihospitalDb: PrismaClient, aegisxDb: PrismaClient) {
  const drugs = await ihospitalDb.$queryRaw`
    SELECT * FROM drugitems WHERE active = 'Y'
  `;

  for (const drug of drugs) {
    // 1. Find or create GP
    const gp = await findOrCreateGP(drug.generic_name, drug.strength, drug.dosage_form);

    // 2. Find or create GPU
    const gpu = await findOrCreateGPU(gp.id, drug.route);

    // 3. Create TradeProduct
    const tp = await aegisxDb.tradeProduct.create({
      data: {
        tradeName: drug.drugname,
        gpuId: gpu.id,
        manufacturer: drug.manufacturer,
        hospitalId: HOSPITAL_ID,
      },
    });

    // 4. Create unit conversions
    await createUnitConversions(tp.id, drug);

    // 5. Create DrugItem
    await aegisxDb.drugItem.create({
      data: {
        hospitalId: HOSPITAL_ID,
        tradeProductId: tp.id,
        venClass: mapVenClass(drug.ven),
        nedList: mapNedList(drug.ned),
        costPrice: drug.unitprice,
        minStock: drug.min_stock,
        maxStock: drug.max_stock,
      },
    });
  }
}
```
