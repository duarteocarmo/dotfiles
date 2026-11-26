--[[
  Doc's config.
  Single file. Just because.
  ======================
]]
local vim = vim -- suppress lsp warnings [ignore: undefined-global]
local o = vim.opt

o.number = true
o.signcolumn = "yes"
o.relativenumber = true
o.clipboard = ""
o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.expandtab = true
o.wrap = true
o.autoread = true
o.backspace = "indent,eol,start"
if vim.fn.executable("fish") == 1 then
	o.shell = vim.fn.exepath("fish")
end
o.wildmode = { "lastused", "full" }
o.winborder = "rounded"
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.swapfile = false
o.foldmethod = "indent"
o.foldlevelstart = 99
o.termguicolors = true -- Enables 24-bit RGB colors in the terminal
o.smartindent = true -- Automatically inserts an extra level of indentation in some cases
o.smarttab = true -- Makes <Tab> insert 'shiftwidth' number of spaces at the start of a line

local g = vim.g
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1
g.mapleader = " "
g.maplocalleader = " "

local opts = { silent = true }
local map = vim.keymap.set

require("vim._core.ui2").enable({})

-- copy absolute filepath to clipboard
map("n", "<leader>y", function()
	vim.fn.setreg("+", vim.fn.expand("%:p"))
end)

map("n", "<leader>ff", function()
	require("fff").find_files()
end, { desc = "Find files" })
map("n", "<leader>fg", function()
	require("fff").live_grep()
end, { desc = "Search project text" })
-- fff only shows tracked files, so untracked and gitignored files go through fzf
map("n", "<leader>fu", function()
	local skip = [[(^|/)(\.venv[^/]*|venv|node_modules|__pycache__|\.ruff_cache|\.pytest_cache|\.mypy_cache)/|\.DS_Store$]]
	local list = "git ls-files --others | grep -v -E '" .. skip .. "'"
	if vim.fn.executable("fzf") == 0 or vim.fn.systemlist("git rev-parse --is-inside-work-tree")[1] ~= "true" then
		return vim.notify("Untracked search needs fzf and a git repo", vim.log.levels.WARN)
	end
	local out = vim.fn.tempname()
	local buf = vim.api.nvim_create_buf(false, true)
	local width, height = math.floor(vim.o.columns * 0.8), math.floor(vim.o.lines * 0.7)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		title = " Untracked files ",
	})
	vim.fn.jobstart(list .. " | fzf --preview 'head -200 {}' > " .. out, {
		term = true,
		on_exit = function()
			vim.api.nvim_win_close(win, true)
			local picked = vim.fn.filereadable(out) == 1 and vim.fn.readfile(out)[1]
			if picked and picked ~= "" then
				vim.cmd.edit(vim.fn.fnameescape(picked))
			end
		end,
	})
	vim.cmd.startinsert()
end, { desc = "Find untracked and ignored files" })
map("n", "<leader>rr", "<cmd>:restart<cr>")
map("n", "<leader>dd", "<cmd>CodeDiff<cr>")
map({ "n", "v" }, "<Tab>", ":tabnext<CR>", opts)
map({ "n", "v" }, "<S-Tab>", ":tabprev<CR>", opts)
map({ "n", "v" }, "<leader>tx", ":tabclose<CR>", opts)
map({ "n", "v" }, "<leader>gu", "<cmd>GitLink<cr>", opts)
map({ "n", "v" }, "<leader>go", function()
	require("gitlinker").link({ action = require("gitlinker.actions").system })
end, opts)
map({ "n", "v" }, "<leader>pc", ":PrtChatNew popup<CR>", opts)
map({ "n", "v" }, "<leader>pr", ":PrtRewrite<CR>", opts)
map({ "n", "v" }, "<leader>pa", ":PrtAppend<CR>", opts)
map({ "n", "v" }, "<C-k>", function()
	require("conform").format({ async = false, lsp_fallback = true })
end, opts)

vim.api.nvim_create_user_command("ConfigReload", function()
	vim.cmd.source(vim.env.MYVIMRC)
	vim.notify("Config reloaded")
end, { desc = "Reload Neovim config" })
map("n", "<leader>cr", "<cmd>ConfigReload<cr>", opts)

local plugins = {
	"hxueh/beancount.nvim",
	"mason-org/mason-lspconfig.nvim",
	"mason-org/mason.nvim",
	"MeanderingProgrammer/render-markdown.nvim",
	"nathangrigg/vim-beancount",
	"neovim/nvim-lspconfig",
	"nvim-tree/nvim-web-devicons",
	"nvim-tree/nvim-tree.lua",
	"nvim-lualine/lualine.nvim",
	"nvim-treesitter/nvim-treesitter",
	"rachartier/tiny-inline-diagnostic.nvim",
	"sindrets/diffview.nvim",
	"stevearc/conform.nvim",
	"linrongbin16/gitlinker.nvim",
	"karb94/neoscroll.nvim",
	"miikanissi/modus-themes.nvim",
	"rose-pine/neovim",
	"nvim-lua/plenary.nvim",
	"frankroeder/parrot.nvim",
	"dmtrKovalenko/fff.nvim",
	"esmuellert/codediff.nvim",
	"folke/which-key.nvim",
	"lewis6991/gitsigns.nvim",
}
if vim.fn.has("macunix") == 1 then
	table.insert(plugins, "cormacrelf/dark-notify")
end

vim.g.fff = { lazy_sync = true }
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "fff.nvim" and (kind == "install" or kind == "update") then
			if not ev.data.active then
				vim.cmd.packadd("fff.nvim")
			end
			require("fff.download").download_or_build_binary()
		end
	end,
})

vim.pack.add(vim.tbl_map(function(repo)
	return "https://github.com/" .. repo
end, plugins))

require("lualine").setup({
	options = {
		theme = "auto",
		icons_enabled = false,
		component_separators = "",
		section_separators = "",
		globalstatus = true,
	},
	sections = {
		lualine_a = {
			function()
				return ""
			end,
			"mode",
		},
		lualine_b = {},
		lualine_c = { { "filename", path = 1 } },
		lualine_x = { "filetype" },
		lualine_y = {},
		lualine_z = { "location" },
	},
})

require("nvim-tree").setup({
	view = { width = 32 },
	hijack_directories = { enable = false },
	filters = {
		git_ignored = true,
		custom = { "^\\.git$", "^\\.venv$", "^node_modules$", "^__pycache__$", "^\\.DS_Store$" },
	},
	renderer = {
		group_empty = true,
		indent_markers = { enable = true },
		icons = { show = { git = false } },
	},
	update_focused_file = { enable = true },
})
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Explorer toggle" })
map("n", "<leader>E", "<cmd>NvimTreeFindFile<cr>", { desc = "Explorer at current file" })

require("diffview").setup({ use_icons = false })
require("neoscroll").setup({ duration_multiplier = 0.3 })
require("gitlinker").setup()
require("gitsigns").setup({
	linehl = true,
	word_diff = true,
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")
		local function bmap(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
		end
		bmap("]h", function() gitsigns.nav_hunk("next") end, "Next hunk")
		bmap("[h", function() gitsigns.nav_hunk("prev") end, "Prev hunk")
		bmap("<leader>hp", gitsigns.preview_hunk, "Preview hunk")
		bmap("<leader>hr", gitsigns.reset_hunk, "Reset hunk")
		bmap("<leader>hb", gitsigns.blame_line, "Blame line")
		bmap("<leader>hd", gitsigns.preview_hunk_inline, "Show deleted lines inline")
		bmap("<leader>ht", function()
			local enabled = gitsigns.toggle_linehl()
			gitsigns.toggle_word_diff(enabled)
		end, "Toggle line and word highlights")
	end,
})
require("render-markdown").setup({ preset = "obsidian" })
vim.lsp.config("pyright", {
	root_markers = {
		{
			"pyrightconfig.json",
			"pyproject.toml",
			"setup.py",
			"setup.cfg",
			"requirements.txt",
			"Pipfile",
			".venv",
			"venv",
		},
		".git",
	},
	before_init = function(_, config)
		for _, directory in ipairs({ ".venv", "venv" }) do
			local python = vim.fs.joinpath(config.root_dir or vim.fn.getcwd(), directory, "bin", "python")
			if vim.fn.executable(python) == 1 then
				config.settings.python.pythonPath = python
				break
			end
		end
	end,
})
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "rust_analyzer", "pyright" },
})
local parrot_models = {
	"deepseek/deepseek-v4-flash",
	"minimax/minimax-m3",
}
require("parrot").setup({
	providers = {
		openrouter = {
			name = "openrouter",
			api_key = function()
				return vim.trim(vim.fn.system({ "fish", "-lc", 'printf %s "$OPENROUTER_API_KEY"' }))
			end,
			endpoint = "https://openrouter.ai/api/v1/chat/completions",
			params = {
				chat = { temperature = 0.0, top_p = 1 },
				command = { temperature = 0.0, top_p = 1 },
			},
			topic = {
				model = parrot_models[1],
				params = { max_completion_tokens = 64 },
			},
			models = parrot_models,
		},
	},
	toggle_target = "popup",
	enable_preview_mode = false,
})
local bean_file = vim.fn.expand("~/Repos/accounting/duarte.beancount")
if vim.fn.filereadable(bean_file) == 1 then
	require("beancount").setup({
		main_bean_file = bean_file,
		python_path = vim.fn.expand("~/Repos/accounting/.venv/bin/python"),
		auto_format_on_save = false, -- conform owns formatting
		ui = { virtual_text = false }, -- let tiny-inline-diagnostic render (wrapped)
	})
end

require("tiny-inline-diagnostic").setup({
	-- attach on buffer open too, not only LspAttach, so non-LSP
	-- filetypes (beancount) still get inline messages
	options = { overwrite_events = { "LspAttach", "BufWinEnter" } },
})
require("nvim-treesitter").install({ "lua", "rust", "python", "beancount", "markdown", "markdown_inline" })
require("conform").setup({
	formatters_by_ft = {
		python = function(bufnr)
			local conform = require("conform")
			if conform.get_formatter_info("ruff_format", bufnr).available then
				return { "ruff_format", "ruff_fix" }
			end
			return { "isort", "black" }
		end,
		javascript = { "prettierd", "prettier" },
		beancount = { "bean-format" },
		toml = { "taplo" },
		css = { "prettier" },
		htmldjango = { "djlint" },
		lua = { "stylua" },
		json = { "jq" },
		yaml = { "prettier" },
	},
})

-- LSP stuff
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local bufnr = args.buf
		local client = vim.lsp.get_client_by_id(args.data.client_id)

		if client and client.server_capabilities.semanticTokensProvider then
			vim.lsp.semantic_tokens.enable(true, { bufnr = bufnr })
		end

		local opts = { buffer = bufnr, silent = true }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
	end,
})

-- Even nicer highlighting with Treesitter
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		pcall(vim.treesitter.start)
	end,
})

require("modus-themes").setup({
	style = "auto",
	variants = "default",
	styles = {
		comments = { italic = true },
		keywords = { bold = true },
	},
})
-- dark-notify needs macOS
if vim.fn.has("macunix") == 1 then
	require("dark_notify").run({
		schemes = {
			light = { colorscheme = "modus_operandi" },
			dark = { colorscheme = "modus_vivendi" },
		},
	})
else
	vim.o.background = "dark"
	vim.cmd.colorscheme("modus_vivendi")
end

map("n", "<leader>st", function()
	local light = require("modus-themes.config").is_light()
	vim.o.background = light and "dark" or "light"
	vim.cmd.colorscheme(light and "modus_vivendi" or "modus_operandi")
end, { desc = "Switch light/dark theme" })

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermLeave", "BufEnter", "CursorHold", "CursorHoldI" }, {
	callback = function()
		if vim.fn.getcmdwintype() == "" then
			vim.cmd("checktime")
		end
	end,
})

if vim.g.external_edit_timer then
	vim.fn.timer_stop(vim.g.external_edit_timer)
end
vim.g.external_edit_timer = vim.fn.timer_start(1000, function()
	if vim.api.nvim_get_mode().mode == "n" and vim.fn.getcmdwintype() == "" then
		vim.cmd("checktime")
	end
end, { ["repeat"] = -1 })

local function pack_clean()
	local active_plugins = {}
	local unused_plugins = {}

	for _, plugin in ipairs(vim.pack.get()) do
		active_plugins[plugin.spec.name] = plugin.active
	end

	for _, plugin in ipairs(vim.pack.get()) do
		if not active_plugins[plugin.spec.name] then
			table.insert(unused_plugins, plugin.spec.name)
		end
	end

	if #unused_plugins == 0 then
		print("No unused plugins.")
		return
	end

	local choice = vim.fn.confirm("Remove unused plugins?", "&Yes\n&No", 2)
	if choice == 1 then
		vim.pack.del(unused_plugins)
	end
end

vim.keymap.set("n", "<leader>pC", pack_clean)
vim.keymap.set("n", "<leader>pu", vim.pack.update)
