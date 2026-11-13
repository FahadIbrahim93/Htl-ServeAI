import Link from 'next/link';
import {requireUser} from '@/lib/supabase/auth';
import {OnboardingForm} from '@/components/onboarding-form';

export default async function Onboarding(){
  await requireUser();
  return <main>
    <header><strong>HTL <span>ServeAI</span></strong><Link href="/dashboard">Dashboard</Link></header>
    <section className="panel">
      <h1>Register your restaurant</h1>
      <p>Creates a tenant, first branch and your owner membership in one audited database transaction.</p>
      <OnboardingForm/>
    </section>
  </main>;
}
