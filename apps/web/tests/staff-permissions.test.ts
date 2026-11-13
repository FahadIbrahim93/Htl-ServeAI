import {describe,expect,it} from 'vitest';
import {canManageStaff,isStaffRole,STAFF_ROLES} from '../src/lib/staff-permissions';

describe('staff management policy (UI/domain only)', () => {
  it('recognizes only enumerated roles', () => {
    expect(STAFF_ROLES).toHaveLength(5);
    for (const role of STAFF_ROLES) expect(isStaffRole(role)).toBe(true);
    for (const role of ['admin', 'service_role', '', null, 5]) expect(isStaffRole(role)).toBe(false);
  });
  it('allows owners to invite managers and operational staff', () => {
    expect(canManageStaff('owner', 'invite', 'manager')).toBe(true);
    expect(canManageStaff('owner', 'invite', 'kitchen')).toBe(true);
  });
  it('never allows invitations to or mutation of ownership', () => {
    for (const actor of STAFF_ROLES) {
      expect(canManageStaff(actor, 'invite', 'owner')).toBe(false);
      expect(canManageStaff(actor, 'revoke', 'owner')).toBe(false);
      expect(canManageStaff(actor, 'change-role', 'cashier', 'owner')).toBe(false);
    }
  });
  it('restricts manager invitations to operational staff', () => {
    expect(canManageStaff('manager', 'invite', 'waiter')).toBe(true);
    expect(canManageStaff('manager', 'invite', 'manager')).toBe(false);
  });
  it('prevents managers from revoking or promoting managers', () => {
    expect(canManageStaff('manager', 'revoke', 'manager')).toBe(false);
    expect(canManageStaff('manager', 'change-role', 'waiter', 'manager')).toBe(false);
  });
  it('allows managers to change operational staff roles only', () => {
    expect(canManageStaff('manager', 'change-role', 'waiter', 'cashier')).toBe(true);
    expect(canManageStaff('manager', 'revoke', 'kitchen')).toBe(true);
  });
  it('prevents operational staff managing any staff', () => {
    for (const actor of ['waiter','kitchen','cashier'] as const) {
      expect(canManageStaff(actor, 'invite', 'waiter')).toBe(false);
      expect(canManageStaff(actor, 'revoke', 'cashier')).toBe(false);
      expect(canManageStaff(actor, 'change-role', 'kitchen', 'waiter')).toBe(false);
    }
  });
  it('requires an actual role change', () => {
    expect(canManageStaff('owner', 'change-role', 'waiter')).toBe(false);
    expect(canManageStaff('owner', 'change-role', 'waiter', 'waiter')).toBe(false);
  });
});
