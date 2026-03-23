import { useEffect } from "react";
import { useNavigate } from "react-router";
import type { AxiosError } from "axios";

import api from "../../utils/api/api";

export default function HostInit() {
  const navigate = useNavigate();
  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      try {
        const response = await api.post("rooms/create");
        const code: string = response.data.room_code;

        if (cancelled) return;
        navigate(`/room/${code}`, { state: "host", replace: true });
      } catch (err) {
        const axiosError = err as AxiosError<{ detail?: string }>;
        if (cancelled) return;

        const status = axiosError.response?.status;
        const detail =
          axiosError.response?.data?.detail ??
          axiosError.message ??
          "Unknown error";

        console.error(status);
        console.error(detail);
      }
    };
    run();
  }, [navigate]);

  return null;
}
