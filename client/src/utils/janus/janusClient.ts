import adapter from "webrtc-adapter";
(window as any).adapter = adapter;
import Janus from "janus-gateway";

const janusSecret = import.meta.env.VITE_JANUS_API_SECRET;

export class JanusClient {
  private janus: any = null;

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

  /* destroys existing Janus connection object */
  public cleanupSession() {
    if (this.janus) {
      try {
        this.janus.destroy();
      } catch (e) {}
      this.janus = null;
    }
  }

  public getSession(): any {
    if (!this.janus) return;
    return this.janus;
  }
}
