import { MuseoModerno } from "@next/font/google";
import { NextPage } from "next";

const museo = MuseoModerno({
  subsets: ["latin"],
  weight: "400",
});

const NextFontPage: NextPage = () => (
    <article>
        <h1>Font — @next/font</h1>
        <p><b>Test 1:</b></p>
        <p>This uses default font.</p>
        <p className={museo.className}>This uses MuseoModerno font.</p>
    </article>    
);

export default NextFontPage