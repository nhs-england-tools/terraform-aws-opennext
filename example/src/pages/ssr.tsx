import { GetServerSideProps, NextPage } from "next";

export const getServerSideProps: GetServerSideProps = async () => {
    return {
      props: {
        time: Date.now(),
      },
    };
}
  
const SSRPage: NextPage<{time: number}> = ({ time }) => (
    <article>
        <h1>Server Side Rendering (SSR)</h1>
        <h2>Test 1</h2>
        <p>This timestamp 👉 <b>{time}</b> should change every time the page is refreshed, because the page is rendered on the server on every request.</p>
    </article>
);

export default SSRPage
  