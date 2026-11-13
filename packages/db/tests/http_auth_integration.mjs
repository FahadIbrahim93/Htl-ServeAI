// Run against disposable local Supabase only. No privileged service keys used.
// Validates Auth password JWTs, PostgREST RLS, and restricted restaurant bootstrap.
import {randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';

const base=process.env.SUPABASE_API_URL??'http://127.0.0.1:54321';
const anonKey=process.env.SUPABASE_ANON_KEY;
if(!anonKey)throw new Error('Missing disposable local Supabase anon key');

async function request(path,{method='GET',token,body}={}){
  const response=await fetch(new URL(path,base),{
    method,
    headers:{
      apikey:anonKey,
      ...(token?{Authorization:`Bearer ${token}`}:{}),
      ...(body!==undefined?{'Content-Type':'application/json'}:{})
    },
    ...(body!==undefined?{body:JSON.stringify(body)}:{})
  });
  const raw=await response.text();
  let parsed;
  try{parsed=JSON.parse(raw)}catch{parsed=raw}
  return {status:response.status,ok:response.ok,data:parsed};
}

async function register(label){
  const email=`serveai-${label}-${randomUUID()}@test.invalid`;
  const password=`SecureLocalTest-${randomUUID()}!`;
  const signup=await request('/auth/v1/signup',{
    method:'POST',body:{email,password}
  });
  assert(signup.ok,`Local Supabase sign-up for ${label} returned ${signup.status}`);
  let token=signup.data?.access_token;
  if(!token){
    const login=await request('/auth/v1/token?grant_type=password',{
      method:'POST',body:{email,password}
    });
    assert(login.ok,`Local Supabase login for ${label} returned ${login.status}`);
    token=login.data?.access_token;
  }
  assert(typeof token==='string'&&token.length>50,'A signed-in session JWT is required');
  return token;
}

const a=await register('a');
const b=await register('b');
const slugA=`tenant-a-${randomUUID().slice(0,8)}`;
const slugB=`tenant-b-${randomUUID().slice(0,8)}`;

async function createRestaurant(token,slug){
  return request('/rest/v1/rpc/create_restaurant',{
    method:'POST',token,
    body:{p_name:'ServeAI Test Restaurant',p_slug:slug,p_branch_name:'Main Branch'}
  });
}

const newA=await createRestaurant(a,slugA);
assert(newA.ok,`Tenant A onboarding failed HTTP ${newA.status}`);
const newB=await createRestaurant(b,slugB);
assert(newB.ok,`Tenant B onboarding failed HTTP ${newB.status}`);

const ownA=await request('/rest/v1/tenants?select=id,slug',{token:a});
const ownB=await request('/rest/v1/tenants?select=id,slug',{token:b});
assert(ownA.ok&&ownB.ok,'Authenticated members must be able to read their tenant');
assert.deepEqual(ownA.data.map(x=>x.slug),[slugA],'Tenant A must see only itself');
assert.deepEqual(ownB.data.map(x=>x.slug),[slugB],'Tenant B must see only itself');

const membersA=await request('/rest/v1/memberships?select=role,tenant_id',{token:a});
assert(membersA.ok&&membersA.data.length===1&&membersA.data[0].role==='owner','Owner membership must be self-scoped');

const retry=await createRestaurant(a,slugA);
assert(!retry.ok,'Duplicate restaurant slug should be rejected');

const throttled=await createRestaurant(a,`tenant-a-retry-${randomUUID().slice(0,8)}`);
assert(!throttled.ok,'A second restaurant within 60 seconds must be blocked');

const anonymousRead=await request('/rest/v1/tenants?select=id');
assert(!anonymousRead.ok,'Anonymous Data API table read must be denied');

const unauthorizedInsert=await request('/rest/v1/tenants',{method:'POST',token:a,body:{name:'Attack',slug:'unauthorized'}});
assert(!unauthorizedInsert.ok,'Authenticated browser role must not insert tenants directly');

const internalOutbox=await request('/rest/v1/outbox_events?select=id',{token:a});
assert(!internalOutbox.ok,'Outbox must not be readable to browser clients');

const invalidJWT=await request('/rest/v1/tenants?select=id',{token:'invalid.jwt.signature'});
assert(!invalidJWT.ok,'Invalid JWT must be rejected');

console.log('Supabase HTTP Auth/JWT/PostgREST tenant isolation checks passed');
