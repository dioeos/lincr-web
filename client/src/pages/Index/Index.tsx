import Layout from "../../components/Layout/Layout";

export default function Index() {
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
