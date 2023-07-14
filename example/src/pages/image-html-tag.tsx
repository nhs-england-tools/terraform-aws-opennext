import { NextPage } from "next";
import Head from "next/head";

const ImageHTMLTagPage: NextPage = () => (
    <>
      <Head>
        <title>Image using html image tag - Next.js Feature Test App</title>
        <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <article>
        <h1>Image using html image tag</h1>
        <img src="/images/patrick.1200x1200.png" alt="Patrick" />
        <h2>Test 1:</h2>
        <p>Original image dimension: 1200 x 1200. Check the dimension of the displayed image is also 1200 x 1200.</p>
      </article>
    </>
);


export default ImageHTMLTagPage;
