import { useEffect } from "react";
import { useNavigate } from "react-router";
// import type { AxiosError } from "axios";

import api from "../../utils/api/api";

type CreateRoomSuccess = {
  room_code: string;
  janus_room_id: number;
};

export default function HostInit() {
  const navigate = useNavigate();
  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      try {
        const response = await api.post<CreateRoomSuccess>("rooms/create");
        const code: string = response.data.room_code;

        if (cancelled) return;
        navigate(`/room/${code}`, {
          state: {
            janus_room_id: response.data.janus_room_id,
            role: "host",
          },
          replace: true,
        });
      } catch (err) {
        if (!cancelled) {
          navigate("/error");
        }
      }
    };
    run();
    return () => {
      cancelled = true;
    };
  }, [navigate]);

  return null;
}
