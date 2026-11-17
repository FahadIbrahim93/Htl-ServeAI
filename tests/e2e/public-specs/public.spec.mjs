import {test,expect} from '@playwright/test';

for(const route of ['/','/login']){
  test(`${route} renders without Supabase settings`,async({page})=>{
    const errors=[];
    page.on('pageerror',error=>errors.push(error.message));
    const response=await page.goto(route);
    expect(response.status()).toBe(200);
    if(route==='/login'){
      await expect(page.getByRole('heading',{name:'Restaurant owner sign-in'})).toBeVisible();
      await expect(page.getByLabel('Email address')).toBeVisible();
      await expect(page.getByRole('button',{name:'Sign in',exact:true})).toBeEnabled();
    }else{
      await expect(page.getByText(/ServeAI/i).first()).toBeVisible();
    }
    expect(errors).toEqual([]);
  });
}
