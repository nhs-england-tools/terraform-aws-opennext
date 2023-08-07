import { NextPage } from "next";
import Head from "next/head";

const MiddlewareRedirectPage: NextPage = ()  => (
    <>
      <Head>
        <title>Middleware - Redirect - Next.js Feature Test App</title>
        <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <article>
        <h1>Middleware - redirect</h1>
        <h2>Test 1:</h2>
        <p>If you see this page, Middleware with redirect is NOT working. You should be redirected to /middleware-redirect-destination.</p>
      </article>
    </>
);

export default MiddlewareRedirectPage
