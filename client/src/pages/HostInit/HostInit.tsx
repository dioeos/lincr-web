import { useEffect } from "react";
import { useNavigate } from "react-router";
import type { Room } from "../../types/room";

import api from "../../utils/api/api";

export default function HostInit() {
  const navigate = useNavigate();
  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      try {
        const response = await api.post<Room>("rooms/create");
        const code: string = response.data.room_code;

        if (cancelled) return;
        navigate(`/room/${code}`, {
          state: {
            janusRoomId: response.data.janus_room_id,
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
