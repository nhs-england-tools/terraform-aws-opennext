import { GetServerSideProps, NextPage } from "next";
import Head from "next/head";

export const getServerSideProps: GetServerSideProps = async (context) => {
    return {
      props: {
        isRewritten: context.query.rewritten === "true"
          ? "✅"
          : "❌",
      },
    };
  }

const MiddlewareRewritePage: NextPage<{isRewritten: boolean}> = ({ isRewritten }) => (
    <>
      <Head>
        <title>Middleware - Rewrite - Next.js Feature Test App</title>
        <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <article>
        <h1>Middleware - rewrite</h1>
        <b>Test 1:</b>
        <p>URL is rewritten {isRewritten}</p>
      </article>
    </>
);

export default MiddlewareRewritePage;
