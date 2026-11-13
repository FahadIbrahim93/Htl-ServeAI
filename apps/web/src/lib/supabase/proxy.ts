import {createServerClient} from '@supabase/ssr';
import {NextResponse,type NextRequest} from 'next/server';
import {supabasePublicEnv} from './env';

export async function updateSession(request:NextRequest) {
  const {url,publishableKey}=supabasePublicEnv();
  let response=NextResponse.next({request});
  const supabase=createServerClient(url,publishableKey,{
    cookies:{
      getAll() {return request.cookies.getAll();},
      setAll(toSet) {
        for (const {name,value} of toSet) request.cookies.set(name,value);
        response=NextResponse.next({request});
        for (const {name,value,options} of toSet) response.cookies.set(name,value,options);
      }
    }
  });
  // A trusted Auth server check also refreshes cookie sessions when necessary.
  await supabase.auth.getUser();
  return response;
}
