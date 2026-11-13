import {describe,it,expect} from 'vitest';
import {validateRestaurantInput} from './tenant-validation';
describe('restaurant onboarding validation',()=>{
  it('normalizes name, slug and branch',()=>{
    expect(validateRestaurantInput({name:'  Dhaka Kitchen ',slug:'  My-Restaurant  ',branchName:' Main '}))
      .toEqual({name:'Dhaka Kitchen',slug:'my-restaurant',branchName:'Main'});
  });
  it('rejects malformed slug',()=>{
    expect(()=>validateRestaurantInput({name:'Restaurant',slug:'test space',branchName:'Main'})).toThrow();
  });
  it('rejects empty restaurant name',()=>{
    expect(()=>validateRestaurantInput({name:' ',slug:'example',branchName:'Main'})).toThrow();
  });
});
