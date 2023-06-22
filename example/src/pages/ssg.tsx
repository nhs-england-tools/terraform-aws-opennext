import { GetStaticProps, NextPage } from "next";
import React from "react";

export const getStaticProps: GetStaticProps = async () => {
    return {
        props: {
            time: new Date().toISOString()
        }
    }
}

const SSGPage: NextPage<{time: string}> = ({time}) => (
    <article>
        <h1>Static Site Generation (SSG)</h1>
        <h2>Test 1:</h2>
        <p> This timestamp 👉 <b>{time}</b> should be when the `npx open-next build` was run, not when the page is refreshed. Hence, this time should not change on refresh.</p>
        <h2>Test 2:</h2>
        <p>Check your browser&apos;s developer console. the request might show cache MISS on first load. Subsequent refreshes should shows cache HIT.</p>
    </article>
)

export default SSGPage