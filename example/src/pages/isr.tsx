import { GetStaticProps, NextPage } from "next";

export const getStaticProps: GetStaticProps = () => {
    return {
        props: {
            time: Date.now()
        },
        revalidate: 10
    }
}

const ISRPage: NextPage<{time: string}> = ({time}) => (
    <article>
        <h1>Incremental Static Rendering (ISR)</h1>
        <h2>Test 1:</h2>
        <p>This timestamp 👉 <b>{time}</b> should change every 10 seconds when the page is repeatedly refreshed.</p>
    </article>
)

export default ISRPage;