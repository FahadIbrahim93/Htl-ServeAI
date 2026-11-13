# Guest ordering UX — executable contract

1. QR token resolves to active restaurant, branch, table and signed guest session; invalid/revoked QR displays help and staff contact, never leaks tenant data.
2. Menu lists only available items with images, descriptions, allergens and modifier rules. Guest may switch Bangla/English without losing cart.
3. AI only searches tenant-scoped menu data; it cannot authorize an order or change pricing. User can always switch to manual cart or request human staff.
4. Cart is repriced by the server on every checkout, applying tenant-configured inclusive/exclusive VAT rules, service charges, discounts and rounding policy. Show line-item subtotal, discount, service, VAT, total, and what is payable now.
5. Before submitting, display an explicit confirmation button, table, item list, modifiers and final amount. If stock/price changes, return a new quote and require reconfirmation.
6. POST /orders uses an idempotency key; transactional write persists order, line snapshots and outbox event atomically. Return stable order reference.
7. Kitchen ticket is delivered from outbox; polling/realtime reconnect reconciles against server state. No AI-generated order can skip staff-facing event.
8. Guest tracks confirmed/preparing/ready/served status. Staff-only actions change status with version checks.
9. Human handoff creates a service_request with reason, table, priority, status, assignee and acknowledgment time. Duplicate calls are coalesced; unresolved requests escalate.
10. Payment and bill settlement remain separate from order status; only verified cashiers or payment callbacks can mark paid.

## Sample Bangla conversation
AI: আসসালামু আলাইকুম! আজ কী খেতে চান? আপনার বাজেট অনুযায়ী সাজেস্ট করতে পারি।
Guest: ৬০০ টাকার মধ্যে দুইজনের জন্য ভালো কিছু সাজেস্ট করো।
AI: ২টি চিকেন বিরিয়ানি (৳৪৪০) এবং ২টি বোরহানি (৳১২০) — খাবারের সাবটোটাল ৳৫৬০। সার্ভিস চার্জ ও ভ্যাট চেকআউটে দেখা যাবে। কার্টে যোগ করব?
Guest: হ্যাঁ।
AI: কার্টে যোগ করেছি। অর্ডার নিশ্চিত করার আগে সব আইটেম ও মোট মূল্য দেখে নিন।

## Failure cases
Expired QR; unavailable item; modifier incompatibility; stale quote; duplicate submission; kitchen offline; network retry; guest reconnect; AI timeout; prompt injection; allergy uncertainty; staff request unacknowledged; partial refund; payment callback replay.
