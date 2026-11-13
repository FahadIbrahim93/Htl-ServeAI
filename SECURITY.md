# Security Policy

ServeAI is pre-production. Do not use it for live orders, payments, or customer records until launch gates are met.

## Reporting

Do not open public issues with vulnerabilities, secrets, access tokens, exploit details, or personal data. Contact the repository owner privately through GitHub, or use GitHub private vulnerability reporting if enabled.

## Security baseline

- Tenant-scoped PostgreSQL RLS and composite foreign keys
- Least-privilege authorization and staff roles
- No privileged keys in browsers or public build output
- Explicit validation and idempotency for transactional operations
- Audit trails for financial, membership and order state changes
- Rate limits, abuse protection and secure session handling
- Reviewed migrations, dependency scanning and restoration drills

## Secret exposure

Immediately revoke/rotate the exposed secret, remove it from current code and history as appropriate, inspect access logs, and document the incident privately. Deleting a file from the latest commit alone does not remove its history.
