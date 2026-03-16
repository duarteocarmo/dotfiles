--[[
  Doc's config.
  Single file. Just because.
  ======================
]]
local vim = vim -- suppress lsp warnings
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

local g = vim.g
g.mapleader = " "
g.maplocalleader = " "

local opts = { silent = true }
local map = vim.keymap.set

map({ "n", "v" }, "<leader>tt", "<cmd>lua require('FTerm').toggle()<cr>", opts)
map({ "t" }, "<Esc>", "<C-\\><C-n><cmd>lua require('FTerm').toggle()<cr>", opts)
map("n", "<leader>y", function() -- copy relative filepath to clipboard
	vim.fn.setreg("+", vim.fn.expand("%"))
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
map({ "n", "v" }, "<leader>pc", ":GpChatNew popup<CR>", opts)
map({ "n", "v" }, "<leader>pr", ":GpRewrite<CR>", opts)
map({ "n", "v" }, "<leader>pa", ":GpAppend<CR>", opts)
map({ "n", "v" }, "<C-k>", function()
	require("conform").format({ async = false, lsp_fallback = true })
end, opts)

local plugins = {
	"L3MON4D3/LuaSnip",
	"cormacrelf/dark-notify",
	"crispgm/cmp-beancount",
	"kdheepak/lazygit.nvim",
	"mason-org/mason-lspconfig.nvim",
	"mason-org/mason.nvim",
	"nathangrigg/vim-beancount",
	"neovim/nvim-lspconfig",
	"numToStr/FTerm.nvim",
	"nvim-mini/mini.nvim",
	"nvim-treesitter/nvim-treesitter",
	"rachartier/tiny-inline-diagnostic.nvim",
	"saghen/blink.cmp",
	"saghen/blink.compat",
	"sindrets/diffview.nvim",
	"stevearc/conform.nvim",
	"linrongbin16/gitlinker.nvim",
	"karb94/neoscroll.nvim",
	"oskarnurm/koda.nvim",
	"nvim-lua/plenary.nvim",
	"Exafunction/windsurf.nvim",
	-- "jnz/studio98",
	-- "metalelf0/base16-black-metal-scheme",
	-- "p00f/alabaster.nvim",
}

vim.pack.add(vim.tbl_map(function(repo)
	return "https://github.com/" .. repo
end, plugins))

require("vim._extui").enable({}) -- https://github.com/neovim/neovim/pull/27855
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
				module = "blink.compat.source",
				opts = {
					account = "/Users/duarteocarmo/Repos/accounting/duarte.beancount",
				},
			},
		},
	},
	snippets = { preset = "luasnip" },
	fuzzy = { implementation = "lua" },
	signature = { enabled = true },
})

require("luasnip.loaders.from_vscode").lazy_load({
	paths = { vim.fn.stdpath("config") .. "/snippets" },
})

require("tiny-inline-diagnostic").setup()
require("nvim-treesitter").install({ "lua", "rust", "python", "beancount" })
require("FTerm").setup({
	border = "single",
	dimensions = {
		height = 0.9,
		width = 0.9,
	},
})

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
local beancount_journal = "/Users/duarteocarmo/Repos/accounting/duarte.beancount"

vim.lsp.config.beancount = {
	init_options = {
		journal_file = beancount_journal,
		formatting = {
			prefix_width = 30,
			currency_column = 60,
			number_currency_spacing = 1,
		},
	},
}
vim.lsp.enable("beancount")

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

require("koda").setup({ cache = true })
require("dark_notify").run({
	schemes = {
		light = {
			colorscheme = "koda",
		},
		dark = {
			colorscheme = "koda",
		},
	},
})

vim.g.maplocalleader = " "

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

vim.keymap.set("n", "<leader>pc", pack_clean)
vim.keymap.set("n", "<leader>pu", vim.pack.update)

require("codeium").setup({
	enable_cmp_source = false,
	virtual_text = {
		enabled = true,
		key_bindings = {
			accept = "<C-j>",
			next = "<M-]>",
			prev = "<M-[>",
		},
	},
})
