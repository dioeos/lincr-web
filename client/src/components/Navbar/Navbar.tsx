import { Link } from "react-router";

const links = [
  { title: "About", href: "/" },
  { title: "Sign Up", href: "/" },
  { title: "Docs", href: "/" },
  { title: "Discord", href: "/" },
];

export default function Navbar() {
  return (
    <div id="nav-wrapper" className="">
      <nav className="font-geist-light uppercase text-xs">
        <div className="max-w-5xl mx-auto flex flex-wrap items-center justify-center gap-6 md:gap-10 lg:gap-16 px-4 py-4 md:px-8 md:py-6">
          {links.map((link, index) => (
            <Link key={`_l_${index}`} to={link.href}>
              {link.title}
            </Link>
          ))}
        </div>
      </nav>
    </div>
  );
}
