filetype indent on                  " load filetype-specific indent files
syntax on                           " syntax highlighting
set vb t_vb=                        " no visual bell & flash"
set tabstop=4                       " 4 characters long
set softtabstop=4                   " number of spaces in tab while editing
set shiftwidth=4                    " when indenting with >, user 4 spaces width
set expandtab 	                    " tabs are spaces
set smartindent                     " indentation
set nu                              " line numbers
set showmatch                       " highlight matching !!important!!
set wildmenu                        " visual autocomplete for command menu
set showcmd                         " show command in bottom bar
set cursorline                      " highlight current line
set mouse=a                         " mouse support?                        
set incsearch                       " search highlighing
set guicursor=                      " vim like cursor behavior
set background=light                 " fixes glitch? in colors when using vim with tmux
set t_Co=256                        " tmux related
set termguicolors                   " tmux related


" TODO cleanup configuration w/ lua files

call plug#begin('~/.vim/plugged')                               " vim-plug plugins will be downloaded there

" Colorschemes
Plug 'phanviet/vim-monokai-pro'
Plug 'catppuccin/nvim'
Plug 'sjl/badwolf' 
Plug 'EdenEast/nightfox.nvim' 
Plug 'projekt0n/github-nvim-theme'

" LSP and syntax
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}     " We recommend updating the parsers on update
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-cmdline'
Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'onsails/lspkind-nvim'
 
" Handy tools
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'tpope/vim-commentary'                                     " comment using gcc
Plug 'tpope/vim-fugitive'                                       " git versioning and bar 
Plug 'lewis6991/gitsigns.nvim'
Plug 'jiangmiao/auto-pairs'                                     " auto close brackets
Plug 'tpope/vim-surround'

" Language specific
Plug 'satabin/hocon-vim'
Plug 'plasticboy/vim-markdown'                                  " Markdown folding 
Plug 'nathangrigg/vim-beancount'                                " beancount plugin
Plug 'psf/black', { 'branch': 'stable' }                        " black formatting for python
Plug 'sbdchd/neoformat'
Plug 'nvim-lua/plenary.nvim'

call plug#end()                                                 " vim-plugs should not be declared below this.

" Fix tmux rendering, only necessary if you use 'set termguicolors'
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

" set background=light
colorscheme monokai_pro

" Set path to python
let g:python3_host_prog = "/Users/duartecarmo/.asdf/installs/python/3.10.2/bin/python"

" Configuration for vim-markdown plugin
autocmd FileType markdown let g:vim_markdown_new_list_item_indent = 0

" Because we dont want to screw with PEP 8
autocmd FileType python let g:black_linelength = 79         " max file length

" Spell check for markdown files
autocmd FileType markdown setlocal spell

" Map :Black to ctrl+k
nnoremap <C-k> :Neoformat<Cr> 

"Clear search highlighting when hitting ESC
nnoremap <esc> :let @/=""<return><esc>

" Ctrl+p for fzf vim
" nnoremap <C-p>Telescope find_files<Cr>
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr> 


" Git diff file
nnoremap <space>gd :Git diff %<CR>

" Git commit file
nnoremap <space>gc :Git commit %<CR>

" Autocompelte
set completeopt=menu,menuone,noselect

" Folding
set foldlevel=99
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()

" Nvim tree
nnoremap <C-n> :NvimTreeToggle<CR>
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>

lua <<EOF


local nvim_lsp = require('lspconfig')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
  buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

end




-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { 'pyright'}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    }
  }
end





-- Treesitter config, required for syntax highlighting
require'nvim-treesitter.configs'.setup {
ensure_installed = "maintained",
highlight = {
enable = true,
},
indent = {
enable = true,
disable = {"python"}
},
}








-- Setup nvim-cmp
local cmp = require'cmp'

cmp.setup({
sources = {
    { name = "nvim_lsp", max_item_count = 25},
    { name = "path", max_item_count = 25 },
    { name = "buffer", keyword_length = 4, max_item_count = 25},
    },
mapping = {
    ["<CR>"] = cmp.mapping.confirm({select = true}),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    },
formatting = {
    format = require("lspkind").cmp_format({with_text = true, menu = ({
    buffer = "[buf]",
    nvim_lsp = "[lsp]",
    path = "[path]",
    })}),
    },
})


require'lualine'.setup {options={theme = 'modus-vivendi'}}
require('gitsigns').setup()


EOF
