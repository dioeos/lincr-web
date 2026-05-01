import type { JanusJS } from "janus-gateway";
import type { PublisherInfo } from "../../types/janus";

type StartSubscriberArgs = {
  janusRoomId: number;
};

type SubscriberMessageArgs = {
  msg: JanusJS.Message;
  jsep: JanusJS.JSEP;
  resolve: () => void;
  reject: (err: any) => void;
  janusRoomId: number;
};

export class JanusSubscriber {
  private janus: any = null;
  private publisherHandle!: JanusJS.PluginHandle;
  private opaqueId = `sub-lincr-${Math.random().toString(36).slice(2)}`;

  constructor(janus: any) {
    this.janus = janus;
  }

  async start(args: StartSubscriberArgs) {
    const { janusRoomId } = args;

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
            janusRoomId: janusRoomId,
          });
        },
      });
    });
  }

  private joinRoom(janusRoomId: number): void {
    /* publishers and subscribers all initially join as publishers
     *  and will later create subscriber handles
     */
    this.publisherHandle.send({
      message: {
        request: "join",
        ptype: "publisher",
        room: janusRoomId,
      },
    });
  }

  private handleMessage(args: SubscriberMessageArgs): void {
    const { msg, jsep, resolve, reject, janusRoomId } = args;
    const event = msg?.videoroom;

    if (event === "joined") {
      this.getJanusRoomPublishers(janusRoomId)
        .then((publishers) => {
          resolve();
        })
        .catch(reject);

      return;
    }

    if (event === "event" && msg.publishers) {
    }
  }

  private getJanusRoomPublishers(
    janusRoomId: number,
  ): Promise<PublisherInfo[]> {
    return new Promise((resolve, reject) => {
      this.publisherHandle.send({
        message: {
          request: "listparticipants",
          room: janusRoomId,
        },

        success: (resp: any) => {
          const participants = resp?.participants ?? [];

          const publishers = participants
            .filter((p: any) => p.publisher && p.id)
            .map((p: any) => ({
              id: p.id,
              display: p.display,
            }));

          resolve(publishers);
        },
        error: (err: any) => reject(err),
      });
    });
  }
}
