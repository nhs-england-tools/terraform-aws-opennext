import { GetServerSideProps, NextPage } from "next";

export const getServerSideProps: GetServerSideProps = async () => {
  return {
    notFound: true,
  };
}

const SSRNotFoundPage: NextPage = () => (
    <article>
        <h1>SSR - Server Side Rendering</h1>
        <h2>Test 1:</h2>
        <p>If you see this page, SSR with notFound is NOT working.</p>
    </article>
);

export default SSRNotFoundPage