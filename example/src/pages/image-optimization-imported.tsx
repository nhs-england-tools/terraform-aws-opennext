import Image from 'next/image'
import pic from '../../public/images/patrick.1200x1200.png'
import { NextPage } from 'next';

const ImageOptimizationImportedPage: NextPage = () => (
    <article>
        <h1>Image Optimization</h1>
        <Image id="pic" src={pic} width={100} height={100} alt="Patrick" />
        <h2>Test 1:</h2>
        <p>Original image dimension: 1200 x 1200. Check the dimension of the displayed image is smaller than 1200 x 1200.</p>
    </article>
);

export default ImageOptimizationImportedPage