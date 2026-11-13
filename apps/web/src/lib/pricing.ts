export type CartLine={id:string;name:string;unitMinor:number;qty:number};
export type Charges={subtotalMinor:number;discountMinor:number;serviceMinor:number;vatMinor:number;totalMinor:number};
/** All money is in BDT poisha. Rate basis points: 10000 = 100%. Rates are configuration, not legal advice. */
export function priceCart(lines:CartLine[],discountMinor=0,serviceBps=0,vatBps=0):Charges {
 for(const line of lines){if(!Number.isSafeInteger(line.unitMinor)||line.unitMinor<0||!Number.isSafeInteger(line.qty)||line.qty<1)throw Error('Invalid line');}
 for(const n of [discountMinor,serviceBps,vatBps])if(!Number.isSafeInteger(n)||n<0)throw Error('Invalid charge');
 if(serviceBps>10000||vatBps>10000)throw Error('Invalid rate');
 const subtotalMinor=lines.reduce((a,b)=>a+b.unitMinor*b.qty,0);
 if(!Number.isSafeInteger(subtotalMinor)||discountMinor>subtotalMinor)throw Error('Invalid discount');
 const base=subtotalMinor-discountMinor;
 const serviceMinor=Math.round(base*serviceBps/10000);
 const vatMinor=Math.round((base+serviceMinor)*vatBps/10000);
 const totalMinor=base+serviceMinor+vatMinor;
 if(!Number.isSafeInteger(totalMinor))throw Error('Overflow');
 return {subtotalMinor,discountMinor,serviceMinor,vatMinor,totalMinor};
}
export const taka=(minor:number)=>`৳${(minor/100).toFixed(2)}`;
