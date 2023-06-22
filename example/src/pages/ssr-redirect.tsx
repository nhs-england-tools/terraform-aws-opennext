import { GetServerSideProps, NextPage } from "next";

export const getServerSideProps: GetServerSideProps = async () => {
    return {
      redirect: {
        destination: "/ssr-redirect-destination",
        permanent: false,
      },
    };
}
  
const SSRRedirectPage: NextPage = () => (
    <article>
        <h1>Server Side Rendering - redirect</h1>
        <h2>Test 1:</h2>
        <p>If you see this page, SSR with redirect is NOT working. You should be redirected to /ssr-redirect-destination.</p>
    </article>    
);

export default SSRRedirectPage