local terminal = "com.superlogical.terminal"
local state_dir = rex.args.state_dir or (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state") .. "/rex"
local state_path = state_dir .. "/session-names-local.json"
local created, err = rex.exec({ "mkdir", "-p", state_dir })
assert(created and created.ok, err or "Cannot create session naming state directory")

local function load_auto_labels()
	local file = io.open(state_path, "r")
	if not file then
		return {}
	end
	local contents = file:read("*a")
	file:close()
	local labels = rex.json.decode(contents)
	assert(type(labels) == "table", "Invalid session naming state: " .. state_path)
	return labels
end

local auto_labels = load_auto_labels()
local pending_updates = {}

local function save_auto_labels()
	local file = assert(io.open(state_path .. ".tmp", "w"))
	assert(file:write(rex.json.encode(auto_labels)))
	assert(file:close())
	assert(os.rename(state_path .. ".tmp", state_path))
end

local function first_block_in(layout)
	if layout.block_id then
		return layout.block_id
	end
	if layout.split then
		return first_block_in(layout.split.before)
	end
end

local function first_tab_block(view)
	local first_window = view.windows and view.windows[1]
	if not first_window then
		return nil
	end
	for _, layer in ipairs(first_window.layers) do
		if layer.kind == "tiled" and layer.layout then
			return first_block_in(layer.layout)
		end
	end
end

local function path_from_pwd_url(url)
	if not url:match("^file://") then
		return url
	end
	local path = url:gsub("^file://[^/]*", "")
	return (path:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

local function list_git_entries(session_id, block_id, dir)
	return rex.block.call(terminal, "list_dir", {
		session_id = session_id,
		block_id = block_id,
		path = dir,
		files = true,
		prefix = ".git",
	})
end

local function has_git_entry(listing)
	for _, entry in ipairs(listing.entries or {}) do
		if entry.name == ".git" then
			return true
		end
	end
	return false
end

local function label_for(session_id, block_id, path)
	local listing = list_git_entries(session_id, block_id, path)
	local home = listing and listing.home
	if path == home then
		return "~"
	end

	local dir = path
	while listing and dir ~= "" and dir ~= home do
		if has_git_entry(listing) then
			path = dir
			break
		end
		dir = dir:match("^(.*)/[^/]*$") or ""
		listing = dir ~= "" and list_git_entries(session_id, block_id, dir)
	end
	return path:match("([^/]+)/?$") or path
end

local function update_session(session_id)
	local view = rex.session.view({ session_id = session_id })
	if not view then
		return
	end

	local current_label = view.label or ""
	local is_manual = current_label ~= "" and current_label ~= auto_labels[session_id]
	if is_manual then
		return
	end

	local block_id = first_tab_block(view)
	if not block_id then
		return
	end
	local args = { session_id = session_id, block_id = block_id }
	local pwd = rex.block.call(terminal, "pwd", args)
	local path = pwd and pwd.pwd and path_from_pwd_url(pwd.pwd)
	if not path then
		local process = rex.block.call(terminal, "process", args)
		path = process and process.child and process.child.cwd
	end
	if not path or path == "" then
		return
	end

	local label = label_for(session_id, block_id, path)
	if label == current_label then
		return
	end
	local renamed, err = rex.session.set_label({ session_id = session_id, label = label })
	assert(renamed, err)
	auto_labels[session_id] = label
	save_auto_labels()
end

local function schedule_update(session_id)
	if not session_id then
		return
	end
	if pending_updates[session_id] then
		pending_updates[session_id]:cancel()
	end
	pending_updates[session_id] = rex.after(0.3, function()
		pending_updates[session_id] = nil
		update_session(session_id)
	end)
end

rex.on("terminal.pwd_changed", function(ctx)
	schedule_update(ctx.session_id)
end)

rex.on("terminal.process_changed", function(ctx)
	schedule_update(ctx.session_id)
end)

rex.on("session_view_changed", function(ctx)
	schedule_update(ctx.session_id)
end)

rex.on("session_created", function(ctx, ev)
	auto_labels[ev.session.session_id] = ev.session.label
	save_auto_labels()
	schedule_update(ev.session.session_id)
end)

rex.on("session_destroyed", function(ctx, ev)
	if pending_updates[ev.session_id] then
		pending_updates[ev.session_id]:cancel()
		pending_updates[ev.session_id] = nil
	end
	auto_labels[ev.session_id] = nil
	save_auto_labels()
end)

local sessions, err = rex.call("session.list")
assert(sessions, err)
for _, session in ipairs(sessions.sessions or {}) do
	schedule_update(session.session_id)
end
