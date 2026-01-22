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

type PtyExitEvent = { exitCode: number; signal?: number };
type PtyListener<T> = (event: T) => void;
type PtyHandle = {
  pid: number;
  write: (data: string | Buffer) => void;
  onData: (listener: PtyListener<string>) => void;
  onExit: (listener: PtyListener<PtyExitEvent>) => void;
};
type PtySpawn = (
  file: string,
  args: string[] | string,
  options: {
    name?: string;
    cols?: number;
    rows?: number;
    cwd?: string;
    env?: Record<string, string>;
  },
) => PtyHandle;

function coerceEnv(env: NodeJS.ProcessEnv): Record<string, string> {
  const entries = Object.entries(env).filter(([, value]) => typeof value === "string");
  return Object.fromEntries(entries) as Record<string, string>;
}

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
        const baseEnv = coerceEnv(process.env);
        const env = params.env ? { ...baseEnv, ...params.env } : baseEnv;

        const timeoutMs =
          typeof params.timeoutSec === "number" && params.timeoutSec > 0
            ? Math.floor(params.timeoutSec * 1000)
            : undefined;

        const output: { stdout: string; stderr: string } = {
          stdout: "",
          stderr: "",
        };

        const ptyModule = (await import("@lydell/node-pty")) as unknown as {
          spawn?: PtySpawn;
          default?: { spawn?: PtySpawn };
        };
        const spawnPty = ptyModule.spawn ?? ptyModule.default?.spawn;
        if (!spawnPty) {
          throw new Error("PTY support is unavailable (node-pty spawn not found).");
        }
        const pty = spawnPty(shell, args, {
          cwd,
          env,
          name: process.env.TERM ?? "xterm-256color",
          cols: 120,
          rows: 30,
        });

        const killProcess = () => {
          try {
            if (pty.pid) {
              process.kill(pty.pid, "SIGKILL");
            }
          } catch {
            // ignore
          }
        };

        const result = await new Promise<{
          ok: boolean;
          code?: number | null;
          signal?: NodeJS.Signals | number | null;
          error?: string;
        }>((resolvePromise) => {
          let timedOut = false;
          let timeoutHandle: NodeJS.Timeout | undefined;

          if (timeoutMs) {
            timeoutHandle = setTimeout(() => {
              timedOut = true;
              killProcess();
            }, timeoutMs);
          }

          const finalize = (
            code: number | null,
            signal: NodeJS.Signals | number | null,
          ) => {
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
          };

          pty.onData((data) => {
            output.stdout += data.toString();
          });
          pty.onExit((event) => {
            const exitSignal = event.signal && event.signal !== 0 ? event.signal : null;
            finalize(event.exitCode ?? null, exitSignal);
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
