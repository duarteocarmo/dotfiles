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
o.shell = "/opt/homebrew/bin/fish"
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
	"cormacrelf/dark-notify",
	"hxueh/beancount.nvim",
	"mason-org/mason-lspconfig.nvim",
	"mason-org/mason.nvim",
	"MeanderingProgrammer/render-markdown.nvim",
	"nathangrigg/vim-beancount",
	"neovim/nvim-lspconfig",
	"nvim-tree/nvim-web-devicons",
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
}

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

require("diffview").setup({ use_icons = false })
require("neoscroll").setup({ duration_multiplier = 0.3 })
require("gitlinker").setup()
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
require("beancount").setup({
	main_bean_file = "/Users/duarteocarmo/Repos/accounting/duarte.beancount",
	python_path = "/Users/duarteocarmo/Repos/accounting/.venv/bin/python",
	auto_format_on_save = false, -- conform owns formatting
	ui = { virtual_text = false }, -- let tiny-inline-diagnostic render (wrapped)
})

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
require("dark_notify").run({
	schemes = {
		light = { colorscheme = "modus_operandi" },
		dark = { colorscheme = "modus_vivendi" },
	},
})

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
