import { useEffect, useRef } from "react";
import type { LocationState } from "../../types/locationState";

import { useLocation } from "react-router";

import { JanusClient } from "../../utils/janus/janusClient";

export default function VideoRoom() {
  const location = useLocation();
  const state: LocationState = location.state ?? {};

  const janusRoomId = state?.janusRoomId;
  const videoRoomRole = state?.role;

  const localVideoRef = useRef<HTMLVideoElement | null>(null);

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
            onLocalStream: (stream: MediaStream) => {
              if (!localVideoRef.current) return;
              if (localVideoRef.current.srcObject !== stream) {
                localVideoRef.current.srcObject = stream;
              }
            },
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
      {videoRoomRole === "host" && (
        <video
          ref={localVideoRef}
          autoPlay
          playsInline
          muted
          className="w-full max-w-xl rounded-lg bg-black"
        />
      )}
    </div>
  );
}
