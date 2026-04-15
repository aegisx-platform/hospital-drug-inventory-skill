# Common Code Patterns

Implementation patterns ที่ใช้ทั้งระบบ — อ่านเมื่อจะ generate code จริง (Prisma model, Fastify route, Angular component ฯลฯ)

---

## 1. Stock Journal (Append-Only Ledger)

ทุกการเคลื่อนไหวของสต็อก insert journal entry ใหม่ — **ห้าม UPDATE** สต็อกที่มีอยู่

```typescript
interface StockJournal {
  id: string;
  drugId: string;
  warehouseId: string;
  lotId: string;
  movementType: 'RECEIVE' | 'DISPENSE' | 'TRANSFER' | 'ADJUST' | 'RETURN';
  direction: 'IN' | 'OUT';
  quantity: number;        // base unit เสมอ
  baseUnitId: string;
  referenceType: string;   // PO | REQUISITION | PRESCRIPTION | ADJUSTMENT
  referenceId: string;
  hospitalId: string;
  createdBy: string;
  createdAt: DateTime;
}
```

ยอดคงเหลือ = `SUM(quantity * direction)` group by `drugId, lotId, warehouseId` — อาจ materialize ใน view/cache สำหรับ hot reads

---

## 2. Unit Conversion

```
Package Unit → Trade Unit → Base Unit
1 กล่อง = 10 แผง = 100 เม็ด
```

เก็บใน base unit เสมอ แปลงเฉพาะตอนแสดงผล/input

---

## 3. Separation of Duties (RBAC — ระเบียบ สธ. 2563 ข้อ 11)

```typescript
enum DrugRole { PURCHASER, WAREHOUSE_KEEPER, INSPECTOR, APPROVER, PHARMACIST }

// validation: user มี role PURCHASER + WAREHOUSE_KEEPER พร้อมกันไม่ได้
const FORBIDDEN_COMBOS = [[DrugRole.PURCHASER, DrugRole.WAREHOUSE_KEEPER]];
```

---

## 4. Min/Max Stock Calculation

```
Min stock = ปริมาณใช้ต่อปี ÷ 12
Max stock = Min × 1.5
คงคลังไม่เกิน 2 เดือน
```

---

## 5. FEFO Lot Selection

```typescript
// First-Expired-First-Out
prisma.lot.findMany({
  where: { drugId, warehouseId, qtyRemaining: { gt: 0 } },
  orderBy: { expiryDate: 'asc' },
});
```

---

## 6. Multi-Site Isolation

ทุก query ต้องมี `hospitalId` — ใช้ Prisma middleware บังคับ

```typescript
prisma.$use(async (params, next) => {
  if (params.action.startsWith('find') || params.action === 'count') {
    params.args.where = { ...params.args.where, hospitalId: ctx.hospitalId };
  }
  return next(params);
});
```

---

## Anti-Patterns

1. ❌ อย่า UPDATE stock — ใช้ append-only journal
2. ❌ อย่าลืม `hospitalId` ใน query
3. ❌ อย่าเก็บ stock ใน dispensing unit — ใช้ base unit
4. ❌ อย่ารวมผู้จัดซื้อกับผู้คลัง (ข้อ 11)
5. ❌ อย่ามี discount/rebate fields — ราคาสุทธิเท่านั้น (เกณฑ์จริยธรรม ข้อ 15(2))
6. ❌ อย่าแสดง trade name ก่อน generic — generic primary (ข้อ 13)
7. ❌ อย่าลืม DMSIC reference price check — alert เมื่อซื้อแพงกว่า
8. ❌ อย่าลืมรายงานไตรมาส — แผน vs จริง ตามแบบฟอร์ม สธ.
