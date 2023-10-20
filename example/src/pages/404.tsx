import { NextPage } from "next";
import Head from "next/head";

const PageNotFoundPage: NextPage = () => (
    <>
      <Head>
        <title>404 Page Not Found - Next.js Feature Test App</title>
        <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <article>
        <h1>404</h1>
      </article>
    </>
);

export default PageNotFoundPage;
