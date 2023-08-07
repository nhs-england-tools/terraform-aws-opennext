import Head from 'next/head'
import Link from 'next/link'

export default function Home() {
  return (
    <>
      <Head>
        <title>Home - Next.js Feature Test App</title>
        <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main>
        <header>
          <h1>Next.js Feature Test App</h1>
          <p>This app contains a handful of pages. Each page implements a specific Next.js feature. Deploy this app. Then select a test below to check if the feature works.</p>
          <p>Based upon the excellent <a href="https://github.com/serverless-stack/open-next/blob/main/example/">OpenNext example Next.js app</a>.</p>
        </header>
        <section>
          <ul>
            <li><Link href="/ssg">Static Site Generation (SSG)</Link></li>
            <li><Link href="/ssg-dynamic/1">Static Site Generation — with dynamic routes</Link></li>
            <li><Link href="/ssg-dynamic-fallback/1">Static Site Generation — with dynamic route fallback</Link></li>
            <li><Link href="/isr">Incremental Static Regeneration (ISR)</Link></li>
            <li><Link href="/ssr">Server Side Rendering (SSR)</Link></li>
            <li><Link href="/ssr-redirect">Server Side Rendering — redirect</Link></li>
            <li><Link href="/ssr-not-found">Server Side Rendering — page not found</Link></li>
            <li><Link href="/api-route">API Route</Link></li>
            <li><Link href="/middleware-rewrite">Middleware — rewrite</Link></li>
            <li><Link href="/middleware-redirect">Middleware — redirect</Link></li>
            <li><Link href="/middleware-set-header">Middleware — set header</Link></li>
            <li><Link href="/middleware-geolocation">Middleware — geolocation</Link></li>
            <li><Link href="/next-auth">NextAuth</Link></li>
            <li><Link href="/image-optimization-imported">Image Optimization — imported image</Link></li>
            <li><Link href="/image-optimization-remote">Image Optimization — remote image</Link></li>
            <li><Link href="/image-html-tag">Image using html image tag</Link></li>
            <li><Link href="/font-next-font">Font — @next/font</Link></li>
            <li><Link href="/page-does-not-exist">404 Page not found</Link></li>
          </ul>
        </section>
      </main>
    </>
  )
}
