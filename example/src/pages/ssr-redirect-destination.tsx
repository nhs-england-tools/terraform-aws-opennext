import { NextPage } from "next";

const SSRDestinationPage: NextPage = () => (
    <article>
        <h1>Server Side Rendering - redirect</h1>
        <h2>Test 1:</h2>
        <p>If you see this page, SSR with redirect is working.</p>
    </article>
);

export default SSRDestinationPage