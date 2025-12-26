return {

  {
    "folke/noice.nvim",
    enabled = false,
  },
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
  { "nvimdev/dashboard-nvim", enabled = false },
  { "goolord/alpha-nvim", enabled = false },
  { "akinsho/bufferline.nvim", enabled = false },
  {
    "lukas-reineke/headlines.nvim",
    enabled = false,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",

    opts = {
      -- LazyVim config for treesitter
      indent = { enable = true },
      highlight = { enable = true },
      folds = { enable = true },
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  { "miikanissi/modus-themes.nvim", priority = 1000 },
  { "oonamo/ef-themes.nvim" },
  { "datsfilipe/vesper.nvim" },
  { "projekt0n/github-nvim-theme" },
  { "nyoom-engineering/oxocarbon.nvim" },
  { "yorickpeterse/vim-paper" },
  {
    "LazyVim/LazyVim",
    tag = "v14.13.0",
    opts = {
      colorscheme = "ef-eagle",
    },
  },
  {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- or if using mini.icons/mini.nvim
    -- dependencies = { "nvim-mini/mini.icons" },
    opts = {},
  },
  {
    "cormacrelf/dark-notify",
    config = function()
      local dn = require("dark_notify")

      dn.run({
        schemes = {
          light = {
            background = "light",
            colorscheme = "ef-eagle",
          },
          dark = {
            background = "dark",
            -- colorscheme = "vesper",
            colorscheme = "tokyonight",
          },
        },
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettierd" },
        beancount = { "bean-format" },
        toml = { "taplo" },
        css = { "prettierd" },
        htmldjango = { "djlint" },
        python = { "ruff_format", "ruff_fix" },
      },
    },
    keys = {
      {
        "<C-k>",
        function()
          require("conform").format({ async = false, lsp_fallback = true })
        end,
        desc = "Format file",
      },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      "copilotlsp-nvim/copilot-lsp",
    },
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
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
    end,
  },
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
    },
    config = function()
      vim.g.opencode_opts = {}
      vim.o.autoread = true

      vim.keymap.set({ "n", "x" }, "<leader>oq", function()
        require("opencode").ask("@this: ", { submit = true })
      end, { desc = "Ask opencode" })
      vim.keymap.set({ "n", "x" }, "<leader>oe", function()
        require("opencode").select()
      end, { desc = "Execute opencode action…" })
      vim.keymap.set({ "n", "t" }, "<leader>ot", function()
        require("opencode").toggle()
      end, { desc = "Toggle opencode" })
      vim.keymap.set({ "n", "x" }, "<leader>oar", function()
        return require("opencode").operator("@this ")
      end, { expr = true, desc = "Add range to opencode" })
      vim.keymap.set("n", "<leader>oal", function()
        return require("opencode").operator("@this ") .. "_"
      end, { expr = true, desc = "Add line to opencode" })
    end,
  },
  {
    "robitx/gp.nvim",
    config = function()
      local code_prompt = assert(io.open("/Users/duarteocarmo/.AGENTS.MD", "r")):read("*all")
      local ollama_agents = {}

      -- TODO: Make one for openrouter and ollama as well

      local copilot_models = {
        { name = "claude-sonnet-4.5", model = "claude-sonnet-4.5" },
        { name = "gpt-5-mini", model = "gpt-5-mini" },
        -- { name = "GPT-5.1-Codex", model = "gpt-5.1-codex" },
      }

      for _, config in ipairs(copilot_models) do
        table.insert(ollama_agents, {
          provider = "copilot",
          name = "Copilot - " .. config.name,
          chat = true,
          command = true,
          model = { model = config.model, temperature = config.temperature, top_p = config.top_p },
          system_prompt = code_prompt,
        })
      end

      local conf = {
        default_command_agent = "gpt-5-mini",
        default_chat_agent = "gpt-5-mini",
        providers = {
          ollama = {
            disable = false,
            endpoint = "http://localhost:11434/v1/chat/completions",
            secret = "dummy_secret",
          },
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

        agents = vim.tbl_extend("force", {}, ollama_agents),
      }
      require("gp").setup(conf)
      vim.keymap.set({ "n", "v" }, "<leader>pc", ":GpChatNew popup<CR>")
      vim.keymap.set({ "n", "v" }, "<leader>pr", ":GpRewrite<CR>")
      vim.keymap.set({ "n", "v" }, "<leader>pa", ":GpAppend<CR>")

      -- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
    end,
  },
  {
    "echasnovski/mini.diff",
    config = function()
      local diff = require("mini.diff")
      diff.setup({
        source = diff.gen_source.none(),
      })
    end,
  },
  {
    "saghen/blink.compat",
    opts = {},
    version = not vim.g.lazyvim_blink_main and "*",
  },

  {
    "saghen/blink.cmp",
    tag = "v0.11.0",

    dependencies = {
      { "crispgm/cmp-beancount" },
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",

        config = function()
          local luasnip = require("luasnip")
          require("luasnip.loaders.from_lua").load({
            paths = vim.fn.stdpath("config") .. "/lua/snippets",
          })
        end,
      },
    },
    opts = {
      snippets = { preset = "luasnip" },
      sources = {
        compat = {},
        default = { "lsp", "path", "buffer", "beancount", "snippets" },
        cmdline = {},
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
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        beancount = {
          journal_file = "/Users/duarteocarmo/Repos/accounting/duarte.beancount",
        },
      },
    },
  },
  { "mason-org/mason.nvim", version = "^1.0.0" },
  { "mason-org/mason-lspconfig.nvim", version = "^1.0.0" },
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
      explorer = { enabled = false },
      scroll = { enabled = false },
      picker = {
        win = {
          input = {
            keys = {
              ["<c-x>"] = { "edit_split", mode = { "i", "n" } },
            },
          },
        },
      },
    },
    keys = {
      { "<leader>fg", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>ff", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
    },
  },

  {
    "numToStr/FTerm.nvim",
    cmd = "FTerm",
    keys = {
      { "<leader>tt", "<cmd>lua require('FTerm').toggle()<cr>", desc = "Toggle FTerm", mode = { "n", "v" } },
      { "<Esc>", "<C-\\><C-n><cmd>lua require('FTerm').toggle()<cr>", desc = "Exit FTerm", mode = "t" },
    },
    opts = {
      dimensions = {
        height = 0.8,
        width = 0.8,
      },
      border = "single",
    },
  },

  {
    "stevearc/conform.nvim",
    opts = function()
      require("conform").setup({
        formatters_by_ft = {
          python = function(bufnr)
            if require("conform").get_formatter_info("ruff_format", bufnr).available then
              return { "ruff_format", "ruff_fix" }
            else
              return { "isort", "black" }
            end
          end,
          javascript = { "prettierd", "prettier" },
          beancount = { "bean-format" },
          toml = { "taplo" },
          css = { "prettier" },
          htmldjango = { "djlint" },
        },
      })
    end,
  },
  keys = {
    {
      "<C-k>",
      function()
        require("conform").format({ async = false, lsp_fallback = true })
      end,
      desc = "Format",
      mode = { "n", "v" },
    },
  },

  { "nathangrigg/vim-beancount" },
  { "tpope/vim-fugitive" },
  { "tpope/vim-rhubarb" },
}
