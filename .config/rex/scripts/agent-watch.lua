-- Watch every agent in ~/.local/state/rex/orchestrator.json and ping the orchestrator pane
-- when one stops working. One script on this Mac's server polls all hosts with rex.server().
-- agent-launch starts it in the background, bound to the orchestrator session (it stops when that session closes):
--   rex do -s ORCHESTRATOR_SESSION ~/.config/rex/scripts/agent-watch.lua
-- Blocked or error pings at once. Idle or done pings after `settle` seconds of quiet.
-- The same state doesn't ping twice within a minute. Agents whose session is gone are dropped.

local terminal = "com.superlogical.terminal"
local state_path = (os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state") .. "/rex/orchestrator.json"
local poll_seconds = rex.args.poll or 3
local settle_seconds = rex.args.settle or 20

local servers = {}   -- host label -> server table
local attached = {}  -- host .. session -> true
local watched = {}   -- agent name -> { identity, state, quiet_since, pinged_at, children }
local last_errors = {} -- agent name -> last logged error, so a down host logs once

local function load_state()
	local file = io.open(state_path, "r")
	if not file then return { agents = {} } end
	local state = rex.json.decode(file:read("*a"))
	file:close()
	state.agents = state.agents or {}
	return state
end

local function save_state(state)
	local file = assert(io.open(state_path .. ".tmp", "w"))
	assert(file:write(rex.json.encode(state, { indent = true })))
	assert(file:close())
	assert(os.rename(state_path .. ".tmp", state_path))
end

local function server_for(host)
	if host == "local" then return rex end
	servers[host] = servers[host] or rex.server(host)
	return servers[host]
end

local function forget_connection(host)
	servers[host] = nil
	for key in pairs(attached) do
		if key:sub(1, #host + 1) == host .. "|" then attached[key] = nil end
	end
end

-- Returns the root state and child records, or nil and an error. "gone" means the session closed.
local function read_status(agent)
	local server = server_for(agent.host)
	local key = agent.host .. "|" .. agent.session
	if not attached[key] then
		local _, err = server.call("session.attach", { session_id = agent.session })
		if err then
			local sessions = server.call("session.list", {})
			if sessions and not rex.json.encode(sessions):find(agent.session, 1, true) then return nil, "gone" end
			forget_connection(agent.host)
			return nil, err
		end
		attached[key] = true
	end
	local status, err = server.block.call(terminal, "program_status", { session_id = agent.session, block_id = agent.block })
	if err then
		forget_connection(agent.host)
		local sessions = server_for(agent.host).call("session.list", {})
		if sessions and not rex.json.encode(sessions):find(agent.session, 1, true) then return nil, "gone" end
		return nil, err
	end
	local root, children = nil, {}
	for _, record in ipairs(status.records or {}) do
		if record.id then children[record.id] = record.state else root = record.state end
	end
	return root or "not reporting", children
end

local function ping(name, agent, entry, state, notify)
	if os.time() - (entry.pinged_at[state] or 0) < 60 then return true end
	local message = string.format(
		"/skill:rex-orchestrator [agent-watch] %s/%s: agent is %s. Read its pane (%s) and report to Duarte.",
		agent.host, name, state, agent.block)
	for _, keys in ipairs({ { "send", message }, { "send-key", "Enter" } }) do
		local result, err = rex.exec({ "rex", "-S", notify.server, "-s", notify.session, "-b", notify.block, keys[1], keys[2] })
		if not (result and result.ok) then
			rex.log("notify failed, retrying next poll: " .. tostring(err or result.stderr))
			return false
		end
	end
	entry.pinged_at[state] = os.time()
	rex.exec({ "osascript", "-e",
		string.format("display notification %q with title %q", name .. " is " .. state, "Rex agent-watch") })
	rex.log("pinged: " .. agent.host .. "/" .. name .. " " .. state)
	return true
end

local function check(name, agent, notify)
	local state, children = read_status(agent)
	if state == nil then return children end
	-- A new agent (or a name reused for another pane) starts from its current state. Only an
	-- alert pings at once, so a pane where pi hasn't reported yet doesn't ping "not reporting".
	local identity = agent.host .. "|" .. agent.session .. "|" .. agent.block
	local entry = watched[name]
	if not entry or entry.identity ~= identity then
		entry = { identity = identity, state = "new", pinged_at = {}, children = {} }
		watched[name] = entry
		rex.log("watching " .. agent.host .. "/" .. name .. " (state " .. state .. ")")
		if state ~= "blocked" and state ~= "error" then entry.state = state end
	end

	-- Pi reports a root record plus child records such as "pi-input" for questions.
	for id, child_state in pairs(children) do
		local alert = child_state == "blocked" or child_state == "error"
		if alert and child_state ~= entry.children[id] and not ping(name, agent, entry, child_state, notify) then
			child_state = entry.children[id]
		end
		entry.children[id] = child_state
	end
	for id in pairs(entry.children) do
		if not children[id] then entry.children[id] = nil end
	end

	if state ~= entry.state then
		local was_working = entry.state == "working"
		if state == "blocked" or state == "error" then
			if not ping(name, agent, entry, state, notify) then return end
		end
		entry.state, entry.quiet_since = state, nil
		if was_working and (state == "idle" or state == "done") then
			entry.quiet_since = os.time()
		end
	elseif entry.quiet_since and os.time() - entry.quiet_since >= settle_seconds then
		if ping(name, agent, entry, state, notify) then entry.quiet_since = nil end
	end
end

local function tick()
	local state = load_state()
	if not state.notify then return end
	local gone = {}
	for name, agent in pairs(state.agents) do
		local ok, err = pcall(check, name, agent, state.notify)
		err = not ok and tostring(err) or err
		err = err and err:gsub("control%-%d+", "control") or err
		if err == "gone" then
			table.insert(gone, name)
		elseif err and err ~= last_errors[name] then
			rex.log(name .. ": " .. err)
		end
		last_errors[name] = err
	end
	for name in pairs(watched) do
		if not state.agents[name] then watched[name] = nil end
	end
	if #gone > 0 then
		local fresh = load_state()
		for _, name in ipairs(gone) do
			local current = fresh.agents[name]
			if current and current.session == state.agents[name].session then
				fresh.agents[name], watched[name] = nil, nil
				rex.log("session closed, stopped watching " .. name)
			end
		end
		save_state(fresh)
	end
end

tick()
rex.every(poll_seconds, tick)
