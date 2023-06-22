import { GetServerSideProps, NextPage } from "next";

export const getServerSideProps: GetServerSideProps = async (context) => {
  return {
    props: {
      qs: JSON.stringify(context.query),
    },
  };
}

const GeolocationMiddlewarePage: NextPage<{qs: string}> = ({ qs }) => (
      <article>
        <h1>Middleware - geolocation</h1>
        <h2>Test 1:</h2>
        <p>URL query contains country, city, and region: {qs}</p>
      </article>
);

export default GeolocationMiddlewarePage;