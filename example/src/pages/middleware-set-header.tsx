import { GetServerSideProps, NextPage } from "next";

export const getServerSideProps: GetServerSideProps = async (context) => {
    return {
      props: {
        isMiddlewareHeaderSet: 
            context.req.headers["x-hello-from-middleware-1"] === "hello" ? "yes" : "no",
      },
    };
  }
  
const MiddlewareSetHeaderPage: NextPage<{isMiddlewareHeaderSet: boolean}> = ({ isMiddlewareHeaderSet }) => (
        <article>
          <h1>Middleware - set header</h1>
          <h2>Test 1:</h2>
          <p>Is middleware header set? {isMiddlewareHeaderSet}</p>
        </article>
);


export default MiddlewareSetHeaderPage;