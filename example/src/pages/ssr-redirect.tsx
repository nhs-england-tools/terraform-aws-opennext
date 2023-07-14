import { GetServerSideProps, NextPage } from "next";
import Head from "next/head";

export const getServerSideProps: GetServerSideProps = async () => {
    return {
      redirect: {
        destination: "/ssr-redirect-destination",
        permanent: false,
      },
    };
}

const SSRRedirectPage: NextPage = () => (
  <>
    <Head>
      <title>SSR Redirect - Next.js Feature Test App</title>
      <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="icon" href="/favicon.ico" />
    </Head>
    <article>
      <h1>Server Side Rendering - redirect</h1>
      <h2>Test 1:</h2>
      <p>If you see this page, SSR with redirect is NOT working. You should be redirected to /ssr-redirect-destination.</p>
    </article>
  </>
);

export default SSRRedirectPage
