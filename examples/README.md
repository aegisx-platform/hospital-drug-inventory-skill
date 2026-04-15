# Examples

Minimal, copy-ready code snippets that demonstrate the patterns from `references/patterns.md`.
**Not** standalone — adapt naming, auth, and tenant context to your project.

| File | Demonstrates |
|------|-------------|
| `prisma-stock-journal.prisma` | Append-only ledger model (patterns §1) |
| `fastify-goods-receiving.ts` | GR route with separation-of-duties + journal write |
| `angular-dispense-form.component.ts` | Generic-primary dispensing UI with FEFO lookup |
