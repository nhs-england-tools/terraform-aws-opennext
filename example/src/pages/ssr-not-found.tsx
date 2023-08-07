import { GetServerSideProps, NextPage } from "next";
import Head from "next/head";

export const getServerSideProps: GetServerSideProps = async () => {
  return {
    notFound: true,
  };
}

const SSRNotFoundPage: NextPage = () => (
  <>
    <Head>
      <title>SSR Not Found - Next.js Feature Test App</title>
      <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="icon" href="/favicon.ico" />
    </Head>
    <article>
      <h1>SSR - Server Side Rendering</h1>
      <h2>Test 1:</h2>
      <p>If you see this page, SSR with notFound is NOT working.</p>
    </article>
  </>
);

export default SSRNotFoundPage
