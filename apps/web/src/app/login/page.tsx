import Link from 'next/link';
import {AuthForm} from '@/components/auth-form';

export default function Login(){
  return <main>
    <header><strong>HTL <span>ServeAI</span></strong><Link href="/">Guest demo</Link></header>
    <section className="panel">
      <h1>Restaurant owner sign-in</h1>
      <p>Sign in to manage your restaurant or create a trial account.</p>
      <AuthForm/>
    </section>
  </main>;
}
