import { MuseoModerno } from "@next/font/google";
import { NextPage } from "next";
import Head from "next/head";

const museo = MuseoModerno({
  subsets: ["latin"],
  weight: "400",
});

const NextFontPage: NextPage = () => (
  <>
    <Head>
      <title>Font - @next/font - Next.js Feature Test App</title>
      <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="icon" href="/favicon.ico" />
    </Head>
    <article>
        <h1>Font — @next/font</h1>
        <p><b>Test 1:</b></p>
        <p>This uses default font.</p>
        <p className={museo.className}>This uses MuseoModerno font.</p>
    </article>
  </>
);

export default NextFontPage
