import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { GodotBridge } from "./godot-bridge.js";
import { TOOL_DEFINITIONS, type ToolParamDef } from "./tool-manifest.js";

function textResult(data: unknown, isError = false) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }],
    isError,
  };
}

function buildSchema(params: ToolParamDef[] = []): Record<string, z.ZodTypeAny> {
  const schema: Record<string, z.ZodTypeAny> = {};
  for (const p of params) {
    let field: z.ZodTypeAny;
    switch (p.type) {
      case "number":
        field = z.number();
        break;
      case "boolean":
        field = z.boolean();
        break;
      case "array":
        field = z.array(z.any());
        break;
      case "record":
        field = z.record(z.string());
        break;
      default:
        field = p.enum ? z.enum(p.enum as [string, ...string[]]) : z.string();
    }
    if (p.description) field = field.describe(p.description);
    if (!p.required) field = field.optional();
    schema[p.name] = field;
  }
  return schema;
}

export function registerTools(server: McpServer, bridge: GodotBridge): void {
  for (const def of TOOL_DEFINITIONS) {
    const schema = buildSchema(def.params);
    server.tool(def.name, def.description, schema, async (args) => {
      try {
        const result = await bridge.call(def.method, args as Record<string, unknown>);
        return textResult(result);
      } catch (e) {
        return textResult({ error: (e as Error).message }, true);
      }
    });
  }
  console.error(`[godot-mcp] Registered ${TOOL_DEFINITIONS.length} MCP tools`);
}
