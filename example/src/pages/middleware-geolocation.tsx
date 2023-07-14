import { GetServerSideProps, NextPage } from "next";
import Head from "next/head";

export const getServerSideProps: GetServerSideProps = async (context) => {
  return {
    props: {
      qs: JSON.stringify(context.query),
    },
  };
}

const GeolocationMiddlewarePage: NextPage<{qs: string}> = ({ qs }) => (
  <>
    <Head>
      <title>Middleware - Geolocation - Next.js Feature Test App</title>
      <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="icon" href="/favicon.ico" />
    </Head>
    <article>
      <h1>Middleware - geolocation</h1>
      <h2>Test 1:</h2>
      <p>URL query contains country, city, and region: {qs}</p>
    </article>
  </>
);

export default GeolocationMiddlewarePage;
