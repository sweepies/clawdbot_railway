# Exec Interactive Plugin

Adds an `exec_i` tool that runs commands through a **login + interactive** shell
(e.g. `bash -l -i -c <cmd>`) so your shell rc files load.

## Tool name
- `exec_i`

## Parameters
- `command` (string, required): shell command to run.
- `cwd` (string, optional): working directory.
- `timeoutSec` (number, optional): timeout in seconds.
- `env` (record<string,string>, optional): extra env vars to merge.
- `shell` ("bash" | "sh", optional): default is `bash`.
- `login` (boolean, optional): default `true`.
- `interactive` (boolean, optional): default `true`.

## Load it
Place this folder under one of the plugin discovery paths (or add it to
`plugins.load.paths`) and restart the gateway.

Common locations:
- `~/.clawdbot/extensions/exec-interactive-plugin/`
- `<workspace>/.clawdbot/extensions/exec-interactive-plugin/`

## Example tool call
```json
{
  "command": "echo $SHELL && which node",
  "cwd": "."
}
```

## Notes
- This does **not** override the core `exec` tool (plugin tool names cannot clash).
- The tool is registered as **optional**; if you use a tool allowlist, include
  `exec_i` in it.
- `@lydell/node-pty` is a native module; ensure your deployment allows native builds
  (for example, pnpm `allow-build-scripts` + `pnpm rebuild @lydell/node-pty`).
