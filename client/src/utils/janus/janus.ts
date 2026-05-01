import adapter from "webrtc-adapter";
(window as any).adapter = adapter;
import Janus from "janus-gateway";

const janusSecret = import.meta.env.VITE_JANUS_API_SECRET;

type StartSubscriberArgs = {
  roomId: number;
  displayName?: string;
  onPublisherJoined?: (publishers: PublisherInfo[]) => void;
};

export class JanusVideoRoomClient {
  private janus: any = null;
  private publisherHandle: any = null;
  private subscriberHandles = new Map<number, any>();
  private opaqueId = `lincr-${Math.random().toString(36).slice(2)}`;

  async init() {
    await new Promise<void>((resolve) => {
      Janus.init({
        debug: "all",
        callback: () => resolve(),
      });
    });
  }

  async connect(server = "/janus") {
    return new Promise<void>((resolve, reject) => {
      this.janus = new Janus({
        server,
        apisecret: janusSecret,
        success: () => resolve(),
        error: (err: unknown) => reject(err),
        destroyed: () => {},
      });
    });
  }

  hasSubscriber(feedId: number) {
    return this.subscriberHandles.has(feedId);
  }

  async startSubscriber(args: StartSubscriberArgs) {
    const { roomId, displayName = "Guest", onPublisherJoined } = args;

    return new Promise<void>((resolve, reject) => {
      let resolved = false;

      this.janus.attach({
        plugin: "janus.plugin.videoroom",
        opaqueId: `${this.opaqueId}-listener`,

        success: (pluginHandle: any) => {
          this.publisherHandle = pluginHandle;

          pluginHandle.send({
            message: {
              request: "join",
              ptype: "publisher",
              room: roomId,
              display: displayName,
            },
          });
        },

        error: (err: unknown) => reject(err),

        onmessage: (msg: any, _jsep: any) => {
          console.log("[subscriber control] onmessage", msg);

          const event = msg?.videoroom;

          if (msg?.error) {
            reject(new Error(msg.error));
            return;
          }

          if (event === "joined") {
            const publishers = msg.publishers ?? [];
            onPublisherJoined?.(publishers);

            this.publisherHandle.send({
              message: {
                request: "listparticipants",
                room: roomId,
              },
              success: (resp: any) => {
                console.log("[subscriber control] listparticipants", resp);

                const participants = (resp?.participants ?? []).filter(
                  (p: any) => p.publisher && p.id,
                );

                onPublisherJoined?.(participants);

                if (!resolved) {
                  resolved = true;
                  resolve();
                }
              },
            });

            if (!resolved) {
              resolved = true;
              resolve();
            }

            return;
          }

          if (event === "event" && msg.publishers) {
            onPublisherJoined?.(msg.publishers);

            if (!resolved) {
              resolved = true;
              resolve();
            }

            return;
          }

          if (event === "event" && msg.participants) {
            const publishers = msg.participants.filter(
              (p: any) => p.publisher && p.id,
            );
            onPublisherJoined?.(publishers);

            if (!resolved) {
              resolved = true;
              resolve();
            }
          }
        },

        oncleanup: () => {},
      });
    });
  }

  async startPublisher(args: StartPublisherArgs) {
    const { roomId, displayName, onLocalStream, onPublisherJoined } = args;

    const localStream = new MediaStream();

    return new Promise<void>((resolve, reject) => {
      this.janus.attach({
        plugin: "janus.plugin.videoroom",
        opaqueId: this.opaqueId,

        success: (pluginHandle: any) => {
          this.publisherHandle = pluginHandle;

          pluginHandle.send({
            message: {
              request: "join",
              ptype: "publisher",
              room: roomId,
              display: displayName,
            },
          });
        },

        error: (err: unknown) => reject(err),

        onmessage: (msg: any, jsep: any) => {
          const event = msg?.videoroom;

          if (event === "joined") {
            const publishers: PublisherInfo[] = msg.publishers ?? [];
            onPublisherJoined?.(publishers);

            this.publisherHandle.createOffer({
              tracks: [
                { type: "audio", capture: true, recv: false },
                { type: "video", capture: true, recv: false },
              ],
              success: (offerJsep: any) => {
                this.publisherHandle.send({
                  message: {
                    request: "configure",
                    audio: true,
                    video: true,
                  },
                  jsep: offerJsep,
                });
                resolve();
              },
              error: (err: unknown) => reject(err),
            });

            return;
          }

          if (event === "event" && msg.publishers) {
            onPublisherJoined?.(msg.publishers as PublisherInfo[]);
          }

          if (jsep) {
            this.publisherHandle.handleRemoteJsep({ jsep });
          }
        },

        onlocaltrack: (track: MediaStreamTrack, on: boolean) => {
          if (!on) return;

          const alreadyExists = localStream
            .getTracks()
            .some((t) => t.id === track.id);

          if (!alreadyExists) {
            localStream.addTrack(track);
          }

          onLocalStream?.(localStream);
        },

        oncleanup: () => {},
      });
    });
  }

  async subscribeToFeed(
    feedId: number,
    roomId: number,
    onRemoteStream?: (feedId: number, stream: MediaStream) => void,
  ) {
    if (this.subscriberHandles.has(feedId)) {
      return;
    }

    return new Promise<void>((resolve, reject) => {
      let subscriberHandle: any = null;
      const remoteStream = new MediaStream();
      let started = false;

      this.janus.attach({
        plugin: "janus.plugin.videoroom",
        opaqueId: `${this.opaqueId}-sub-${feedId}`,

        success: (pluginHandle: any) => {
          subscriberHandle = pluginHandle;
          this.subscriberHandles.set(feedId, pluginHandle);

          pluginHandle.send({
            message: {
              request: "join",
              ptype: "subscriber",
              room: roomId,
              feed: feedId,
            },
          });
        },

        error: (err: unknown) => reject(err),

        onmessage: (_msg: any, jsep: any) => {
          if (!jsep || !subscriberHandle) return;

          subscriberHandle.createAnswer({
            jsep,
            tracks: [
              { type: "audio", recv: true },
              { type: "video", recv: true },
            ],
            success: (answerJsep: any) => {
              subscriberHandle.send({
                message: { request: "start", room: roomId },
                jsep: answerJsep,
              });

              if (!started) {
                started = true;
                resolve();
              }
            },
            error: (err: unknown) => reject(err),
          });
        },

        onremotetrack: (track: MediaStreamTrack, _mid: string, on: boolean) => {
          if (!on) return;

          const alreadyExists = remoteStream
            .getTracks()
            .some((t) => t.id === track.id);

          if (!alreadyExists) {
            remoteStream.addTrack(track);
          }

          onRemoteStream?.(feedId, remoteStream);
        },

        oncleanup: () => {
          this.subscriberHandles.delete(feedId);
        },
      });
    });
  }

  destroy() {
    this.subscriberHandles.clear();

    if (this.janus) {
      this.janus.destroy();
      this.janus = null;
    }

    this.publisherHandle = null;
  }
}
