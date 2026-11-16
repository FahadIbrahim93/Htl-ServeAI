/** The browser never renders provider-supplied error.message text.
 * Use stable error codes and deny-by-default generic messages instead.
 */
export type AuthMode = 'signin' | 'signup';

function providerCode(error: unknown): string | null {
  if (error === null || typeof error !== 'object') return null;
  const code = (error as { code?: unknown }).code;
  return typeof code === 'string' ? code : null;
}

export function authErrorMessage(error: unknown, mode: AuthMode): string {
  switch (providerCode(error)) {
    case 'invalid_credentials':
      return 'Email or password is incorrect. Please try again.';
    case 'email_not_confirmed':
      return 'Please confirm your email address before signing in.';
    case 'weak_password':
      return 'Please choose a stronger password.';
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
    case 'over_sms_send_rate_limit':
      return 'Too many attempts. Please try again later.';
    case 'signup_disabled':
      return 'New account registration is currently unavailable.';
    case 'user_already_exists':
    case 'email_exists':
      // Avoid echoing provider messages or asserting account existence.
      return 'Unable to create an account with those details. Try signing in or check your email.';
    default:
      return mode === 'signin'
        ? 'Could not sign you in. Please try again.'
        : 'Could not create your account. Please try again.';
  }
}

export function callbackErrorMessage(errorCode: string | null): string | null {
  return errorCode === 'callback'
    ? 'The sign-in link could not be verified. Please try signing in again.'
    : null;
}
