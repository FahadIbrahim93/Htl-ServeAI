'use client';

import {useState,type FormEvent} from 'react';
import {createClient} from '@/lib/supabase/browser';
import {validateRestaurantInput} from '@/lib/tenant-validation';

export function OnboardingForm(){
  const [name,setName]=useState('');
  const [slug,setSlug]=useState('');
  const [branchName,setBranchName]=useState('Main Branch');
  const [message,setMessage]=useState('');
  const [busy,setBusy]=useState(false);

  async function submit(event:FormEvent<HTMLFormElement>){
    event.preventDefault();
    if(busy)return;
    setBusy(true);setMessage('');
    try{
      const values=validateRestaurantInput({name,slug,branchName});
      const supabase=createClient();
      const {data:{user},error:identityError}=await supabase.auth.getUser();
      if(identityError || !user)throw new Error('Please sign in before creating a restaurant.');
      const {error}=await supabase.rpc('create_restaurant',{
        p_name:values.name,p_slug:values.slug,p_branch_name:values.branchName
      });
      if(error){
        if(error.code==='23505')throw new Error('This restaurant URL slug is already in use.');
        if(error.code==='28000')throw new Error('Please confirm your account and sign in again.');
        throw new Error('Could not create the restaurant. Please check your details and retry.');
      }
      window.location.assign('/dashboard');
    }catch(error){
      setMessage(error instanceof Error?error.message:'Could not create the restaurant.');
    }finally{setBusy(false)}
  }

  return <form onSubmit={submit}>
    <label>Restaurant name<input required minLength={2} maxLength={120} value={name} onChange={e=>setName(e.target.value)}/></label>
    <label>URL slug<input required minLength={3} maxLength={50} placeholder="my-restaurant" value={slug} onChange={e=>setSlug(e.target.value.toLowerCase())}/></label>
    <label>First branch<input required minLength={2} maxLength={120} value={branchName} onChange={e=>setBranchName(e.target.value)}/></label>
    <button type="submit" disabled={busy}>{busy?'Creating…':'Create restaurant'}</button>
    {message&&<p role="alert">{message}</p>}
    <p className="note">Your restaurant starts in trial mode. Staff invitations and live orders are not yet available.</p>
  </form>
}
