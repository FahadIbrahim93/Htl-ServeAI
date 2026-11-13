import {type NextRequest} from 'next/server';
import {updateSession} from '@/lib/supabase/proxy';

export async function middleware(request:NextRequest) {
  return updateSession(request);
}

// Keep the standalone guest UX prototype usable without Supabase env variables.
export const config={matcher:['/dashboard/:path*','/onboarding/:path*','/auth/callback']};
