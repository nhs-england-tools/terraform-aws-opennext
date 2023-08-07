import { GetServerSideProps, NextPage } from "next";
import Head from "next/head";

export const getServerSideProps: GetServerSideProps = async (context) => {
    return {
      props: {
        isMiddlewareHeaderSet:
            context.req.headers["x-hello-from-middleware-1"] === "hello" ? "yes" : "no",
      },
    };
  }

const MiddlewareSetHeaderPage: NextPage<{isMiddlewareHeaderSet: boolean}> = ({ isMiddlewareHeaderSet }) => (
  <>
    <Head>
      <title>Middleware - Set Header - Next.js Feature Test App</title>
      <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="icon" href="/favicon.ico" />
    </Head>
    <article>
      <h1>Middleware - set header</h1>
      <h2>Test 1:</h2>
      <p>Is middleware header set? {isMiddlewareHeaderSet}</p>
    </article>
  </>
);


export default MiddlewareSetHeaderPage;
