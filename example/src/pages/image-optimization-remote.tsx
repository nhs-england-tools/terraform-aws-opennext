import { NextPage } from 'next';
import Image from 'next/image'
import Head from 'next/head';

const ImageOptimizationRemotePage: NextPage = () => (
  <>
    <Head>
      <title>Image Optimization - Remote Image - Next.js Feature Test App</title>
      <meta name="description" content="Next.js Test App for terraform-aws-opennext" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="icon" href="/favicon.ico" />
    </Head>
    <article>
      <h1>Image Optimization</h1>
      <Image id="pic" src="https://images.unsplash.com/photo-1632730038107-77ecf95635ab" width={100} height={100} alt="Misty Forest" />
      <h2>Test 1:</h2>
      <p>Original image dimension: 2268 x 4032. Check the dimension of the displayed image is smaller than 256 x 455.</p>
    </article>
  </>
);

export default ImageOptimizationRemotePage
