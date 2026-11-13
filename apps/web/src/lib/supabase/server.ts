import {createServerClient} from '@supabase/ssr';
import {cookies} from 'next/headers';
import {supabasePublicEnv} from './env';

export async function createClient() {
  const cookieStore=await cookies();
  const {url,publishableKey}=supabasePublicEnv();
  return createServerClient(url,publishableKey,{
    cookies:{
      getAll() {return cookieStore.getAll();},
      setAll(toSet) {
        try {
          for (const {name,value,options} of toSet) cookieStore.set(name,value,options);
        } catch {
          // Server Components cannot write cookies. Middleware handles refresh.
        }
      }
    }
  });
}
