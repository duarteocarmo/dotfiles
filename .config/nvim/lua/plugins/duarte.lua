return {
  {
    "miikanissi/modus-themes.nvim",
    priority = 1000,
    config = function()
      require("modus-themes").setup({
        style = "auto",
        variant = "tinted", -- Theme comes in four variants `default`, `tinted`, `deuteranopia`, and `tritanopia`
      })
    end,
  },
  {
    "oonamo/ef-themes.nvim",
    opts = {
      light = "ef-light", -- Ef-theme to select for light backgrounds
      dark = "ef-dark", -- Ef-theme to select for dark backgrounds
    },
  },
  {
    "LazyVim/LazyVim",
    tag = "v14.13.0",
    opts = {
      colorscheme = "ef-theme",
    },
  },
  {
    "cormacrelf/dark-notify",
    config = function()
      local dn = require("dark_notify")

      dn.run({
        schemes = {
          light = {
            background = "light",
          },
          dark = {
            background = "dark",
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
    "github/copilot.vim",
    enabled = true,
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
      vim.g.copilot_filetypes = {
        ["*"] = false,
        ["javascript"] = true,
        ["typescript"] = true,
        ["lua"] = true,
        ["rust"] = true,
        ["c"] = true,
        ["c#"] = true,
        ["c++"] = true,
        ["go"] = true,
        ["python"] = true,
        ["beancount"] = false,
      }
    end,
  },
  {
    "robitx/gp.nvim",
    config = function()
      local my_prompt = assert(io.open("/Users/duarteocarmo/Dropbox/dots/.gpt4prompt", "r")):read("*all")
      local conf = {
        default_command_agent = nil,
        default_chat_agent = nil,
        providers = {
          anthropic = {
            disable = false,
            endpoint = "https://api.anthropic.com/v1/messages",
            secret = { "cat", "/Users/duarteocarmo/Dropbox/dots/.anthropic_api_key" },
          },
          openai = {
            disable = false,
            endpoint = "https://api.openai.com/v1/chat/completions",
            secret = { "cat", "/Users/duarteocarmo/Dropbox/dots/.openai_api_key" },
          },
          ollama = {
            disable = false,
            endpoint = "http://localhost:11434/v1/chat/completions",
            secret = "dummy_secret",
          },
        },
        agents = {
          {
            provider = "openai",
            name = "Duarte - GPT4o",
            chat = true,
            command = true,
            model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
            system_prompt = my_prompt,
          },
          {
            provider = "anthropic",
            name = "Duarte - Claude-3-5-Sonnet",
            chat = true,
            command = true,
            model = { model = "claude-3-5-sonnet-20240620", temperature = 0.8, top_p = 1 },
            system_prompt = my_prompt,
          },
          {
            provider = "ollama",
            name = "Duarte - Llama",
            chat = true,
            command = true,
            model = {
              model = "llama3.2:latest",
              -- temperature = 0.6,
              -- top_p = 1,
              -- min_p = 0.05,
            },
            -- system prompt (use this to specify the persona/role of the AI)
            -- system_prompt = "You are a general AI assistant.",
            system_prompt = my_prompt,
          },
          {
            provider = "ollama",
            name = "Duarte - Deepseek",
            chat = true,
            command = true,
            model = {
              model = "deepseek-coder:6.7b",
            },
            -- system prompt (use this to specify the persona/role of the AI)
            -- system_prompt = "You are a general AI assistant.",
            system_prompt = my_prompt,
          },
        },
      }
      require("gp").setup(conf)
      vim.keymap.set({ "n", "v" }, "<leader>pc", ":GpChatNew popup<CR>")
      vim.keymap.set({ "n", "v" }, "<leader>pr", ":GpRewrite<CR>")
      vim.keymap.set({ "n", "v" }, "<leader>pa", ":GpAppend<CR>")

      -- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
    end,
  },

  {
    "saghen/blink.compat",
    optional = false, -- make optional so it's only enabled if any extras need it
    opts = {},
    version = not vim.g.lazyvim_blink_main and "*",
  },

  {
    "saghen/blink.cmp",
    tag = "v0.11.0",

    dependencies = {
      { "hrsh7th/cmp-emoji", "crispgm/cmp-beancount" },
    },
    opts = {
      sources = {
        compat = {},
        default = { "lsp", "path", "snippets", "buffer", "beancount", "emoji" },
        cmdline = {},
        providers = {
          emoji = {
            name = "emoji",
            module = "blink.compat.source",
          },
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

  {
    "folke/noice.nvim",
    enabled = true,
  },

  {
    "sphamba/smear-cursor.nvim",
    opts = {},
    enabled = false,
  },
  { "nathangrigg/vim-beancount" },
  { "tpope/vim-fugitive" },
  { "tpope/vim-rhubarb" },
  { "tpope/vim-sleuth" },
}
