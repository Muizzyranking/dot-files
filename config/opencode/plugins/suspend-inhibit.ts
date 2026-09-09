// Holds a systemd suspend-inhibitor lock while this opencode session is
// actively working, releases it when idle. Works regardless of how many
// opencode instances you run or what port they're on — each instance's
// plugin manages its own lock, keyed by process id.

import type { Plugin } from "@opencode-ai/plugin";
import { execFile, execFileSync } from "node:child_process";

const INHIBIT_SCRIPT = "/home/muizzyranking/dot-files/bin/inhibit";
const NAME = `opencode-${process.pid}`;

function inhibit(action: "start" | "stop") {
  execFile(INHIBIT_SCRIPT, [action, NAME], () => {});
}

let cleaned = false;
function inhibitSyncStop() {
  if (cleaned) return;
  cleaned = true;
  try {
    execFileSync(INHIBIT_SCRIPT, ["stop", NAME], { stdio: "ignore" });
  } catch {
  }
}
process.on("exit", inhibitSyncStop);
process.on("SIGINT", () => {
  inhibitSyncStop();
  process.exit(130);
});
process.on("SIGTERM", () => {
  inhibitSyncStop();
  process.exit(143);
});

export const SuspendInhibitPlugin: Plugin = async () => {
  return {
    event: async ({ event }) => {
      // DEBUG: log events
      // require("node:fs").appendFileSync("/tmp/opencode-events.log", JSON.stringify(event) + "\n")

      if (event.type === "session.status") {
        const status = (event as any).properties?.status?.type;
        if (status === "busy") inhibit("start");
        if (status === "idle") inhibit("stop");
        return;
      }

      if (event.type === "session.idle") {
        inhibit("stop");
        return;
      }

      // if (event.type === "tool.execute.before") {
      //   inhibit("start");
      // }
    },
  };
};
