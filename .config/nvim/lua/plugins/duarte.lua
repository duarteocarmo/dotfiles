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
    "arzg/vim-colors-xcode",
    priority = 1000,
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
      colorscheme = "default",
      -- colorscheme = "xcodedarkhc",
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
      -- local my_prompt = assert(io.open("/Users/duarteocarmo/Dropbox/dots/.gpt4prompt", "r")):read("*all")
      local code_prompt = assert(io.open("/Users/duarteocarmo/Dropbox/dots/.code_prompt", "r")):read("*all")

      local ollama_lines = vim.fn.split(vim.fn.system("ollama ls"), "\n")
      local ollama_agents = {}

      for i = 2, #ollama_lines do -- skip header
        local name = ollama_lines[i]:match("^([^%s]+)")
        if name then
          table.insert(ollama_agents, {
            provider = "ollama",
            name = "Ollama - " .. name,
            chat = true,
            command = true,
            model = { model = name },
            system_prompt = code_prompt,
          })
        end
      end

      local conf = {
        default_command_agent = nil,
        default_chat_agent = nil,
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
  -- {
  --   "olimorris/codecompanion.nvim",
  --   opts = {},
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  --   config = function()
  --     require("codecompanion").setup({
  --       adapters = {
  --         anthropic = function()
  --           return require("codecompanion.adapters").extend("anthropic", {
  --             env = {
  --               api_key = "cmd:cat /Users/duarteocarmo/Dropbox/dots/.anthropic_api_key | tr -d '\\n'",
  --             },
  --           })
  --         end,
  --       },
  --       display = {
  --         diff = {
  --           provider = "mini_diff",
  --         },
  --       },
  --     })
  --   end,
  -- },
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
    },
    opts = {
      sources = {
        compat = {},
        default = { "lsp", "path", "snippets", "buffer", "beancount" },
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
