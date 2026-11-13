/**
 * UI/domain policy for proposed ServeAI staff administration (Issue #4).
 *
 * IMPORTANT: This is NOT an authorization boundary. API handlers must derive
 * actor identity and membership from verified Supabase Auth and enforce all
 * permissions again in a database transaction. Never trust role values supplied
 * by the browser; database RLS and carefully scoped RPCs are authoritative.
 */
export const STAFF_ROLES = ['owner', 'manager', 'waiter', 'kitchen', 'cashier'] as const;
export type StaffRole = (typeof STAFF_ROLES)[number];
export type StaffAction = 'invite' | 'revoke' | 'change-role';

/** Owners control managers; managers may manage operational staff only. */
export function canManageStaff(
  actorRole: StaffRole,
  action: StaffAction,
  targetRole: StaffRole,
  nextRole?: StaffRole,
): boolean {
  if (targetRole === 'owner' || nextRole === 'owner') return false;
  if (action === 'change-role' && (!nextRole || nextRole === targetRole)) return false;

  if (actorRole === 'owner') return true;
  if (actorRole !== 'manager') return false;

  const operational: readonly StaffRole[] = ['waiter', 'kitchen', 'cashier'];
  if (!operational.includes(targetRole)) return false;
  if (action === 'change-role' && !operational.includes(nextRole!)) return false;
  return true;
}

/** Pure input guard. API must additionally validate membership and branch scope. */
export function isStaffRole(value: unknown): value is StaffRole {
  return typeof value === 'string' && (STAFF_ROLES as readonly string[]).includes(value);
}
