// Goods Receiving (GR) against a PO — see references/warehouse-receiving.md
// Enforces: separation of duties, multi-site isolation, append-only journal.

import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

const GrLineSchema = z.object({
  poLineId: z.string(),
  lotNo: z.string(),
  expiryDate: z.coerce.date(),
  quantityBase: z.number().positive(),
});

const GrSchema = z.object({
  poId: z.string(),
  receivedAt: z.coerce.date(),
  lines: z.array(GrLineSchema).min(1),
});

export async function goodsReceivingRoutes(app: FastifyInstance) {
  app.post('/drug/gr', async (req, reply) => {
    const { hospitalId, userId, roles } = req.user; // from auth plugin

    // Separation of Duties — ระเบียบ สธ. 2563 ข้อ 11
    if (roles.includes('PURCHASER')) {
      return reply.code(403).send({ error: 'PURCHASER cannot perform GR' });
    }
    if (!roles.includes('WAREHOUSE_KEEPER')) {
      return reply.code(403).send({ error: 'WAREHOUSE_KEEPER role required' });
    }

    const body = GrSchema.parse(req.body);

    return app.prisma.$transaction(async (tx) => {
      const po = await tx.purchaseOrder.findFirstOrThrow({
        where: { id: body.poId, hospitalId },
        include: { lines: true },
      });

      for (const line of body.lines) {
        const poLine = po.lines.find((l) => l.id === line.poLineId);
        if (!poLine) throw new Error(`PO line not found: ${line.poLineId}`);

        const lot = await tx.lot.create({
          data: {
            hospitalId,
            drugId: poLine.drugId,
            lotNo: line.lotNo,
            expiryDate: line.expiryDate,
            warehouseId: po.warehouseId,
            qtyReceived: line.quantityBase,
          },
        });

        await tx.stockJournal.create({
          data: {
            hospitalId,
            drugId: poLine.drugId,
            warehouseId: po.warehouseId,
            lotId: lot.id,
            movementType: 'RECEIVE',
            direction: 'IN',
            quantity: line.quantityBase,
            baseUnitId: poLine.baseUnitId,
            referenceType: 'PO',
            referenceId: po.id,
            createdBy: userId,
          },
        });
      }

      return { ok: true, poId: po.id };
    });
  });
}
