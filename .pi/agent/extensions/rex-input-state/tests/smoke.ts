import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("rex-input-smoke", {
    description: "Show a blocking UI to verify Rex needs-input reporting",
    handler: async (_args, ctx) => {
      if (ctx.mode !== "tui") return;
      await ctx.ui.custom((_tui, _theme, keybindings, done) => ({
        render: (width) => ["Press Enter to finish or Escape to cancel".slice(0, width)],
        handleInput: (data) => {
          if (keybindings.matches(data, "tui.select.confirm") || keybindings.matches(data, "tui.select.cancel")) done();
        },
        invalidate() {},
      }));
    },
  });
}
