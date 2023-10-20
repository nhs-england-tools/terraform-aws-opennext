import Image from 'next/image'
import pic from '../../public/images/patrick.1200x1200.png'
import { NextPage } from 'next';
import Head from 'next/head';

const ImageOptimizationImportedPage: NextPage = () => (
    <>
      <Head>
        <title>Image Optimization - Imported Image - Next.js Feature Test App</title>
        <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <article>
        <h1>Image Optimization</h1>
        <Image id="pic" src={pic} width={100} height={100} alt="Patrick" />
        <h2>Test 1:</h2>
        <p>Original image dimension: 1200 x 1200. Check the dimension of the displayed image is smaller than 1200 x 1200.</p>
      </article>
    </>
);

export default ImageOptimizationImportedPage
