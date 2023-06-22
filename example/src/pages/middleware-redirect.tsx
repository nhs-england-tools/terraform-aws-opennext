import { NextPage } from "next";

const MiddlewareRedirectPage: NextPage = ()  => (
    <article>
        <h1>Middleware - redirect</h1>
        <h2>Test 1:</h2>
        <p>If you see this page, Middleware with redirect is NOT working. You should be redirected to /middleware-redirect-destination.</p>
    </article>
);

export default MiddlewareRedirectPage