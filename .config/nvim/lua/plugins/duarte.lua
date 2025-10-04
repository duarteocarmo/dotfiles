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
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "metalelf0/black-metal-theme-neovim",
    lazy = false,
    priority = 1000,
    config = function()
      require("black-metal").setup({
        -- optional configuration here
      })
    end,
  },
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require("github-theme").setup({
        -- ...
      })
    end,
  },
  {
    "arzg/vim-colors-xcode",
    priority = 1000,
  },
  { "ntk148v/komau.vim" },
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
      colorscheme = "tokyonight",
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
            colorscheme = "tokyonight-day",
          },
          dark = {
            background = "dark",
            colorscheme = "tokyonight-night",
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

      -- for i = 2, #ollama_lines do
      --   local name = ollama_lines[i]:match("^([^%s]+)")
      --   if name then
      --     table.insert(ollama_agents, {
      --       provider = "ollama",
      --       name = "Ollama - " .. name,
      --       chat = true,
      --       command = true,
      --       model = { model = name },
      --       system_prompt = code_prompt,
      --     })
      --   end
      -- end

      table.insert(ollama_agents, {
        provider = "copilot",
        name = "Copilot - Claude Sonnet 4",
        chat = true,
        command = true,
        model = { model = "claude-sonnet-4", temperature = 1.1, top_p = 1 },
        system_prompt = code_prompt,
      })

      table.insert(ollama_agents, {
        provider = "copilot",
        name = "Copilot - Grok",
        chat = true,
        command = true,
        model = { model = "grok-code-fast-1" },
        system_prompt = code_prompt,
      })

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
    "NickvanDyke/opencode.nvim",
    dependencies = {
      -- Recommended for better prompt input, and required to use `opencode.nvim`'s embedded terminal — otherwise optional
      { "folke/snacks.nvim", opts = { input = { enabled = true } } },
    },
    config = function()
      vim.g.opencode_opts = {
        -- Your configuration, if any — see `lua/opencode/config.lua`
      }

      -- Required for `opts.auto_reload`
      vim.opt.autoread = true

      -- Recommended/example keymaps
      vim.keymap.set("n", "<leader>ot", function()
        require("opencode").toggle()
      end, { desc = "Toggle embedded" })
      vim.keymap.set("n", "<leader>oA", function()
        require("opencode").ask()
      end, { desc = "Ask" })
      vim.keymap.set("n", "<leader>oa", function()
        require("opencode").ask("@cursor: ")
      end, { desc = "Ask about this" })
      vim.keymap.set("v", "<leader>oa", function()
        require("opencode").ask("@selection: ")
      end, { desc = "Ask about selection" })
      vim.keymap.set("n", "<leader>oe", function()
        require("opencode").prompt("Explain @cursor and its context")
      end, { desc = "Explain this code" })
      vim.keymap.set("n", "<leader>o+", function()
        require("opencode").prompt("@buffer", { append = true })
      end, { desc = "Add buffer to prompt" })
      vim.keymap.set("v", "<leader>o+", function()
        require("opencode").prompt("@selection", { append = true })
      end, { desc = "Add selection to prompt" })
      vim.keymap.set("n", "<leader>on", function()
        require("opencode").command("session_new")
      end, { desc = "New session" })
      vim.keymap.set("n", "<S-C-u>", function()
        require("opencode").command("messages_half_page_up")
      end, { desc = "Messages half page up" })
      vim.keymap.set("n", "<S-C-d>", function()
        require("opencode").command("messages_half_page_down")
      end, { desc = "Messages half page down" })
      vim.keymap.set({ "n", "v" }, "<leader>os", function()
        require("opencode").select()
      end, { desc = "Select prompt" })
    end,
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
