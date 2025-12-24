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
o.colorcolumn = "100"
o.completeopt = { "menuone", "noselect", "popup" }
o.wildmode = { "lastused", "full" }
o.pumheight = 15
o.laststatus = 0
o.winborder = "rounded"
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.swapfile = false
o.foldmethod = "indent"
o.foldlevelstart = 99

--  Show/hide trail chars
-- o.list = true
-- o.listchars = {
-- 	tab = "  ",
-- 	trail = "·",
-- 	nbsp = "␣",
-- }

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
map("n", "<leader>fg", "<cmd>Pick grep_live<cr>")

map({ "n", "v" }, "<C-k>", function()
	require("conform").format({ async = false, lsp_fallback = true })
end, opts)

vim.pack.add({
	"https://github.com/sindrets/diffview.nvim",
	"https://github.com/tpope/vim-fugitive",
	"https://github.com//mason-org/mason.nvim",
	"https://github.com//neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason-lspconfig.nvim",
	"https://github.com/nvim-mini/mini.completion",
	"https://github.com/nvim-mini/mini.pick",
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/nexxeln/vesper.nvim",
	"https://github.com/numToStr/FTerm.nvim",
	"https://github.com/stevearc/conform.nvim",
})

vim.cmd("colorscheme vesper")

require("vim._extui").enable({}) -- https://github.com/neovim/neovim/pull/27855
require("diffview").setup({ use_icons = false })
require("mason").setup()
require("mason-lspconfig").setup({ ensure_installed = { "lua_ls", "rust_analyzer" } })
require("mini.completion").setup()
require("mini.pick").setup()
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
