import type { JanusJS } from "janus-gateway";

type PublisherInfo = {
  id?: number;
  display?: string;
};

type StartPublisherArgs = {
  janusRoomId: number;
  onLocalStream?: (stream: MediaStream) => void;
};

type PublisherMessageArgs = {
  msg: JanusJS.Message;
  jsep: JanusJS.JSEP;
  resolve: () => void;
  reject: (err: any) => void;
};

type PublisherOfferArgs = {
  resolve: () => void;
  reject: (err: any) => void;
};

export class JanusPublisher {
  private janus: any = null;
  private publisherHandle!: JanusJS.PluginHandle;
  private opaqueId = `lincr-${Math.random().toString(36).slice(2)}`;
  constructor(janus: any) {
    this.janus = janus;
  }

  async start(args: StartPublisherArgs) {
    const { janusRoomId, onLocalStream } = args;
    const localStream = new MediaStream();

    await new Promise<void>((resolve, reject) => {
      this.janus.attach({
        plugin: "janus.plugin.videoroom",
        opaqueId: this.opaqueId,

        success: (pluginHandle: JanusJS.PluginHandle) => {
          this.publisherHandle = pluginHandle;
          this.joinRoom(janusRoomId);
        },

        error: (err: any) => reject(err),

        onmessage: (msg: JanusJS.Message, jsep: JanusJS.JSEP) => {
          this.handleMessage({
            msg: msg,
            jsep: jsep,
            resolve: resolve,
            reject: reject,
          });
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

  private joinRoom(janusRoomId: number): void {
    this.publisherHandle.send({
      message: {
        request: "join",
        ptype: "publisher",
        room: janusRoomId,
      },
    });
  }

  private handleMessage(args: PublisherMessageArgs): void {
    const { msg, jsep, resolve, reject } = args;
    const event = msg?.videoroom;

    if (event === "joined") {
      this.createPublisherOffer({ resolve, reject });
      return;
    }

    if (event === "event" && msg.publishers) {
      console.log("Some event with publishers");
    }

    if (jsep) {
      this.publisherHandle.handleRemoteJsep({ jsep });
    }
  }

  private createPublisherOffer(args: PublisherOfferArgs): void {
    const { resolve, reject } = args;

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
  }
}
