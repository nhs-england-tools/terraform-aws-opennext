import { NextPage } from "next";
import useSWR from "swr";

const fetcher = (url: string) => fetch(url).then((res) => res.json());

const APIRoutePage: NextPage = () => {
  const { data } = useSWR("/api/hello", fetcher);
  return (
    <article>
        <h1>API Route</h1>
        <h2>Test 1:</h2>
        <p>The API response 👉 {JSON.stringify(data)} should be {`{"hello":"world"}`}.</p>
    </article>
  );
}

export default APIRoutePage