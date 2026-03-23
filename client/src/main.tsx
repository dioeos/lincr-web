import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.tsx";

import HostInit from "./pages/HostInit/HostInit";
import LincrVideoRoom from "./pages/LincrVideoRoom/LincrVideoRoom";

import { BrowserRouter, Routes, Route } from "react-router";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<App />} />
        <Route path="/host" element={<HostInit />} />
        <Route path="/room/:code" element={<LincrVideoRoom />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
);
