local prefix = "ctrl+b"

local bindings = {
	{ "h", "pane.focus", { direction = "left" } },
	{ "j", "pane.focus", { direction = "down" } },
	{ "k", "pane.focus", { direction = "up" } },
	{ "l", "pane.focus", { direction = "right" } },
	{ "shift+5", "pane.split", { direction = "right" } },
	{ "shift+'", "pane.split", { direction = "down" } },
	{ "z", "pane.zoom" },
	{ "x", "close_pane_or_tab" },

	{ "c", "client.tab.new" },
	{ "shift+7", "client.tab.close" },
	{ "n", "client.tab.next" },
	{ "p", "client.tab.previous" },
	{ "tab", "client.tab.next" },
	{ "shift+tab", "client.tab.previous" },
	{ "shift+l", "client.tab.next" },
	{ "shift+h", "client.tab.previous" },

	{ "shift+n", "session.new" },
	{ "s", "session.switch" },
	{ "shift+4", "session.rename" },
	{ "shift+0", "session.next" },
	{ "shift+9", "session.previous" },

	{ "m", "client.host.switch" },

	{ prefix, "pane.send_key", { key = prefix } },
}

local function window_block_count(view, block_id)
	for _, window in ipairs(view.windows) do
		local block_ids = {}
		local has_block = false
		for _, layer in ipairs(window.layers) do
			for _, block in ipairs(layer.blocks) do
				table.insert(block_ids, block.block_id)
				has_block = has_block or block.block_id == block_id
			end
		end
		if has_block then
			return #block_ids
		end
	end
	return 0
end

rex.action({
	name = "close_pane_or_tab",
	title = "Close Pane or Tab",
	run = function(ctx, args)
		local view = rex.session.view({})
		if view and window_block_count(view, ctx.block_id) <= 1 then
			rex.client.queue("client.tab.close")
		else
			rex.client.queue("pane.close")
		end
	end,
})

for _, binding in ipairs(bindings) do
	rex.bind(prefix .. ">" .. binding[1], binding[2], binding[3])
end

local navigate_timeout_seconds = 1
local navigate_token_path = (os.getenv("TMPDIR") or "/tmp/") .. "rex-navigate-token"
local navigate_bindings = {
	{ "shift+j", "navigate_tab_next", "Next Tab", "client.tab.next" },
	{ "shift+k", "navigate_tab_previous", "Previous Tab", "client.tab.previous" },
	{ "alt+shift+j", "navigate_tab_forward", "Move Tab Forward", "client.tab.move.forward" },
	{ "alt+shift+k", "navigate_tab_backward", "Move Tab Backward", "client.tab.move.backward" },
}

local function exit_navigate_after_pause(client_id)
	local token = os.time() .. "-" .. math.random(1, 1000000000)
	local token_file = io.open(navigate_token_path, "w")
	token_file:write(token)
	token_file:close()
	rex.exec.start({
		"sh",
		"-c",
		'sleep "$1"; [ "$(cat "$2")" = "$3" ] && PATH="$HOME/.local/bin:$PATH" rex -C "$4" do client.mode.exit',
		"sh",
		tostring(navigate_timeout_seconds),
		navigate_token_path,
		token,
		client_id,
	}, { detach = true, stdout = false, stderr = false })
end

for _, binding in ipairs(navigate_bindings) do
	local key, name, title, client_action = unpack(binding)
	rex.action({
		name = name,
		title = "Navigate: " .. title,
		category = "Navigate",
		run = function(ctx, args)
			rex.client.queue(client_action)
			rex.client.queue("client.mode.enter", { name = "navigate" })
			exit_navigate_after_pause(ctx.client_id)
		end,
	})
	rex.bind("navigate/" .. key, name)
	rex.bind(prefix .. ">" .. key, name)
end
