import { execFile } from "node:child_process";
import { promisify } from "node:util";

import { Type } from "typebox";
import { defineToolPlugin } from "openclaw/plugin-sdk/tool-plugin";

const execFileAsync = promisify(execFile);

const SEARCH_COMMAND =
  "/Users/openclaw/server/scripts/obsidian-search.sh";

const DEFAULT_VAULT_ID = "personal-knowledge";
const DEFAULT_COLLECTION = "obsidian_chunks_v1";
const MAXIMUM_LIMIT = 8;

const resultSchema = Type.Object(
  {
    schema_version: Type.Literal(1),
    query: Type.String(),
    vault_id: Type.String(),
    collection: Type.String(),
    result_count: Type.Integer(),
    results: Type.Array(
      Type.Object(
        {
          rank: Type.Integer(),
          score: Type.Number(),
          title: Type.String(),
          relative_path: Type.String(),
          heading: Type.Union([
            Type.String(),
            Type.Null(),
          ]),
          chunk_text: Type.String(),
          tags: Type.Array(Type.String()),
          document_id: Type.String(),
          chunk_id: Type.String(),
        },
        {
          additionalProperties: false,
        },
      ),
    ),
  },
  {
    additionalProperties: false,
  },
);

export default defineToolPlugin({
  id: "obsidian-retrieval",
  name: "Obsidian Retrieval",
  description:
    "Provides constrained read-only semantic retrieval from approved Obsidian content.",

  tools: (tool) => [
    tool({
      name: "obsidian_search",
      description:
        "Search approved Obsidian knowledge. Returns source paths, headings, text excerpts, tags, and relevance scores. This tool is read-only.",

      optional: true,

      parameters: Type.Object(
        {
          query: Type.String({
            minLength: 1,
            maxLength: 500,
            description:
              "Natural-language question or semantic search query.",
          }),

          limit: Type.Optional(
            Type.Integer({
              minimum: 1,
              maximum: MAXIMUM_LIMIT,
              default: 5,
            }),
          ),

          tag: Type.Optional(
            Type.String({
              minLength: 1,
              maxLength: 100,
            }),
          ),

          relative_path: Type.Optional(
            Type.String({
              minLength: 1,
              maxLength: 500,
            }),
          ),
        },
        {
          additionalProperties: false,
        },
      ),

      async execute(params) {
        const args = [
          params.query,
          "--vault-id",
          DEFAULT_VAULT_ID,
          "--collection",
          DEFAULT_COLLECTION,
          "--limit",
          String(params.limit ?? 5),
        ];

        if (params.tag) {
          args.push("--tag", params.tag);
        }

        if (params.relative_path) {
          args.push(
            "--relative-path",
            params.relative_path,
          );
        }

        const { stdout } = await execFileAsync(
          SEARCH_COMMAND,
          args,
          {
            encoding: "utf8",
            timeout: 30_000,
            maxBuffer: 1024 * 1024,
            windowsHide: true,
          },
        );

        return JSON.parse(stdout);
      },
    }),
  ],
});