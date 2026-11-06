import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const inputRecord = "\u001b]7501;state=blocked:id=pi-input:kind=question:app=pi:msg=V2FpdGluZyBmb3IgaW5wdXQ=\u0007";
const clearRecord = "\u001b]7501;state=clear:id=pi-input\u0007";

export default function (pi: ExtensionAPI) {
  let active = false;

  function clear() {
    if (!active) return;
    process.stdout.write(clearRecord);
    active = false;
  }

  pi.on("ui_prompt_start", (event, ctx) => {
    if (event.kind !== "custom" || !ctx.hasUI || !process.stdout.isTTY || active) return;
    process.stdout.write(inputRecord);
    active = true;
  });

  pi.on("ui_prompt_end", clear);
  pi.on("session_shutdown", clear);
}
