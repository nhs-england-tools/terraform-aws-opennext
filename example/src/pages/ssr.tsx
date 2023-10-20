import { GetServerSideProps, NextPage } from "next";
import Head from "next/head";

export const getServerSideProps: GetServerSideProps = async () => {
    return {
      props: {
        time: Date.now(),
      },
    };
}

const SSRPage: NextPage<{time: number}> = ({ time }) => (
  <>
    <Head>
      <title>Server Side Rendering (SSR) - Next.js Feature Test App</title>
      <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="icon" href="/favicon.ico" />
    </Head>
    <article>
      <h1>Server Side Rendering (SSR)</h1>
      <h2>Test 1</h2>
      <p>This timestamp 👉 <b>{time}</b> should change every time the page is refreshed, because the page is rendered on the server on every request.</p>
    </article>
  </>
);

export default SSRPage
