'use client';

import {useState,type FormEvent} from 'react';
import {createClient} from '@/lib/supabase/browser';

export function AuthForm(){
  const [email,setEmail]=useState('');
  const [password,setPassword]=useState('');
  const [mode,setMode]=useState<'signin'|'signup'>('signin');
  const [message,setMessage]=useState('');
  const [busy,setBusy]=useState(false);
  async function submit(event:FormEvent<HTMLFormElement>){
    event.preventDefault();
    if(busy)return;
    setBusy(true);setMessage('');
    try{
      const client=createClient();
      if(mode==='signin'){
        const {error}=await client.auth.signInWithPassword({email,password});
        if(error)throw error;
        window.location.assign('/dashboard');
      }else{
        const {data,error}=await client.auth.signUp({
          email,password,
          options:{emailRedirectTo:new URL('/auth/callback',window.location.origin).toString()}
        });
        if(error)throw error;
        if(data.session) window.location.assign('/dashboard');
        else setMessage('Check your email to confirm your account before signing in.');
      }
    }catch(error){
      setMessage(error instanceof Error?error.message:'Authentication failed');
    }finally{setBusy(false)}
  }
  return <form onSubmit={submit}>
    <label>Email address<input required type="email" autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)}/></label>
    <label>Password<input required type="password" minLength={8} autoComplete={mode==='signup'?'new-password':'current-password'} value={password} onChange={e=>setPassword(e.target.value)}/></label>
    <button disabled={busy} type="submit">{busy?'Please wait…':mode==='signin'?'Sign in':'Create account'}</button>
    <button type="button" className="outline" disabled={busy} onClick={()=>{setMode(mode==='signin'?'signup':'signin');setMessage('')}}>
      {mode==='signin'?'Need an account? Sign up':'Already registered? Sign in'}
    </button>
    {message&&<p role="status" aria-live="polite">{message}</p>}
  </form>
}
