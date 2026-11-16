import {defineConfig,devices} from '@playwright/test';

if(process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY){
  throw new Error('Public smoke requires Supabase configuration to be absent');
}
export default defineConfig({
  testDir:'./public-specs',
  retries:0,
  use:{baseURL:'http://127.0.0.1:3000',trace:'off'},
  projects:[{name:'chromium',use:{...devices['Desktop Chrome']}}],
  webServer:{
    command:'npm run start --workspace @serveai/web',
    cwd:'../..',
    url:'http://127.0.0.1:3000',
    reuseExistingServer:false,
  },
});
