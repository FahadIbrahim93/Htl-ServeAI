export const transitions={confirmed:['preparing','cancelled'],preparing:['ready','cancelled'],ready:['served'],served:[],cancelled:[]} as const;
export type OrderStatus=keyof typeof transitions;
export function transition(from:OrderStatus,to:OrderStatus,expectedVersion:number,actualVersion:number){
 if(expectedVersion!==actualVersion)throw Error('Version conflict');
 if(!(transitions[from] as readonly string[]).includes(to))throw Error('Invalid transition');
 return {status:to,version:actualVersion+1};
}
