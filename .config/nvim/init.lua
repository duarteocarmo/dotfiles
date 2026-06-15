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
o.wrap = false
o.autoread = true
o.backspace = "indent,eol,start"
o.shell = "/opt/homebrew/bin/fish"
o.wildmode = { "lastused", "full" }
o.pumheight = 15
o.winborder = "rounded"
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.swapfile = false
o.foldmethod = "indent"
o.foldlevelstart = 99
o.shortmess:append("c") -- Prevents showing extra messages when using completion
o.termguicolors = true -- Enables 24-bit RGB colors in the terminal
o.smartindent = true -- Automatically inserts an extra level of indentation in some cases
o.smarttab = true -- Makes <Tab> insert 'shiftwidth' number of spaces at the start of a line

local g = vim.g
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
	local in_git = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true")
	if in_git then
		require("mini.pick").builtin.files({ tool = "git" })
	else
		require("mini.pick").builtin.files({ tool = "rg" }) -- or 'fd'
	end
end)
map("n", "<leader>fg", "<cmd>Pick grep_live<cr>")
map("n", "<leader>rr", "<cmd>:restart<cr>")
map("n", "<leader>gg", "<cmd>:LazyGit<cr>")
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
	"L3MON4D3/LuaSnip",
	"cormacrelf/dark-notify",
	"hxueh/beancount.nvim",
	"kdheepak/lazygit.nvim",
	"mason-org/mason-lspconfig.nvim",
	"mason-org/mason.nvim",
	"nathangrigg/vim-beancount",
	"neovim/nvim-lspconfig",
	"nvim-mini/mini.nvim",
	"nvim-treesitter/nvim-treesitter",
	"rachartier/tiny-inline-diagnostic.nvim",
	"saghen/blink.cmp",
	"saghen/blink.lib",
	"sindrets/diffview.nvim",
	"stevearc/conform.nvim",
	"linrongbin16/gitlinker.nvim",
	"karb94/neoscroll.nvim",
	"miikanissi/modus-themes.nvim",
	"rose-pine/neovim",
	"nvim-lua/plenary.nvim",
	"frankroeder/parrot.nvim",
	"Exafunction/windsurf.nvim",
	"sindrets/diffview.nvim",
}

vim.pack.add(vim.tbl_map(function(repo)
	return "https://github.com/" .. repo
end, plugins))

require("diffview").setup({ use_icons = false })
require("neoscroll").setup({ duration_multiplier = 0.3 })
require("gitlinker").setup()
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "rust_analyzer", "pyright" },
})
require("mini.pick").setup()
require("mini.icons").setup()
require("mini.statusline").setup({})
require("mini.diff").setup()
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
--[[ pi-ide disabled
plugin: "ldelossa/pi-ide.nvim"
map("n", "<leader>ps", "<cmd>PiStatus<cr>", opts)

require("pi-ide").setup({
	auto_start = true,
	claude_code_compatibility = false,
	log_level = "warn",
	suggestion = {
		auto_trigger = true,
		default_keys = false,
		model = nil,
	},
})

-- <Tab>: accept ghost text if present, else a real <Tab>
local pi_suggest = require("pi-ide.suggestion")
map("i", "<Tab>", function()
	if pi_suggest.has_active_suggestion() then
		pi_suggest.accept_all()
		return ""
	end
	return "<Tab>"
end, { expr = true, silent = true })
map("i", "<M-\\>", pi_suggest.trigger, opts)
map("i", "<C-]>", pi_suggest.dismiss, opts)
]]

require("blink.cmp").setup({
	keymap = {
		preset = "default",
		["<Tab>"] = { "select_next", "fallback" },
		["<S-Tab>"] = { "select_prev", "fallback" },
		["<CR>"] = { "accept", "fallback" },
	},
	appearance = {
		nerd_font_variant = "mono",
	},
	completion = {
		documentation = { auto_show = false, auto_show_delay_ms = 500 },
	},
	sources = {
		default = { "lsp", "path", "snippets", "beancount" },
		providers = {
			beancount = {
				name = "beancount",
				module = "beancount.completion.blink",
				score_offset = 100,
				opts = {
					trigger_characters = { ":", "#", "^", '"', " " },
				},
			},
		},
	},
	snippets = { preset = "luasnip" },
	fuzzy = { implementation = "lua" },
	signature = { enabled = true },
})

require("beancount").setup({
	main_bean_file = "/Users/duarteocarmo/Repos/accounting/duarte.beancount",
	python_path = "/Users/duarteocarmo/Repos/accounting/.venv/bin/python",
	auto_format_on_save = false, -- conform owns formatting
	ui = { virtual_text = false }, -- let tiny-inline-diagnostic render (wrapped)
})

require("luasnip.loaders.from_vscode").lazy_load({
	paths = { vim.fn.stdpath("config") .. "/snippets" },
})

require("tiny-inline-diagnostic").setup({
	-- attach on buffer open too, not only LspAttach, so non-LSP
	-- filetypes (beancount) still get inline messages
	options = { overwrite_events = { "LspAttach", "BufWinEnter" } },
})
require("nvim-treesitter").install({ "lua", "rust", "python", "beancount" })
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
require("codeium").setup({
	enable_cmp_source = false,
	virtual_text = {
		enabled = true,
		filetypes = {
			beancount = false,
		},
		key_bindings = {
			accept = "<C-j>",
			next = "<M-]>",
			prev = "<M-[>",
		},
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
