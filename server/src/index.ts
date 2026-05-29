#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { GodotBridge } from "./godot-bridge.js";
import { registerTools } from "./tools.js";

const bridge = new GodotBridge();
bridge.start();

const server = new McpServer({
  name: "godot-mcp",
  version: "0.1.0",
});

registerTools(server, bridge);

function shutdown() {
  bridge.close();
  process.exit(0);
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

const transport = new StdioServerTransport();
await server.connect(transport);
