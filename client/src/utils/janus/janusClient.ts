import adapter from "webrtc-adapter";
(window as any).adapter = adapter;
import Janus from "janus-gateway";
import type { JanusJS } from "janus-gateway";
// import type { StartPublisherArgs } from "../../types/janus";

const janusSecret = import.meta.env.VITE_JANUS_API_SECRET;

type StartPublisherArgs = {
  janusRoomId: number;
  // onPublisherJoined: (publishers: PublisherInfo[])
};

type PublisherMessageArgs = {
  msg: any;
  jsep: JanusJS.JSEP;
  pluginHandle: JanusJS.PluginHandle;
  resolve: () => void;
  reject: (err: any) => void;
};

type PublisherOfferArgs = {
  pluginHandle: any;
  resolve: () => void;
  reject: (err: any) => void;
};

export class JanusClient {
  private janus: any = null;
  private publisherHandle!: JanusJS.PluginHandle;
  private opaqueId = `lincr-${Math.random().toString(36).slice(2)}`;

  /* initializes Janus object for the first time */
  async init(): Promise<void> {
    await new Promise<void>((resolve) => {
      Janus.init({
        debug: true,
        callback: () => resolve(),
      });
    });
  }

  /* connects to Janus server by creating Janus sessions per tab*/
  async connect(janusServerName: string): Promise<void> {
    await new Promise<void>((resolve, reject) => {
      let isHandshakeComplete = false;

      this.janus = new Janus({
        server: janusServerName,
        apisecret: janusSecret,
        success: () => {
          isHandshakeComplete = true;
          resolve();
        },
        error: (err: any) => {
          if (!isHandshakeComplete) {
            reject(err);
          } else {
            //connection live, handle runtime crash
            console.log("Runtime crash occured in connect() for JanusClient");
          }
        },
        destroyed: () => {
          this.cleanupSession();
        },
      });
    });
  }

  async startPublisher(args: StartPublisherArgs) {
    const { janusRoomId } = args;
    const localStream = new MediaStream();

    await new Promise<void>((resolve, reject) => {
      this.janus.attach({
        plugin: "janus.plugin.videoroom",
        opaqueId: this.opaqueId,

        success: (pluginHandle: any) => {
          this.publisherHandle = pluginHandle;
          this.joinPublisherRoom(pluginHandle, janusRoomId);
        },

        error: (err: any) => reject(err),

        onmessage: (msg: any, jsep: JanusJS.JSEP) => {
          this.handlePublisherMessage({
            msg: msg,
            jsep: jsep,
            pluginHandle: this.publisherHandle,
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
        },

        oncleanup: () => {},
      });
    });
  }

  private joinPublisherRoom(pluginHandle: any, janusRoomId: number): void {
    pluginHandle.send({
      message: {
        request: "join",
        ptype: "publisher",
        room: janusRoomId,
      },
    });
  }

  private handlePublisherMessage(args: PublisherMessageArgs) {
    const { msg, jsep, pluginHandle, resolve, reject } = args;
    const event = msg?.videoroom;

    if (event === "joined") {
      this.createPublisherOffer({ pluginHandle, resolve, reject });
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
    const { pluginHandle, resolve, reject } = args;

    pluginHandle.createOffer({
      tracks: [
        { type: "audio", capture: true, recv: false },
        { type: "video", capture: true, recv: false },
      ],
      success: (offerJsep: any) => {
        pluginHandle.send({
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

  private cleanupSession() {
    if (this.janus) {
      try {
        this.janus.destroy();
      } catch (e) {}
      this.janus = null;
    }
  }
}
