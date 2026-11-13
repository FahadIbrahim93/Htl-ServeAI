import type {Metadata} from 'next';import './style.css';
export const metadata:Metadata={title:'HTL ServeAI — Restaurant OS',description:'Bangla-first restaurant operations platform by Hope Theory Labs'};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="bn"><body>{children}</body></html>}
