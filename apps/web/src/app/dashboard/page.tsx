import Link from 'next/link';
import {requireUser} from '@/lib/supabase/auth';
import {SignOut} from '@/components/sign-out';

type TenantJoin={name:string;slug:string}|null;
type MembershipRow={tenant_id:string;role:string;tenants:TenantJoin|TenantJoin[]};

export default async function Dashboard(){
  const {supabase,user}=await requireUser();
  const {data,error}=await supabase.from('memberships')
    .select('tenant_id, role, tenants(name,slug)').eq('user_id',user.id);

  const memberships=(data??[]) as unknown as MembershipRow[];
  return <main>
    <header><strong>HTL <span>ServeAI</span></strong><SignOut/></header>
    <section className="panel">
      <h1>Restaurant dashboard</h1>
      <p>Signed in as {user.email??'Authenticated user'}</p>
      {error&&<p role="alert">Unable to load restaurants. Please try again.</p>}
      {!error&&memberships.length===0&&<p>No restaurants linked to your account yet.</p>}
      {!error&&memberships.map(row=>{
        const restaurant=Array.isArray(row.tenants)?row.tenants[0]:row.tenants;
        return <article key={row.tenant_id} className="line">
          <div><strong>{restaurant?.name??'Restaurant'}</strong>
          <small>{restaurant?.slug??''} · {row.role}</small></div>
          <span>Trial / setup</span>
        </article>;
      })}
      <p><Link href="/onboarding">+ Create a restaurant</Link></p>
      <p className="note">Order persistence, staff invitations, kitchen and billing are still under development.</p>
      <p><Link href="/">Open guest UX prototype</Link></p>
    </section>
  </main>;
}
