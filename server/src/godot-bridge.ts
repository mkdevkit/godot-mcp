import { WebSocketServer, WebSocket } from "ws";

const DEFAULT_PORT = 6505;
const HEARTBEAT_MS = 10_000;
const REQUEST_TIMEOUT_MS = 30_000;

interface PendingRequest {
  resolve: (value: unknown) => void;
  reject: (reason: Error) => void;
  timer: ReturnType<typeof setTimeout>;
}

export class GodotBridge {
  private wss: WebSocketServer | null = null;
  private client: WebSocket | null = null;
  private pending = new Map<number, PendingRequest>();
  private nextId = 1;
  private heartbeatTimer: ReturnType<typeof setInterval> | null = null;
  readonly port: number;

  constructor(port = Number(process.env.GODOT_MCP_PORT ?? DEFAULT_PORT)) {
    this.port = port;
  }

  start(): void {
    if (this.wss) return;

    this.wss = new WebSocketServer({ port: this.port, host: "127.0.0.1" });
    this.wss.on("connection", (ws) => {
      this.client = ws;
      console.error(`[godot-mcp] Godot editor connected on port ${this.port}`);

      ws.on("message", (data) => this.onMessage(data.toString()));
      ws.on("close", () => {
        if (this.client === ws) {
          this.client = null;
          console.error("[godot-mcp] Godot editor disconnected");
        }
        this.rejectAll(new Error("Godot editor disconnected"));
      });
      ws.on("error", () => ws.close());
    });

    this.heartbeatTimer = setInterval(() => {
      if (this.client?.readyState === WebSocket.OPEN) {
        this.client.send(JSON.stringify({ jsonrpc: "2.0", method: "ping", params: {} }));
      }
    }, HEARTBEAT_MS);

    console.error(`[godot-mcp] WebSocket server listening on ws://127.0.0.1:${this.port}`);
  }

  get connected(): boolean {
    return this.client?.readyState === WebSocket.OPEN;
  }

  async call(method: string, params: Record<string, unknown> = {}): Promise<unknown> {
    if (!this.connected || !this.client) {
      throw new Error(
        "Godot editor not connected. Open your project in Godot and enable the Godot MCP plugin."
      );
    }

    const id = this.nextId++;
    const message = JSON.stringify({ jsonrpc: "2.0", id, method, params });
    this.client.send(message);

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Request timeout: ${method}`));
      }, REQUEST_TIMEOUT_MS);
      this.pending.set(id, { resolve, reject, timer });
    });
  }

  close(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
    this.rejectAll(new Error("Server shutting down"));
    this.client?.close();
    this.client = null;
    this.wss?.close();
    this.wss = null;
  }

  private onMessage(text: string): void {
    let msg: {
      id?: number;
      method?: string;
      result?: unknown;
      error?: { message?: string; code?: number; data?: unknown };
    };

    try {
      msg = JSON.parse(text);
    } catch {
      return;
    }

    if (msg.method === "pong") return;

    if (msg.id !== undefined) {
      const pending = this.pending.get(msg.id);
      if (!pending) return;
      this.pending.delete(msg.id);
      clearTimeout(pending.timer);
      if (msg.error) {
        pending.reject(new Error(msg.error.message ?? "Unknown Godot error"));
      } else {
        pending.resolve(msg.result ?? {});
      }
    }
  }

  private rejectAll(error: Error): void {
    for (const [id, pending] of this.pending) {
      clearTimeout(pending.timer);
      pending.reject(error);
      this.pending.delete(id);
    }
  }
}
