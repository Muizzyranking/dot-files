// Holds a systemd suspend-inhibitor lock while this opencode session is
// actively working, releases it when idle. Works regardless of how many
// opencode instances you run or what port they're on — each instance's
// plugin manages its own lock, keyed by process id.

import type { Plugin } from "@opencode-ai/plugin"
import { execFile } from "node:child_process"

const INHIBIT_SCRIPT = "/home/YOUR_USER/bin/agent-inhibit.sh"
const NAME = `opencode-${process.pid}`

const BUSY_EVENTS = new Set([
  "session.created",
  "message.updated",
  "tool.execute.before",
])

function inhibit(action: "start" | "stop") {
  execFile(INHIBIT_SCRIPT, [action, NAME], () => {})
}

export const SuspendInhibitPlugin: Plugin = async () => {
  return {
    event: async ({ event }) => {
      // DEBUG: log events
      // require("node:fs").appendFileSync("/tmp/opencode-events.log", event.type + "\n")

      if (event.type === "session.idle") {
        inhibit("stop")
        return
      }
      if (BUSY_EVENTS.has(event.type)) {
        inhibit("start")
      }
    },
  }
}
