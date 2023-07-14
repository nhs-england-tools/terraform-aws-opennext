import { NextPage } from "next";
import Head from "next/head";

const SSRDestinationPage: NextPage = () => (
    <>
      <Head>
        <title>SSR Redirect Destination - Next.js Feature Test App</title>
        <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <article>
        <h1>Server Side Rendering - redirect</h1>
        <h2>Test 1:</h2>
        <p>If you see this page, SSR with redirect is working.</p>
      </article>
    </>
);

export default SSRDestinationPage
