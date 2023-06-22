import { NextPage } from 'next';
import Image from 'next/image'

const ImageOptimizationRemotePage: NextPage = () => (    
      <article>
        <h1>Image Optimization</h1>
        <Image id="pic" src="https://images.unsplash.com/photo-1632730038107-77ecf95635ab" width={100} height={100} alt="Misty Forest" />
        <h2>Test 1:</h2>
        <p>Original image dimension: 2268 x 4032. Check the dimension of the displayed image is smaller than 256 x 455.</p>
      </article>
);

export default ImageOptimizationRemotePage