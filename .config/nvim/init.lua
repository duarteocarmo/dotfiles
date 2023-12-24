-- Install packer
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
local is_bootstrap = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
	is_bootstrap = true
	vim.fn.execute("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
	vim.cmd([[packadd packer.nvim]])
end

local mykey

require("packer").startup(function(use)
	-- Package manager
	use("wbthomason/packer.nvim")
	-- Useful status updates for LSP
	--
	use({
		"j-hui/fidget.nvim",
		tag = "legacy",
		config = function()
			require("fidget").setup({
				-- options
			})
		end,
	})

	use({ -- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		requires = {
			-- Automatically install LSPs to stdpath for neovim
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
	})

	use({ -- Autocompletion
		"hrsh7th/nvim-cmp",
		requires = { "hrsh7th/cmp-nvim-lsp", "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip" },
	})

	use({ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		run = function()
			pcall(require("nvim-treesitter.install").update({ with_sync = true }))
		end,
	})

	use({ -- Additional text objects via treesitter
		"nvim-treesitter/nvim-treesitter-textobjects",
		after = "nvim-treesitter",
	})
	use({
		"folke/trouble.nvim",
		config = function()
			require("trouble").setup({
				{
					icons = false,
					fold_open = "v", -- icon used for open folds
					fold_closed = ">", -- icon used for closed folds
					indent_lines = false, -- add an indent guide below the fold icons
					signs = {
						-- icons / text used for a diagnostic
						error = "error",
						warning = "warn",
						hint = "hint",
						information = "info",
					},
					use_diagnostic_signs = true, -- enabling this will use the signs defined in your lsp client
				},
			})
		end,
	})

	-- Git related plugins
	use("tpope/vim-fugitive")
	use("tpope/vim-rhubarb")
	use("lewis6991/gitsigns.nvim")

	-- Color schemes
	use("sjl/badwolf") -- Badwolf theme
	use("navarasu/onedark.nvim") -- Theme inspired by Atom
	use("tanvirtin/monokai.nvim") -- Monokai Theme
	use("projekt0n/github-nvim-theme") -- Github theme
	use("haishanh/night-owl.vim") -- Nightowl theme
	use("EdenEast/nightfox.nvim") -- Nightfox theme
	use("rose-pine/neovim") -- Rose pine
	use("Lokaltog/vim-monotone")
	use("rebelot/kanagawa.nvim")
	use("rakr/vim-two-firewatch")
	use("sainnhe/sonokai")
	use("habamax/vim-habamax")
	use("sainnhe/gruvbox-material")
	use("folke/tokyonight.nvim")
	use("tomasr/molokai")
	use({ "ellisonleao/gruvbox.nvim" })
	use({
		"loctvl842/monokai-pro.nvim",
		config = function()
			require("monokai-pro").setup({
				filter = "spectrum",
			})
		end,
	})

	-- Interface
	use("nvim-lualine/lualine.nvim") -- Fancier statusline
	use({
		"lukas-reineke/indent-blankline.nvim",
		tag = "v2.20.8",
	}) -- Add indentation guides even on blank lines
	use("tpope/vim-sleuth") -- Detect tabstop and shiftwidth automatically
	use("cormacrelf/dark-notify") -- Notifies dark mode
	use({
		"folke/which-key.nvim",
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			require("which-key").setup({
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			})
		end,
	})

	-- Code related
	use("sbdchd/neoformat") -- Code formatting
	use("stevearc/conform.nvim") -- Code formatting
	use("tpope/vim-commentary") -- gcc for commenting
	-- use("jiangmiao/auto-pairs") -- auto close brackets
	use({
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	})
	use("tpope/vim-surround") -- auto close brackets

	-- AI
	use("Exafunction/codeium.vim") -- codeium
	use("David-Kunz/gen.nvim")
	-- packer.nvim
	use({
		"robitx/gp.nvim",
		config = function()
			-- local file = io.open("/Users/duarteocarmo/.openai_api_key", "r")
			-- if file then -- Check if the file was opened successfully
			-- 	mykey = file:read() -- Read the first line
			-- 	file:close() -- Close the file
			-- else
			-- 	print("Failed to open the file") -- Handle the case where the file couldn't be opened
			-- end

			require("gp").setup({
				-- openai_api_key = mykey,
				openai_api_key = { "cat", "/Users/duarteocarmo/.openai_api_key" },
			})
		end,
	})

	-- File support
	use("Glench/Vim-Jinja2-Syntax") -- Jinja 2
	use("nathangrigg/vim-beancount") -- Beancount files
	use("NoahTheDuke/vim-just") -- Just file support

	-- Fuzzy Finder (files, lsp, etc)
	use({ "nvim-telescope/telescope.nvim", branch = "0.1.x", requires = { "nvim-lua/plenary.nvim" } })

	-- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
	use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make", cond = vim.fn.executable("make") == 1 })

	-- Linting
	use("mfussenegger/nvim-lint")

	-- Add custom plugins to packer from /nvim/lua/custom/plugins.lua
	local has_plugins, plugins = pcall(require, "custom.plugins")
	if has_plugins then
		plugins(use)
	end

	if is_bootstrap then
		require("packer").sync()
	end
end)

-- When we are bootstrapping a configuration, it doesn't
-- make sense to execute the rest of the init.lua.
-- You'll need to restart nvim, and then it will work.
if is_bootstrap then
	print("==================================")
	print("    Plugins are being installed")
	print("    Wait until Packer completes,")
	print("       then restart nvim")
	print("==================================")
	return
end

-- Automatically source and re-compile packer whenever you save this init.lua
local packer_group = vim.api.nvim_create_augroup("Packer", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
	command = "source <afile> | PackerCompile",
	group = packer_group,
	pattern = vim.fn.expand("$MYVIMRC"),
})

-- [[ Setting options ]]
-- See `:help vim.o`
--
vim.g.codeium_filetypes = {
	beancount = false,
	-- typescript = true,
}

-- Copilot (not using anymore)
-- vim.g.copilot_no_tab_map = true
-- vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })

-- Codeium
-- let g:codeium_enabled = v:false
vim.g.codeium_enabled = true
vim.api.nvim_set_keymap("i", "<C-J>", "codeium#Accept()", { silent = true, expr = true })
vim.api.nvim_set_keymap("i", "<C-;>", "codeium#CycleCompletions", { silent = true, expr = true })

-- Go files indentation is stupid
vim.api.nvim_command("autocmd FileType go setlocal shiftwidth=4 tabstop=4")

-- Background light
-- vim.o.background = 'dark'

-- Set relative line numbers
vim.o.relativenumber = true

vim.cmd([[set smartindent]])

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = "yes"

-- Folding
vim.o.foldlevel = 99
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"

-- Set colorscheme
vim.o.termguicolors = true
local my_theme_dark = "github_dark_tritanopia"
local my_theme_light = "github_light_tritanopia"
vim.g.colors_name = my_theme_dark

-- -- Respect transparency
-- vim.cmd [[ highlight Normal guibg=none ]]

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- [[ Basic Keymaps ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.g.neoformat_enabled_python = { "black", "isort" }
vim.g.neoformat_enabled_html = { "prettierd" }
vim.g.neoformat_enabled_htmldjango = { "djlint" }
vim.g.neoformat_enabled_jinja = { "djlint" }
vim.g.neoformat_enabled_css = { "prettier" }
vim.g.neoformat_enabled_css = { "prettier" }
vim.g.neoformat_try_node_exe = 1
vim.g.neoformat_run_all_formatters = 1

-- My keymaps
-- vim.keymap.set("n", "<C-k>", ":Neoformat<Cr>")

-- Conform
require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { { "ruff_format", "black" } },
		javascript = { { "prettierd", "prettier" } },
		toml = { "taplo" },
		rust = { "rustfmt", "leptosfmt" },
		go = { "goimports", "gofmt" },
	},
})

-- vim.keymap.set("n", "<C-k>", require("conform").format, { desc = "Conform" })
vim.keymap.set("n", "<C-k>", function()
	require("conform").format({ lsp_fallback = true })
	-- vim.lsp.buf.format({ async = true })
	if vim.bo.filetype == "python" then
		vim.lsp.buf.code_action({
			context = {
				only = { "source.fixAll.ruff" },
			},
			apply = true,
		})
	end
end, { desc = "FixStuff" })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {

	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

-- Set lualine as statusline
-- See `:help lualine.txt`
require("lualine").setup({
	options = {
		icons_enabled = false,
		theme = "auto",
		component_separators = "|",
		section_separators = "",
	},
})

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help indent_blankline.txt`
require("indent_blankline").setup({
	char = "┊",
	show_trailing_blankline_indent = false,
})

-- AI helpers config

-- require("gp").setup({
-- 	openai_api_key = openai_api_key,
-- })

vim.keymap.set({ "n", "v" }, "<leader>oo", ":Gen<CR>")
vim.keymap.set({ "n", "v" }, "<leader>oa", ":Gen Ask<CR>")
vim.keymap.set({ "n", "v" }, "<leader>oc", ":Gen Code<CR>")
vim.keymap.set({ "n", "v" }, "<leader>ot", ":Gen Text<CR>")

require("gen").prompts = {
	Ask = { prompt = "$input", replace = false, model = "orca2" },
	Code = {
		prompt = "$input \n\n ```$filetype\n$text\n```",
		model = "codellama:7b-instruct",
		replace = false,
	},
	Text = {
		prompt = "$input \n\n ```\n$text\n```",
		model = "zephyr",
		replace = false,
	},
}

-- GpChat

-- Gitsigns
-- See `:help gitsigns.txt`
require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require("telescope").setup({
	defaults = {
		file_ignore_patterns = {
			"node_modules/*",
			".env/*",
		},
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
	},
})

pcall(require("telescope").load_extension, "fzf")

-- See `:help telescope.builtin`
vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles, { desc = "[?] Find recently opened files" })
vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>/", function()
	-- You can pass additional configuration to telescope to change theme, layout, etc.
	require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "[/] Fuzzily search in current buffer]" })

vim.keymap.set("n", "<leader>sf", require("telescope.builtin").find_files, { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>sh", require("telescope.builtin").git_files, { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })
-- vim.keymap.set("n", "<leader>sw", require("telescope.builtin").grep_string, { desc = "[S]earch current [W]ord" })
-- vim.keymap.set('n', '<leader>sg', require('fzf-lua').live_grep, { desc = '[S]earch by [G]rep' })
-- vim.keymap.set('n', '<leader>sg', require('fzf-lua').live_grep({ cmd = "git grep --line-number --column --color=always" }))

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
require("nvim-treesitter.configs").setup({
	-- Add languages to be installed here that you want installed for treesitter
	ensure_installed = { "c", "cpp", "go", "lua", "python", "rust", "typescript", "vimdoc", "beancount", "r" },

	highlight = { enable = true },
	indent = { enable = true, disable = { "python" } },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<c-space>",
			node_incremental = "<c-space>",
			scope_incremental = "<c-s>",
			node_decremental = "<c-backspace>",
		},
	},
	textobjects = {
		select = {
			enable = true,
			lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]]"] = "@class.outer",
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
			},
		},
		swap = {
			enable = true,
			swap_next = {
				["<leader>a"] = "@parameter.inner",
			},
			swap_previous = {
				["<leader>A"] = "@parameter.inner",
			},
		},
	},
})

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

-- LSP settings.
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
	-- NOTE: Remember that lua is a real programming language, and as such it is possible
	-- to define small helper and utility functions so you don't have to repeat yourself
	-- many times.
	--
	-- In this case, we create a function that lets us more easily define mappings specific
	-- for LSP related items. It sets the mode, buffer and description for us each time.
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

	nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
	nmap("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
	nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
	nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
	nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

	-- See `:help K` for why this keymap
	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	-- nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

	-- Lesser used LSP functionality
	nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
	nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	nmap("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		if vim.lsp.buf.format then
			vim.lsp.buf.format()
		elseif vim.lsp.buf.formatting then
			vim.lsp.buf.formatting()
		end
	end, { desc = "Format current buffer with LSP" })
end

-- Setup mason so it can manage external tooling
require("mason").setup()

-- vim.diagnostic.config({
-- 	virtual_text = false,
-- 	signs = true,
-- 	float = {
-- 		border = "single",
-- 		format = function(diagnostic)
-- 			return string.format(
-- 				"%s (%s) [%s]",
-- 				diagnostic.message,
-- 				diagnostic.source,
-- 				diagnostic.code or diagnostic.user_data.lsp.code
-- 			)
-- 		end,
-- 	},
-- })

-- Enable the following language servers
-- Feel free to add/remove any LSPs that you want here. They will automatically be installed
local servers = {
	"pyright",
	"clangd",
	"rust_analyzer",
	"tsserver",
	"lua_ls",
	"beancount",
	"gopls",
	"ruff_lsp",
	"tailwindcss",
	"cssls",
	"beancount",
}

-- Ensure the servers above are installed
require("mason-lspconfig").setup({
	ensure_installed = servers,
})

-- nvim-cmp supports additional completion capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

for _, lsp in ipairs(servers) do
	require("lspconfig")[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

-- Example custom configuration for lua
--
-- Make runtime files discoverable to the server
local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

require("lspconfig").lua_ls.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT)
				version = "LuaJIT",
				-- Setup your lua path
				path = runtime_path,
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = { library = vim.api.nvim_get_runtime_file("", true) },
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = { enable = false },
		},

		["rust-analyzer"] = {
			procMacro = {
				ignored = {
					leptos_macro = {
						-- optional: --
						-- "component",
						"server",
					},
				},
			},
		},
	},
})

require("lspconfig").beancount.setup({
	{ "beancount-language-server", "--stdio" },
	init_options = {
		journalFile = "/Users/duarteocarmo/Repos/accounting/duarte.beancount",
	},
})

require("lspconfig").tailwindcss.setup({})

require("lint").linters_by_ft = {
	python = { "ruff" },
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	callback = function()
		require("lint").try_lint()
	end,
})

-- dark mode
local dn = require("dark_notify")

dn.run({
	schemes = {
		light = {
			colorscheme = my_theme_light,
			background = "light",
		},
		dark = {
			colorscheme = my_theme_dark,
			background = "dark",
		},
	},
})

-- if you only want these mappings for toggle term use  instead
vim.cmd("autocmd! TermOpen term://*toggleterm#*  lua set_terminal_keymaps()")

-- nvim-cmp setup
local cmp = require("cmp")

cmp.setup({
	mapping = cmp.mapping.preset.insert({
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<CR>"] = cmp.mapping.confirm({
			-- behavior = cmp.ConfirmBehavior.Replace,
			behavior = cmp.ConfirmBehavior.Insert,
			select = true,
		}),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = {
		{ name = "nvim_lsp" },
	},
	snippet = { expand = function() end },
})
