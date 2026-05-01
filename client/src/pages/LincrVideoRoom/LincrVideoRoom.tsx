// PS C:\Users\eryan> adb reverse tcp:5173 tcp:5173
// 5173
// PS C:\Users\eryan> adb reverse tcp:8008 tcp:80
// 8008
// PS C:\Users\eryan> adb reverse tcp:9001 tcp:9000
// 9001
// PS C:\Users\eryan> adb reverse tcp:8088 tcp:8088
// 8088

import { useEffect, useRef, useState } from "react";
import { useLocation } from "react-router";
import { JanusVideoRoomClient } from "../../utils/janus/janus";

type LocationState = {
  janus_room_id?: number;
  role?: "host" | "guest";
};

type RemoteStreamsMap = Record<number, MediaStream>;

type PublisherInfo = {
  id?: number;
  display?: string;
};

export default function LincrVideoRoom() {
  const location = useLocation();
  const state = (location.state ?? {}) as LocationState;

  const janus_room_id = state?.janus_room_id;
  const role = state?.role;

  const [status, setStatus] = useState("idle");
  const [error, setError] = useState<string | null>(null);
  const [remoteStreams, setRemoteStreams] = useState<RemoteStreamsMap>({});

  const janusClientRef = useRef<JanusVideoRoomClient | null>(null);
  const localVideoRef = useRef<HTMLVideoElement | null>(null);
  const subscribedFeedsRef = useRef<Set<number>>(new Set());

  useEffect(() => {
    if (!janus_room_id) {
      setError("Missing janus_room_id.");
      setStatus("error");
      return;
    }

    if (role !== "host" && role !== "guest") {
      setError("Missing role.");
      setStatus("error");
      return;
    }

    let cancelled = false;

    const attachRemoteFeed = async (
      client: JanusVideoRoomClient,
      publishers: PublisherInfo[],
    ) => {
      for (const publisher of publishers) {
        const feedId = publisher.id;

        if (!feedId) continue;
        if (subscribedFeedsRef.current.has(feedId)) continue;
        if (client.hasSubscriber(feedId)) continue;

        subscribedFeedsRef.current.add(feedId);

        try {
          await client.subscribeToFeed(
            feedId,
            janus_room_id,
            (id: number, stream: MediaStream) => {
              setRemoteStreams((prev) => ({
                ...prev,
                [id]: stream,
              }));
            },
          );
        } catch (err) {
          console.error("Failed subscribing to feed", feedId, err);
          subscribedFeedsRef.current.delete(feedId);
        }
      }
    };

    const start = async () => {
      try {
        setError(null);
        setStatus("initializing-janus");

        const client = new JanusVideoRoomClient();
        janusClientRef.current = client;

        await client.init();
        if (cancelled) return;

        await client.connect("/janus");
        if (cancelled) return;

        if (role === "host") {
          setStatus("publishing");

          await client.startPublisher({
            roomId: janus_room_id,
            displayName: "Host",
            onLocalStream: (stream: MediaStream) => {
              if (!localVideoRef.current) return;
              if (localVideoRef.current.srcObject !== stream) {
                localVideoRef.current.srcObject = stream;
              }
            },
            onPublisherJoined: async (publishers: PublisherInfo[]) => {
              if (cancelled) return;
              await attachRemoteFeed(client, publishers);
            },
          });
        } else {
          setStatus("subscribing");

          await client.startSubscriber({
            roomId: janus_room_id,
            displayName: "Guest",
            onPublisherJoined: async (publishers: PublisherInfo[]) => {
              if (cancelled) return;
              await attachRemoteFeed(client, publishers);
            },
          });
        }

        if (!cancelled) {
          setStatus("live");
        }
      } catch (err) {
        console.error(err);
        if (!cancelled) {
          setError("Failed to initialize Janus video room.");
          setStatus("error");
        }
      }
    };

    start();

    return () => {
      cancelled = true;
      subscribedFeedsRef.current.clear();
      janusClientRef.current?.destroy();
      janusClientRef.current = null;
      setRemoteStreams({});
    };
  }, [janus_room_id, role]);

  return (
    <div className="p-6">
      <h1 className="mb-4 text-xl font-semibold">LINCR Video Room</h1>

      <div className="mb-2">
        <span className="font-medium">Room ID:</span>{" "}
        {janus_room_id ?? "missing"}
      </div>

      <div className="mb-4">
        <span className="font-medium">Role:</span> {role ?? "missing"}
      </div>

      <div className="mb-4">
        <span className="font-medium">Status:</span> {status}
      </div>

      {error && <div className="mb-4 text-red-500">{error}</div>}

      {role === "host" && (
        <div className="mb-6">
          <h2 className="mb-2 text-lg font-medium">Local Video</h2>
          <video
            ref={localVideoRef}
            autoPlay
            playsInline
            muted
            className="w-full max-w-xl rounded-lg bg-black"
          />
        </div>
      )}

      <div>
        <h2 className="mb-2 text-lg font-medium">Remote Streams</h2>

        {Object.keys(remoteStreams).length === 0 && (
          <div className="text-sm text-gray-400">No remote streams yet.</div>
        )}

        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          {Object.entries(remoteStreams).map(([id, stream]) => (
            <video
              key={id}
              autoPlay
              playsInline
              muted
              ref={(el) => {
                if (!el) return;

                if (el.srcObject !== stream) {
                  el.srcObject = stream;
                }

                void el.play().catch((err) => {
                  console.error(`Failed to play remote stream ${id}`, err);
                });
              }}
              className="w-full rounded-lg bg-black"
            />
          ))}
        </div>
      </div>
    </div>
  );
}
