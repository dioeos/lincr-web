import type { ReactNode } from "react";
import type { Navbarlink } from "../../types/navbarlink";
import Navbar from "../Navbar/Navbar";

type LayoutProps = {
  children: ReactNode;
};

const links: Navbarlink[] = [
  { title: "About", href: "/" },
  { title: "Sign Up", href: "/" },
  { title: "Docs", href: "/" },
  { title: "Discord", href: "/" },
];

const Layout = ({ children }: LayoutProps) => {
  return (
    <div className="bg-snow min-h-screen grid grid-cols-1 xl:grid-cols-[1fr_minmax(0,2fr)_1fr]">
      <div className="hidden xl:block"></div>

      <div className="flex">
        <div className="flex flex-col w-full">
          <Navbar links={links} />
          <main className="flex items-center justify-center px-4 py-8 md:px-8 md:py-12">
            {children}
          </main>
        </div>
      </div>

      <div className="hidden xl:block"></div>
    </div>
  );
};

export default Layout;
