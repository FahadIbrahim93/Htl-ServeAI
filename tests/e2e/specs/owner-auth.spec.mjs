import {test,expect} from '@playwright/test';
import {randomUUID} from 'node:crypto';

const api=process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const password='ServeAI-Test-2026!';

function identity(){
  return {email:`serveai-e2e-${randomUUID()}@example.test`,password};
}

async function signupViaBrowser(page,account){
  const signUpResult=page.waitForResponse(response=>
    response.url().includes('/auth/v1/signup') && response.request().method()==='POST'
  );
  await page.goto('/login');
  await page.getByRole('button',{name:'Need an account? Sign up'}).click();
  await page.getByLabel('Email address').fill(account.email);
  await page.getByLabel('Password').fill(account.password);
  await page.getByRole('button',{name:'Create account'}).click();
  await expect(page).toHaveURL(/\/dashboard$/, {timeout:30_000});
  await expect(page.getByText(account.email)).toBeVisible();
  const response=await signUpResult;
  const payload=await response.json();
  // Store only in test memory; never log or persist disposable Auth tokens.
  return payload.access_token;
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
  await expect(page.getByRole('alert')).toContainText('Restaurant creation limit reached');
  await expect(page).toHaveURL(/\/onboarding$/);
});

test('unauthorized login does not establish an owner session',async({page})=>{
  const account=identity();
  await page.goto('/login');
  await page.getByLabel('Email address').fill(account.email);
  await page.getByLabel('Password').fill('DefinitelyWrongPassword!'); 
  await page.getByRole('button',{name:'Sign in',exact:true}).click();
  await expect(page.getByRole('status')).toBeVisible();
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
  await page.goto('/dashboard');
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
});

test('callback without an exchange code fails closed',async({page})=>{
  await page.goto('/auth/callback');
  await expect(page).toHaveURL(/\/login\?error=callback$/);
});

test('signing out invalidates the browser session for protected routes',async({page})=>{
  await signupViaBrowser(page,identity());
  await page.getByRole('button',{name:/sign out/i}).click();
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
  await page.goto('/dashboard');
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
});


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
    await expect(other.getByRole('alert')).toContainText('slug is already in use');
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
