import { GetServerSideProps, NextPage } from "next";

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
    <article>
        <h1>Middleware - rewrite</h1>
        <b>Test 1:</b>
        <p>URL is rewritten {isRewritten}</p>
    </article>    
);

export default MiddlewareRewritePage;
