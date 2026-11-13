import {describe,it,expect} from 'vitest';
import {priceCart} from '../src/lib/pricing';
import {transition} from '../src/lib/orders';
describe('money and orders',()=>{
 it('calculates example order exactly',()=>expect(priceCart([{id:'a',name:'Biryani',unitMinor:22000,qty:2},{id:'b',name:'Borhani',unitMinor:6000,qty:2}],0,500,500)).toEqual({subtotalMinor:56000,discountMinor:0,serviceMinor:2800,vatMinor:2940,totalMinor:61740}));
 it('rejects negative prices',()=>expect(()=>priceCart([{id:'a',name:'bad',unitMinor:-1,qty:1}])).toThrow());
 it('rejects over-discount',()=>expect(()=>priceCart([{id:'a',name:'x',unitMinor:100,qty:1}],101)).toThrow());
 it('enforces version',()=>expect(()=>transition('confirmed','preparing',2,1)).toThrow());
 it('enforces state',()=>expect(()=>transition('confirmed','served',1,1)).toThrow());
});
