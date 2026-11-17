import {defineConfig,devices} from '@playwright/test';

if (process.env.E2E_DISPOSABLE_ONLY !== '1') {
  throw new Error('ServeAI browser tests are restricted to disposable local Supabase.');
}

const origin=process.env.E2E_BASE_URL??'http://127.0.0.1:3000';
const supabase=process.env.NEXT_PUBLIC_SUPABASE_URL??'';
for (const target of [origin,supabase]) {
  const url=new URL(target);
  if (!['127.0.0.1','localhost'].includes(url.hostname) || url.protocol!=='http:') {
    throw new Error('Browser E2E tests must target local HTTP origins only.');
  }
}

export default defineConfig({
  testDir:'./specs',
  fullyParallel:false,
  workers:1,
  retries:process.env.CI?1:0,
  timeout:60_000,
  expect:{timeout:15_000},
  reporter:process.env.CI
    ? [['line'],['html',{open:'never',outputFolder:'playwright-report'}]]
    : [['list']],
  use:{
    baseURL:origin,
    // Auth traces include request bodies, Authorization headers and cookie values.
    // Keep screenshots and HTML diagnostics, but never record those secrets.
    trace:'off',
    screenshot:'only-on-failure',
    actionTimeout:20_000,
  },
  projects:[{name:'chromium',use:{...devices['Desktop Chrome']}}],
});
