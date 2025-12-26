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
o.signcolumn = "yes"
o.backspace = "indent,eol,start"
o.shell = "/opt/homebrew/bin/fish"
o.completeopt = { "menuone", "noselect", "popup" }
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

map("n", "<leader>ff", "<cmd>Pick files<cr>")
map("n", "<leader>rr", "<cmd>:restart<cr>")
map("n", "<leader>fg", "<cmd>Pick grep_live<cr>")
map("n", "<leader>gg", "<cmd>:LazyGit<cr>")
map({ "n", "v" }, "<leader>pc", ":GpChatNew popup<CR>", opts)
map({ "n", "v" }, "<leader>pr", ":GpRewrite<CR>", opts)
map({ "n", "v" }, "<leader>pa", ":GpAppend<CR>", opts)

map({ "n", "v" }, "<C-k>", function()
	require("conform").format({ async = false, lsp_fallback = true })
end, opts)

local plugins = {
	"mason-org/mason.nvim",
	"neovim/nvim-lspconfig",
	"mason-org/mason-lspconfig.nvim",
	"numToStr/FTerm.nvim",
	"nvim-mini/mini.nvim",
	"nvim-treesitter/nvim-treesitter",
	"sindrets/diffview.nvim",
	"stevearc/conform.nvim",
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
	"zbirenbaum/copilot.lua",
	"copilotlsp-nvim/copilot-lsp",
	"rachartier/tiny-inline-diagnostic.nvim",
	"kdheepak/lazygit.nvim",
	"robitx/gp.nvim",
}

vim.pack.add(vim.tbl_map(function(repo)
	return "https://github.com/" .. repo
end, plugins))

vim.cmd("colorscheme default")

require("vim._extui").enable({}) -- https://github.com/neovim/neovim/pull/27855
require("diffview").setup({ use_icons = false })
require("mason").setup()
require("mason-lspconfig").setup({ ensure_installed = { "lua_ls", "rust_analyzer" } })
require("mini.completion").setup()
require("mini.pick").setup()
require("mini.statusline").setup({})
require("mini.diff").setup()
require("tiny-inline-diagnostic").setup()
require("copilot").setup({
	nes = {
		enabled = false, -- Not nice.
		keymap = {
			accept_and_goto = "<leader>p",
			accept = false,
			dismiss = "<Esc>",
		},
	},
	suggestion = {
		enabled = true,
		auto_trigger = true,
		keymap = {
			accept = "<C-J>",
		},
	},
	filetypes = {
		["*"] = true,
		beancount = false,
		sh = function()
			if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "^%.env") then
				return false
			end
			return true
		end,
	},
})
require("nvim-treesitter").install({ "lua", "rust", "python" })
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
	},
})
local code_prompt = assert(io.open(os.getenv("HOME") .. "/.AGENTS.MD", "r")):read("*all")
require("gp").setup({
	default_command_agent = "gpt-5-mini",
	default_chat_agent = "gpt-5-mini",
	providers = {
		copilot = {
			disable = false,
			endpoint = "https://api.githubcopilot.com/chat/completions",
			secret = {
				"bash",
				"-c",
				"cat ~/.config/github-copilot/apps.json | sed -e 's/.*oauth_token...//;s/\".*//'",
			},
		},
	},
	agents = {
		{
			provider = "copilot",
			name = "Copilot - claude-sonnet-4.5",
			chat = true,
			command = true,
			model = { model = "claude-sonnet-4.5" },
			system_prompt = code_prompt,
		},
		{
			provider = "copilot",
			name = "Copilot - gpt-5-mini",
			chat = true,
			command = true,
			model = { model = "gpt-5-mini" },
			system_prompt = code_prompt,
		},
	},
})
vim.lsp.config.beancount = {
	cmd = { "beancount-language-server", "--stdio" },
	filetypes = { "beancount" },
	root_markers = { ".git" },
	settings = {
		journal_file = os.getenv("HOME") .. "/Repos/accounting/duarte.beancount",
	},
}
vim.lsp.enable("beancount")
