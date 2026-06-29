--[[ =========================================================================
  init.lua  —  Neovim 0.12+ config (vim.pack + native LSP + native completion)

  Requires: Neovim >= 0.12  (check with `nvim --version`)

  External tools to install yourself (no Mason here). On openSUSE Tumbleweed:
    sudo zypper in lua-language-server ripgrep fd gcc git make stylua
    pipx install ruff pyright          # python: lint+format (ruff) and types (pyright)
    rustup component add rust-analyzer # if you write Rust

  First-launch notes:
    * Wipe any stale plugins from a previous manager BEFORE first start:
        rm -rf ~/.local/share/nvim/site/pack
    * vim.pack writes ~/.config/nvim/nvim-pack-lock.json — COMMIT that file.
    * Build hooks (treesitter parsers, fzf-native) run async on first install;
      if telescope-fzf or a parser isn't ready, just restart once.
============================================================================ ]]

-- [[ Leader keys — must be set before plugins load ]]
vim.g.mapleader = ' '
vim.g.maplocalleader = ','
vim.g.have_nerd_font = true

-- [[ Options ]]
vim.opt.number = true
-- vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10

-- Floating-window borders (0.11+): gives hover/signature/diagnostics a frame.
vim.o.winborder = 'rounded'

-- [[ Native completion (Neovim 0.12) ]]
-- This is the "no nvim-cmp" path. See the COMPLETION SWAP block near the LSP
-- section if you'd rather use blink.cmp or keep nvim-cmp.
vim.o.autocomplete = true -- auto-show the insert-mode completion menu as you type
vim.o.completeopt = 'menu,menuone,noselect,fuzzy,popup'
vim.o.pumheight = 10

-- [[ Basic keymaps ]]
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostics (0.11+ uses vim.diagnostic.jump, not the old goto_prev/goto_next)
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = 'Go to previous [D]iagnostic' })
vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Go to next [D]iagnostic' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic autocommands ]]
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank() -- 0.12: vim.hl replaces the deprecated vim.highlight
  end,
})

-- [[ Optional: your ported personal modules ]]
-- If you bring keymaps/options/autocommands over from your old repo, drop them
-- in lua/custom/ and they'll layer on top of the defaults above. Guarded so a
-- missing file won't break startup.
for _, mod in ipairs { 'custom.options', 'custom.keymaps', 'custom.autocommands' } do
  pcall(require, mod)
end

-- [[ Build hooks for plugins that compile something ]]
-- vim.pack has no `build=` key; we react to install/update via PackChanged.
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('pack-build-hooks', { clear = true }),
  callback = function(ev)
    local spec = ev.data.spec
    if not spec or ev.data.kind == 'delete' then
      return
    end
    if spec.name == 'nvim-treesitter' then
      vim.cmd 'TSUpdate'
    elseif spec.name == 'telescope-fzf-native.nvim' then
      vim.system({ 'make' }, { cwd = ev.data.path })
    end
  end,
})

-- [[ Install plugins ]]
-- vim.pack.add loads plugins immediately and is NOT a lazy loader. List any
-- dependency (e.g. plenary) BEFORE the plugin that needs it.
vim.pack.add {
  -- Library deps
  'https://github.com/nvim-lua/plenary.nvim',

  -- Colorscheme
  'https://github.com/catppuccin/nvim',
  'https://github.com/folke/tokyonight.nvim',

  -- Fuzzy finder
  'https://github.com/nvim-telescope/telescope.nvim',
  { src = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim' },
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',

  -- LSP default configs (provider only; we never call .setup() on it)
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/folke/lazydev.nvim',

  -- Formatting
  'https://github.com/stevearc/conform.nvim',

  -- Treesitter — pinned to master for the classic configs API.
  -- (The `main`-branch rewrite has a different API; migrate later if you want.)
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'master' },

  -- Editing / QoL — mini.nvim provides surround, ai, statusline, etc.
  'https://github.com/echasnovski/mini.nvim',
  'https://github.com/folke/which-key.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/folke/todo-comments.nvim',

  -- Org-mode
  'https://github.com/nvim-orgmode/orgmode',
}

-- ===========================================================================
-- Plugin configuration
-- ===========================================================================

-- Colorscheme
require('catppuccin').setup { flavour = 'mocha' }
vim.cmd.colorscheme 'catppuccin'

-- mini.nvim modules
require('mini.ai').setup { n_lines = 500 }
require('mini.surround').setup() -- saiw) add, sd' delete, sr)' replace  (your surround plugin)
require('mini.git').setup {}
local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
  return '%2l:%-2v'
end
require('mini.trailspace').setup()

-- which-key
require('which-key').setup {
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
    { '<leader>d', group = '[D]ocument' },
    { '<leader>o', group = '[O]rgmode' },
    { '<leader>r', group = '[R]ename' },
    { '<leader>s', group = '[S]earch' },
    { '<leader>w', group = '[W]orkspace' },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
  },
}

-- gitsigns
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

-- todo-comments
require('todo-comments').setup { signs = false }

-- lazydev (Lua LSP awareness for your config)
require('lazydev').setup {
  library = {
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
  },
}

-- Telescope
require('telescope').setup {
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
  },
}
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
end, { desc = '[/] Fuzzily search in current buffer' })
vim.keymap.set('n', '<leader>sn', function()
  builtin.find_files { cwd = vim.fn.stdpath 'config' }
end, { desc = '[S]earch [N]eovim files' })

-- Treesitter
require('nvim-treesitter.configs').setup {
  -- NOTE: no 'org' here — orgmode ships and compiles its own parser via
  -- :Org install_treesitter_grammar. Adding it here pulls a conflicting one.
  ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'vim', 'vimdoc', 'python', 'rust' },
  auto_install = true,
  highlight = { enable = true, additional_vim_regex_highlighting = { 'org' } },
  indent = { enable = true },
}

-- Conform (formatting). Formatters must be on $PATH (ruff, stylua).
require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    local disable_filetypes = { c = true, cpp = true }
    return {
      timeout_ms = 500,
      lsp_format = disable_filetypes[vim.bo[bufnr].filetype] and 'never' or 'fallback',
    }
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    -- ruff replaces isort + black: organize imports first, then format.
    python = { 'ruff_organize_imports', 'ruff_format' },
  },
}
vim.keymap.set('', '<leader>f', function()
  require('conform').format { async = true, lsp_format = 'fallback' }
end, { desc = '[F]ormat buffer' })

-- Orgmode (replaces neorg). Adjust the paths to taste.
require('orgmode').setup {
  org_agenda_files = '~/org/**/*',
  org_default_notes_file = '~/org/refile.org',
}
-- Default orgmode mappings live under <localleader> inside .org files, plus
-- global <leader>oa (agenda) and <leader>oc (capture).

-- ===========================================================================
-- LSP
-- ===========================================================================

-- Diagnostics appearance (0.12: configure signs here; :sign-define is gone).
local sev = vim.diagnostic.severity
vim.diagnostic.config {
  severity_sort = true,
  update_in_insert = false,
  float = { border = 'rounded', source = true },
  virtual_text = { source = 'if_many' },
  signs = vim.g.have_nerd_font and {
    text = {
      [sev.ERROR] = '󰅚 ',
      [sev.WARN] = '󰀪 ',
      [sev.INFO] = '󰋽 ',
      [sev.HINT] = '󰌶 ',
    },
  } or {},
}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('gd', builtin.lsp_definitions, '[G]oto [D]efinition')
    map('gr', builtin.lsp_references, '[G]oto [R]eferences')
    map('gI', builtin.lsp_implementations, '[G]oto [I]mplementation')
    map('<leader>D', builtin.lsp_type_definitions, 'Type [D]efinition')
    map('<leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
    map('<leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
    map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Native LSP completion for this buffer (0.11+ API, colon form).
    if client and client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end

    -- ruff + pyright overlap: let pyright own hover so you don't get duplicates.
    if client and client.name == 'ruff' then
      client.server_capabilities.hoverProvider = false
    end

    -- Highlight references of the symbol under the cursor.
    if client and client:supports_method 'textDocument/documentHighlight' then
      local hl_group = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = hl_group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = hl_group,
        callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    -- Toggle inlay hints if supported.
    if client and client:supports_method 'textDocument/inlayHint' then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Server configs. nvim-lspconfig ships sensible cmd/root_markers/filetypes
-- defaults; we only specify overrides here, then enable by name.
vim.lsp.config('pyright', {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'standard',
        reportAttributeAccessIssue = false,
        reportArgumentType = false,
        reportIndexIssue = false,
      },
    },
  },
})

vim.lsp.config('ruff', {
  -- ruff acts as a linter / code-action server here; formatting is via conform.
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      completion = { callSnippet = 'Replace' },
      -- diagnostics = { disable = { 'missing-fields' } },
    },
  },
})

-- rust_analyzer uses nvim-lspconfig defaults as-is.
vim.lsp.enable { 'pyright', 'ruff', 'lua_ls', 'rust_analyzer' }

-- ===========================================================================
-- COMPLETION SWAP (optional)
-- ===========================================================================
-- You're on native completion (top of file: vim.o.autocomplete + the
-- vim.lsp.completion.enable call in LspAttach). To switch engines instead:
--
--   blink.cmp (single modern plugin):
--     1. add  'https://github.com/saghen/blink.cmp'  (pin a release tag) to vim.pack
--     2. remove the vim.lsp.completion.enable(...) line in LspAttach
--     3. set vim.o.autocomplete = false  and  require('blink.cmp').setup{...}
--
--   nvim-cmp (your old stack): add nvim-cmp + cmp-nvim-lsp + cmp-buffer +
--     cmp-path + LuaSnip + cmp_luasnip to vim.pack, drop the native bits above,
--     and merge cmp capabilities back into your server configs.
-- ===========================================================================

-- vim: ts=2 sts=2 sw=2 et
