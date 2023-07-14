import { GetStaticProps, NextPage } from "next";
import Head from "next/head";

export const getStaticProps: GetStaticProps = () => {
    return {
        props: {
            time: Date.now()
        },
        revalidate: 10
    }
}

const ISRPage: NextPage<{time: string}> = ({time}) => (
    <>
      <Head>
        <title>Incremental Static Rendering (ISR) - Next.js Feature Test App</title>
        <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <article>
        <h1>Incremental Static Rendering (ISR)</h1>
        <h2>Test 1:</h2>
        <p>This timestamp 👉 <b>{time}</b> should change every 10 seconds when the page is repeatedly refreshed.</p>
      </article>
    </>
)

export default ISRPage;
