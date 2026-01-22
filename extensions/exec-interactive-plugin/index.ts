import { spawn } from "node:child_process";
import { resolve } from "node:path";

import { Type } from "@sinclair/typebox";
import type { ClawdbotPluginApi } from "clawdbot/plugin-sdk";

const ExecInteractiveSchema = Type.Object({
  command: Type.String({ description: "Shell command to run." }),
  cwd: Type.Optional(Type.String({ description: "Working directory." })),
  timeoutSec: Type.Optional(Type.Number({ description: "Timeout in seconds." })),
  env: Type.Optional(
    Type.Record(Type.String(), Type.String(), {
      description: "Environment variables to merge in.",
    }),
  ),
  shell: Type.Optional(
    Type.Union([Type.Literal("bash"), Type.Literal("sh")], {
      description: "Shell to use (default: bash).",
    }),
  ),
  login: Type.Optional(
    Type.Boolean({
      description: "If true, run as login shell (default: true).",
    }),
  ),
  interactive: Type.Optional(
    Type.Boolean({
      description: "If true, run as interactive shell (default: true).",
    }),
  ),
});

type ExecInteractiveParams = {
  command: string;
  cwd?: string;
  timeoutSec?: number;
  env?: Record<string, string>;
  shell?: "bash" | "sh";
  login?: boolean;
  interactive?: boolean;
};

function buildShellArgs(params: ExecInteractiveParams) {
  const login = params.login ?? true;
  const interactive = params.interactive ?? true;

  if (params.shell === "sh") {
    return ["-c", params.command];
  }

  const flags: string[] = [];
  if (login) flags.push("-l");
  if (interactive) flags.push("-i");

  return [...flags, "-c", params.command];
}

export default function register(api: ClawdbotPluginApi) {
  api.registerTool(
    {
      name: "exec_i",
      label: "Interactive Exec",
      description:
        "Executes a shell command with login/interactive mode so shell rc files are sourced.",
      parameters: ExecInteractiveSchema,
      async execute(_toolCallId: string, params: ExecInteractiveParams) {
        const startedAt = Date.now();
        const shell = params.shell ?? "bash";
        const args = buildShellArgs(params);

        const cwd = params.cwd ? resolve(params.cwd) : process.cwd();
        const env = {
          ...process.env,
          ...(params.env ?? {}),
        };

        const timeoutMs =
          typeof params.timeoutSec === "number" && params.timeoutSec > 0
            ? Math.floor(params.timeoutSec * 1000)
            : undefined;

        const output: { stdout: string; stderr: string } = {
          stdout: "",
          stderr: "",
        };

        const child = spawn(shell, args, {
          cwd,
          env,
          stdio: ["ignore", "pipe", "pipe"],
        });

        const result = await new Promise<{
          ok: boolean;
          code?: number | null;
          signal?: NodeJS.Signals | null;
          error?: string;
        }>((resolvePromise) => {
          let timedOut = false;
          let timeoutHandle: NodeJS.Timeout | undefined;

          if (timeoutMs) {
            timeoutHandle = setTimeout(() => {
              timedOut = true;
              try {
                child.kill("SIGKILL");
              } catch {
                // ignore
              }
            }, timeoutMs);
          }

          child.stdout?.on("data", (buf) => {
            output.stdout += buf.toString();
          });
          child.stderr?.on("data", (buf) => {
            output.stderr += buf.toString();
          });

          child.on("error", (err) => {
            if (timeoutHandle) clearTimeout(timeoutHandle);
            resolvePromise({ ok: false, error: String(err) });
          });

          child.on("close", (code, signal) => {
            if (timeoutHandle) clearTimeout(timeoutHandle);
            if (timedOut) {
              resolvePromise({
                ok: false,
                code,
                signal,
                error: `Command timed out after ${params.timeoutSec}s`,
              });
              return;
            }
            resolvePromise({ ok: code === 0, code, signal });
          });
        });

        const durationMs = Date.now() - startedAt;
        const details = {
          ...result,
          durationMs,
          cwd,
          shell,
          args,
        };

        const text = [
          result.ok ? "OK" : "FAILED",
          output.stdout?.trim() ? `\n\nstdout:\n${output.stdout}` : "",
          output.stderr?.trim() ? `\n\nstderr:\n${output.stderr}` : "",
        ].join("");

        return {
          content: [{ type: "text", text }],
          details,
        };
      },
    },
    { optional: true },
  );
}
