import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HERDR_BLOCKED_EVENT = "herdr:blocked";

export default function (pi: ExtensionAPI) {
  pi.on("ui_prompt_start", (event) => {
    pi.events.emit(HERDR_BLOCKED_EVENT, {
      active: true,
      label: event.title ?? "Waiting for input",
    });
  });

  pi.on("ui_prompt_end", () => {
    pi.events.emit(HERDR_BLOCKED_EVENT, { active: false });
  });
}
