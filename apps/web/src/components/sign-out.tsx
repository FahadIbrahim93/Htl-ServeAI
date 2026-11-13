'use client';
import {useState} from 'react';
import {createClient} from '@/lib/supabase/browser';

export function SignOut(){
  const [busy,setBusy]=useState(false);
  return <button type="button" className="outline" disabled={busy} onClick={async()=>{
    setBusy(true);
    try{await createClient().auth.signOut();window.location.assign('/login');}
    catch{setBusy(false)}
  }}>{busy?'Signing out…':'Sign out'}</button>;
}
