import {describe,expect,it} from 'vitest';
import {authErrorMessage,callbackErrorMessage} from '../src/lib/auth-errors';

describe('safe authentication error messages',()=>{
  it('normalizes incorrect password without echoing provider details',()=>{
    expect(authErrorMessage({code:'invalid_credentials',message:'secret internal trace'},'signin'))
      .toBe('Email or password is incorrect. Please try again.');
  });
  it('prompts users to confirm email',()=>{
    expect(authErrorMessage({code:'email_not_confirmed'},'signin'))
      .toContain('confirm your email');
  });
  it('uses a generic message for account existence',()=>{
    const message=authErrorMessage({code:'user_already_exists'},'signup');
    expect(message).not.toMatch(/already exists/i);
    expect(message).toContain('Try signing in');
  });
  it('handles weak passwords',()=>{
    expect(authErrorMessage({code:'weak_password'},'signup')).toContain('stronger password');
  });
  it('handles all rate limiting signals',()=>{
    for(const code of ['over_request_rate_limit','over_email_send_rate_limit','over_sms_send_rate_limit']){
      expect(authErrorMessage({code},'signin')).toContain('Too many attempts');
    }
  });
  it('does not expose unknown provider-supplied messages',()=>{
    const secret='DATABASE_CONNECTION_STRING_PRIVATE';
    const message=authErrorMessage({code:'unexpected_new_code',message:secret},'signin');
    expect(message).not.toContain(secret);
    expect(message).toBe('Could not sign you in. Please try again.');
  });
  it('handles string and null errors without echoing',()=>{
    expect(authErrorMessage('secret stack trace','signup'))
      .toBe('Could not create your account. Please try again.');
    expect(authErrorMessage(null,'signin'))
      .toBe('Could not sign you in. Please try again.');
  });
  it('shows a friendly callback message only for expected callback error',()=>{
    expect(callbackErrorMessage('callback')).toContain('sign-in link');
    expect(callbackErrorMessage('anything_else')).toBeNull();
    expect(callbackErrorMessage(null)).toBeNull();
  });
});
