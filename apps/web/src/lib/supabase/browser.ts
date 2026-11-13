import {createBrowserClient} from '@supabase/ssr';
import {supabasePublicEnv} from './env';
let cached:ReturnType<typeof createBrowserClient>|undefined;
export function createClient() {
  if (!cached) {
    const {url,publishableKey}=supabasePublicEnv();
    cached=createBrowserClient(url,publishableKey);
  }
  return cached;
}
