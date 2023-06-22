import { NextPage } from "next";

const ImageHTMLTagPage: NextPage = () => (
    <article>
        <h1>Image using html image tag</h1>
        <img src="/images/patrick.1200x1200.png" alt="Patrick" />
        <h2>Test 1:</h2>
        <p>Original image dimension: 1200 x 1200. Check the dimension of the displayed image is also 1200 x 1200.</p>
    </article>
);


export default ImageHTMLTagPage;