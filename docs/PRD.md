# Product Requirements — HTL ServeAI

**Owner:** Hope Theory Labs  
**Status:** Draft specification, not shipped  
**Market:** Bangladesh; Bangla and English

## Problem

Restaurants lose time and accuracy in menu discovery, ordering, kitchen handoff, billing, and reporting. ServeAI aims to provide browser-based table ordering without requiring guests to install an app.

## Users

Guest, waiter, kitchen staff, cashier, manager, owner, and platform administrator.

## Product scope

1. **Tenancy:** independent restaurants and branches, membership and role-based permissions.
2. **QR experience:** table-specific opaque revocable links, guest menu browsing, item variants and modifiers.
3. **Orders:** cart, confirmation, server-calculated prices/tax, idempotent submission and status tracking.
4. **Kitchen:** reliable order tickets, accept/preparing/ready statuses, reconnect recovery.
5. **Staff:** table service requests, waiter notifications, cashier reconciliation.
6. **Finance:** immutable order snapshots, receipts, recorded payments, refund/audit trails.
7. **AI waiter:** Bangla/English menu-grounded suggestions, budget assistance, draft orders and human handoff.
8. **Owner:** menu editing, staff access, branch analytics, subscriptions.

## First release

Multi-tenant foundation with one branch per restaurant, QR ordering, kitchen workflow, cash/manual payment recording, and controlled AI waiter. Online payment gateway and advanced inventory are later phases.

## Non-negotiable acceptance criteria

- Cross-tenant read/write attempts fail.
- AI cannot invent products/prices or place an order without explicit guest confirmation.
- Backend recomputes all amounts from authoritative menu/tax data.
- Duplicate order requests do not create duplicate orders.
- Unavailable items and invalid modifiers are rejected.
- Kitchen receives durable tickets; reconnecting clients recover state.
- Errors are observable; manual fallback is documented.

## Non-goals

No custom model training, no full accounting suite, no nationwide delivery marketplace in the first release.
