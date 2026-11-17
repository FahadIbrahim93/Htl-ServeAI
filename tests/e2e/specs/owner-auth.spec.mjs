import {test,expect} from '@playwright/test';
import {randomUUID} from 'node:crypto';
import {execFileSync} from 'node:child_process';

const api=process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const password='ServeAI-Test-2026!';

function identity(){
  return {email:`serveai-e2e-${randomUUID()}@example.test`,password};
}

async function browserSessionToken(context) {
  // Supabase SSR persists signed-in sessions in one or more sb-*-auth-token
  // browser cookies. Use the *browser's* session, not a separately minted JWT.
  const chunks=(await context.cookies()).filter(c=>
    /-auth-token(?:\.\d+)?$/.test(c.name)
  ).sort((a,b)=>{
    const index=name=>Number(name.match(/\.(\d+)$/)?.[1]??0);
    return index(a.name)-index(b.name);
  });
  if(!chunks.length)throw new Error('Browser session cookie not found');
  const payload=chunks.map(c=>c.value).join('');
  const decoded=payload.startsWith('base64-')
    ? Buffer.from(payload.slice(7),'base64url').toString('utf8')
    : payload;
  const parsed=JSON.parse(decoded);
  if(typeof parsed.access_token!=='string')throw new Error('Session JWT absent');
  return parsed.access_token;
}

async function signupViaBrowser(page,account){
  await page.goto('/login');
  await page.getByRole('button',{name:'Need an account? Sign up'}).click();
  await page.getByLabel('Email address').fill(account.email);
  await page.getByLabel('Password').fill(account.password);
  await page.getByRole('button',{name:'Create account'}).click();
  await expect(page).toHaveURL(/\/dashboard$/, {timeout:30_000});
  await expect(page.getByText(account.email)).toBeVisible();
  // Returns a JWT derived from the actual browser cookie, without logging it.
  return browserSessionToken(page.context());
}

async function signupViaLocalAuth(request,account){
  const response=await request.post(`${api}/auth/v1/signup`,{
    headers:{apikey:anonKey,'Content-Type':'application/json'},
    data:account
  });
  expect(response.ok(),`Local Auth signup failed: ${response.status()}`).toBeTruthy();
}

async function registerRestaurant(page,name,slug){
  await page.goto('/onboarding');
  await page.getByLabel('Restaurant name').fill(name);
  await page.getByLabel('URL slug').fill(slug);
  await page.getByLabel('First branch').fill('Main Branch');
  await page.getByRole('button',{name:'Create restaurant'}).click();
}

test('anonymous visits cannot enter the owner dashboard or onboarding', async({page})=>{
  await page.goto('/dashboard');
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
  await page.goto('/onboarding');
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
});

test('local signup establishes a browser session and empty owner dashboard',async({page})=>{
  const account=identity();
  await signupViaBrowser(page,account);
  await expect(page.getByText('No restaurants linked to your account yet.')).toBeVisible();
});

test('an existing local user can log in with password',async({page,request})=>{
  const account=identity();
  await signupViaLocalAuth(request,account);
  await page.goto('/login');
  await page.getByLabel('Email address').fill(account.email);
  await page.getByLabel('Password').fill(account.password);
  await page.getByRole('button',{name:'Sign in',exact:true}).click();
  await expect(page).toHaveURL(/\/dashboard$/, {timeout:30_000});
  await expect(page.getByText(account.email)).toBeVisible();
});

test('owner can create a tenant and see it on their dashboard',async({page})=>{
  const account=identity();
  const slug=`browser-${randomUUID().slice(0,8)}`;
  await signupViaBrowser(page,account);
  await registerRestaurant(page,'ServeAI Browser Restaurant',slug);
  await expect(page).toHaveURL(/\/dashboard$/, {timeout:30_000});
  await expect(page.getByText('ServeAI Browser Restaurant')).toBeVisible();
  await expect(page.getByText(slug,{exact:false})).toBeVisible();
  await expect(page.getByText('owner',{exact:false})).toBeVisible();
});

test('a second restaurant created immediately is limited per account',async({page})=>{
  const account=identity();
  await signupViaBrowser(page,account);
  await registerRestaurant(page,'First Browser Restaurant',`first-${randomUUID().slice(0,8)}`);
  await expect(page).toHaveURL(/\/dashboard$/, {timeout:30_000});
  await registerRestaurant(page,'Second Browser Restaurant',`second-${randomUUID().slice(0,8)}`);
  await expect(page.locator('form [role="alert"]')).toContainText('Restaurant creation limit reached');
  await expect(page).toHaveURL(/\/onboarding$/);
});

for (const knownAccount of [false,true]) {
test(`rejected credentials show safe feedback for ${knownAccount?'existing':'unknown'} accounts`,async({page,request})=>{
  const account=identity();
  if(knownAccount)await signupViaLocalAuth(request,account);
  await page.goto('/login');
  await page.getByLabel('Email address').fill(account.email);
  await page.getByLabel('Password').fill('DefinitelyWrongPassword!'); 
  await page.getByRole('button',{name:'Sign in',exact:true}).click();
  await expect(page.locator('form [role="status"]')).toHaveText('Email or password is incorrect. Please try again.');
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
  await page.goto('/dashboard');
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
});

}

for (const callback of ['/auth/callback','/auth/callback?code=invalid-code']) {
  test(`callback fails closed with friendly feedback: ${callback}`,async({page})=>{
    await page.goto(callback);
    await expect(page).toHaveURL(/\/login\?error=callback$/);
    await expect(page.locator('form [role="status"]')).toHaveText(
      'The sign-in link could not be verified. Please try signing in again.'
    );
  });
}

test('signing out clears session cookies and denies protected routes',async({page,context})=>{
  await signupViaBrowser(page,identity());
  await page.getByRole('button',{name:/sign out/i}).click();
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
  const remaining=(await context.cookies()).filter(c=>/-auth-token(?:\.\d+)?$/.test(c.name));
  expect(remaining.length,'Sign-out must remove session cookie chunks').toBe(0);
  for(const route of ['/dashboard','/onboarding']){
    await page.goto(route);
    await expect(page).toHaveURL(/\/login(?:\?|$)/);
  }
});

for(const route of ['/dashboard','/onboarding']){
  test(`tampered browser session cannot enter ${route}`,async({page,context,browser})=>{
    await signupViaBrowser(page,identity());
    // Copy the session into a fresh context to avoid the original page's Auth
    // client repairing it through its in-memory token or background refresh.
    const cookies=(await context.cookies()).filter(c=>/-auth-token(?:\.\d+)?$/.test(c.name));
    expect(cookies.length,'A genuine session must exist before tampering').toBeGreaterThan(0);
    const tampered=await browser.newContext();
    try{
      await tampered.addCookies(cookies.map(c=>({...c,value:'invalid-session'})));
      const visitor=await tampered.newPage();
      await visitor.goto(route);
      await expect(visitor).toHaveURL(/\/login(?:\?|$)/);
      await expect(visitor.getByRole('heading',{name:'Restaurant owner sign-in'})).toBeVisible();
    }finally{
      await tampered.close();
    }
  });
}


test('a duplicate restaurant slug is rejected across two browser accounts',async({page,browser})=>{
  const slug=`duplicate-${randomUUID().slice(0,8)}`;
  await signupViaBrowser(page,identity());
  await registerRestaurant(page,'Original Restaurant',slug);
  await expect(page).toHaveURL(/\/dashboard$/,{timeout:30_000});

  const secondContext=await browser.newContext();
  try{
    const other=await secondContext.newPage();
    await signupViaBrowser(other,identity());
    await registerRestaurant(other,'Different Restaurant',slug);
    await expect(other.locator('form [role="alert"]')).toContainText('slug is already in use');
    await expect(other).toHaveURL(/\/onboarding$/);
  }finally{
    await secondContext.close();
  }
});

test('different owners cannot view each others restaurant using browser JWTs',async({page,browser})=>{
  const slug=`isolation-${randomUUID().slice(0,8)}`;
  await signupViaBrowser(page,identity());
  await registerRestaurant(page,'Restaurant Only For A',slug);
  await expect(page).toHaveURL(/\/dashboard$/,{timeout:30_000});
  await expect(page.getByText('Restaurant Only For A')).toBeVisible();

  const contextB=await browser.newContext();
  try{
    const pageB=await contextB.newPage();
    const browserTokenB=await signupViaBrowser(pageB,identity());
    expect(typeof browserTokenB).toBe('string');
    await expect(pageB.getByText('Restaurant Only For A')).not.toBeVisible();

    const result=await pageB.evaluate(async({api,key,token,slug})=>{
      const url=new URL('/rest/v1/tenants',api);
      url.searchParams.set('select','id,slug');
      url.searchParams.set('slug',`eq.${slug}`);
      const response=await fetch(url.toString(),{
        headers:{apikey:key,Authorization:`Bearer ${token}`}
      });
      return {ok:response.ok,records:await response.json()};
    },{api,key:anonKey,token:browserTokenB,slug});
    expect(result.ok,'Authenticated B must query PostgREST successfully').toBe(true);
    expect(result.records,'B must not see tenant A rows').toEqual([]);
  }finally{
    await contextB.close();
  }
});

test('session cookies use root path and SameSite protection',async({page,context})=>{
  await signupViaBrowser(page,identity());
  const authCookies=(await context.cookies()).filter(c=>c.name.startsWith('sb-'));
  expect(authCookies.length,'Supabase session cookies must exist').toBeGreaterThan(0);
  for (const cookie of authCookies){
    expect(cookie.path).toBe('/');
    expect(['Lax','Strict']).toContain(cookie.sameSite);
  }
  // HttpOnly and Secure are recorded in test diagnostics without cookie values.
  console.log('Session cookie attributes:',authCookies.map(c=>({
    name:c.name.replace(/.*/, 'sb-cookie'),httpOnly:c.httpOnly,
    secure:c.secure,sameSite:c.sameSite,path:c.path
  })));
});

test('guest demo renders independently of authentication',async({page})=>{
  await page.goto('/');
  await expect(page.getByText(/ServeAI/i).first()).toBeVisible();
});


function jwtClaims(token){
  return JSON.parse(Buffer.from(token.split('.')[1],'base64url').toString('utf8'));
}

async function waitForExpiry(token){
  const {exp}=jwtClaims(token);
  const remaining=exp*1000-Date.now();
  // Fail promptly when the developer forgot the test-only short expiry.
  expect(Number.isFinite(remaining)&&remaining<150_000,
    'Configure disposable Auth jwt_expiry = 120 before running lifecycle tests').toBe(true);
  await expect.poll(()=>Date.now()>exp*1000+1500,{
    timeout:155_000,intervals:[1000]
  }).toBe(true);
}

function ageCreationEvents(token){
  const {sub,email}=jwtClaims(token);
  if(process.env.E2E_DISPOSABLE_ONLY!=='1' ||
    process.env.E2E_LOCAL_DB_CONTAINER!=='supabase_db_htl-serveai' ||
    !/^[0-9a-f-]{36}$/.test(sub) ||
    !/^serveai-e2e-[0-9a-f-]{36}@example\.test$/.test(email)){
    throw new Error('Quota helper requires the explicitly enabled disposable test database and identity');
  }
  // No shell, no persistent helper/RPC, and no change to quota enforcement.
  // Require matching disposable Auth identity as well as actor ID.
  const sql=`update public.audit_logs set created_at=now()-interval '61 seconds'
    where actor_id='${sub}'::uuid and event_type='tenant.created'
    and exists(select 1 from auth.users where id='${sub}'::uuid and email='${email}');`;
  execFileSync('docker',['exec','-i','supabase_db_htl-serveai',
    'psql','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1'],{
    input:sql,stdio:['pipe','pipe','pipe']
  });
}

test('fourth restaurant is denied after three successful browser creations',async({page})=>{
  const token=await signupViaBrowser(page,identity());
  const prefix=`cap-${randomUUID().slice(0,8)}`;
  for(let i=1;i<=3;i++){
    if(i>1)ageCreationEvents(token);
    await registerRestaurant(page,`Cap Restaurant ${i}`,`${prefix}-${i}`);
    await expect(page).toHaveURL(/\/dashboard$/);
    await expect(page.getByText(`Cap Restaurant ${i}`,{exact:true})).toBeVisible();
  }
  ageCreationEvents(token); // Fourth must hit the total cap, not the cooldown.
  await registerRestaurant(page,'Cap Restaurant 4',`${prefix}-4`);
  await expect(page.locator('form [role="alert"]')).toHaveText(
    'Restaurant creation limit reached. Please try later or contact support.');
  await page.goto('/dashboard');
  for(let i=1;i<=3;i++)await expect(page.getByText(`Cap Restaurant ${i}`,{exact:true})).toBeVisible();
  await expect(page.getByText('Cap Restaurant 4',{exact:true})).toHaveCount(0);
  const current=await browserSessionToken(page.context());
  const response=await page.request.get(`${api}/rest/v1/tenants?select=id`,{
    headers:{apikey:anonKey,Authorization:`Bearer ${current}`}
  });
  expect(response.ok()).toBe(true);
  expect((await response.json()).length,'Exactly three persisted tenants').toBe(3);
});

test('server refresh preserves identity across two actual JWT expiry windows',async({page,browser})=>{
  test.setTimeout(360_000);
  const account=identity();
  await signupViaBrowser(page,account);
  const cookies=await page.context().cookies();
  await page.close(); // Stop the signed-in client's refresh timer.
  const context=await browser.newContext({javaScriptEnabled:false});
  try{
    await context.addCookies(cookies);
    const visitor=await context.newPage();
    for(const route of ['/onboarding','/dashboard']){
      const before=await browserSessionToken(context);
      await waitForExpiry(before);
      await visitor.goto(route);
      await expect(visitor).toHaveURL(new RegExp(`${route}$`));
      const after=await browserSessionToken(context);
      expect(after!==before,'Server navigation must rotate the expired session cookie').toBe(true);
      expect(jwtClaims(after).exp>jwtClaims(before).exp,'Replacement JWT must have a later expiry').toBe(true);
      expect(jwtClaims(after).sub===jwtClaims(before).sub,'Identity must remain unchanged').toBe(true);
    }
    await expect(visitor.getByText(account.email)).toBeVisible();
  }finally{await context.close();}
});

test('revoked refresh credentials cannot recover an expired browser session',async({page,browser,request})=>{
  test.setTimeout(200_000);
  const token=await signupViaBrowser(page,identity());
  const cookies=await page.context().cookies();
  await page.close();
  const logout=await request.post(`${api}/auth/v1/logout?scope=global`,{
    headers:{apikey:anonKey,Authorization:`Bearer ${token}`}
  });
  expect(logout.ok(),'Local Auth must revoke the session').toBe(true);
  const context=await browser.newContext({javaScriptEnabled:false});
  try{
    await context.addCookies(cookies);
    await waitForExpiry(token);
    const visitor=await context.newPage();
    for(const route of ['/dashboard','/onboarding']){
      await visitor.goto(route);
      await expect(visitor).toHaveURL(/\/login(?:\?|$)/);
    }
  }finally{await context.close();}
});
