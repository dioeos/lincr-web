import { useEffect } from "react";
import type { LocationState } from "../../types/locationState";

import { useLocation } from "react-router";

import { JanusClient } from "../../utils/janus/janusClient";

export default function VideoRoom() {
  const location = useLocation();
  const state: LocationState = location.state ?? {};

  const janusRoomId = state?.janusRoomId;
  const videoRoomRole = state?.role;

  useEffect(() => {
    if (!janusRoomId) {
      return;
    }

    if (videoRoomRole !== "host" && videoRoomRole !== "guest") {
      return;
    }

    let cancelled = false;

    const start = async () => {
      try {
        const client = new JanusClient();

        await client.init();
        if (cancelled) return;

        await client.connect("/janus");
        if (cancelled) return;

        if (videoRoomRole === "host") {
          await client.startPublisher({
            janusRoomId: janusRoomId,
          });
        }
      } catch (err) {}
    };

    start();

    return () => {
      cancelled = true;
    };
  }, [janusRoomId, videoRoomRole]);

  return (
    <div>
      <h1>Video Room</h1>
      <span>Room ID:</span> {janusRoomId ?? "Missing"}
    </div>
  );
}
