import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.tsx";

import HostInit from "./pages/HostInit/HostInit";
import LincrVideoRoom from "./pages/LincrVideoRoom/LincrVideoRoom";
import VideoRoom from "./pages/VideoRoom/VideoRoom";

import { BrowserRouter, Routes, Route } from "react-router";
import JoinInit from "./pages/JoinInit/JoinInit.tsx";

createRoot(document.getElementById("root")!).render(
  <BrowserRouter>
    <Routes>
      <Route path="/" element={<App />} />
      <Route path="/host" element={<HostInit />} />
      <Route path="/join" element={<JoinInit />} />
      <Route path="/room/:code" element={<VideoRoom />} />
    </Routes>
  </BrowserRouter>,
);
