import Layout from "../../components/Layout/Layout";
import { useEffect } from "react";
import api from "../../utils/api/api";

export default function Index() {
  useEffect(() => {
    const run = async () => {
      try {
        const response = await api.get("rooms/hello");
        const data = response.data;
        console.log(data);
      } catch (err) {
        console.error("Error");
      }
    };
    run();
  });
  return (
    <Layout>
      <div className="flex flex-row justify-center items-center gap-6 md:gap-12">
        <a className="no-underline font-geist-light" href="/host">
          Host a Room
        </a>
        <a className="no-underline font-geist-light" href="#">
          Join a Room
        </a>
      </div>
    </Layout>
  );
}
