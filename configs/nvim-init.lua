-- ===========================================================================
-- AUTOCMDS
-- ===========================================================================

-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = "lua vim.lsp.buf.format()",
})

-- Set HTML-style comments for Vue files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "vue",
	callback = function()
		vim.bo.commentstring = "<!-- %s -->"
	end,
})

-- Restore cursor position when reopening a file
vim.api.nvim_create_autocmd("BufWinEnter", {
	desc = "return cursor to where it was last time closing the file",
	pattern = "*",
	command = 'silent! normal! g`"zv',
})

-- ===========================================================================
-- KEYMAPS
-- ===========================================================================

-- Set the mapleader to a space character for key mappings that use <leader>.
vim.g.mapleader = " "

-- Define a key mapping in normal mode (<leader>pv) to execute an Ex command.
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Ex command" })

-- Create key mappings for moving selected text down and up in visual mode.
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Join the current line with the line below in normal mode (J).
vim.keymap.set("n", "J", "mzJ`z")

-- Edit the Packer.nvim configuration file in normal mode.
vim.keymap.set("n", "<leader>vpp", "<cmd>e ~/.config/nvim<CR>", { desc = "Open settings" })

-- Create a key mapping to open the GitHub repository homepage in the default web browser.
vim.keymap.set("n", "<leader>gh", function()
	local handle = io.popen("git config --get remote.origin.url")
	if not handle then
		return
	end

	local url = handle:read("*a"):gsub("%s+", "")
	print("Opening URL: " .. url)
	handle:close()

	if url == "" then
		print("No git remote found")
		return
	end

	-- Convert SSH to HTTPS
	if url:match("^git@") then
		url = url:gsub("git@([^:]+):", "https://%1/"):gsub("%.git$", "")
	elseif url:match("^https://") then
		url = url:gsub("%.git$", "")
	end

	-- Open in browser
	local opener
	if vim.fn.has("mac") == 1 then
		opener = "open"
	elseif vim.fn.has("unix") == 1 then
		opener = "xdg-open"
	elseif vim.fn.has("win32") == 1 then
		opener = "start"
	end

	if opener then
		os.execute(opener .. " " .. url)
	else
		print("Unsupported OS")
	end
end, { desc = "Open repo homepage" })

vim.keymap.set("n", "<C-_>", function()
	vim.cmd("botright split")
	vim.cmd("resize 15")

	vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), vim.api.nvim_create_buf(false, true))

	vim.fn.termopen(vim.o.shell)
	vim.cmd("startinsert")
end, { desc = "Toggle bottom terminal" })

-- ===========================================================================
-- LAZY
-- ===========================================================================

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- ===========================================================================
-- OPTIONS
-- ===========================================================================

-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

-- Enable clipboard support
vim.opt.clipboard:append("unnamedplus")

vim.opt.conceallevel = 0 -- don't hide my json strings

vim.o.pumheight = 10
vim.o.cursorline = true

-- https://github.com/neovim/neovim/issues/32660
vim.g._ts_force_sync_parsing = true

-- ---------------------------------------------------------------------------

-- ===========================================================================
-- PLUGINS
-- ===========================================================================
require("lazy").setup({
	spec = {

		-- -----------------------------------------------------------------------
		-- Autopairs
		-- -----------------------------------------------------------------------
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			config = true,
			-- use opts = {} for passing setup options
			-- this is equivalent to setup({}) function
		},

		-- -----------------------------------------------------------------------
		-- Flash
		-- -----------------------------------------------------------------------
		{
			"folke/flash.nvim",
			event = "VeryLazy",
			opts = {},
			keys = {
				{
					"s",
					mode = { "n", "x", "o" },
					function()
						require("flash").jump()
					end,
					desc = "Flash",
				},
			},
			config = function(_, opts)
				require("flash").setup(opts)
				vim.api.nvim_set_hl(0, "FlashMatch", { fg = "#C08069", bg = "#000000", bold = true })
				vim.api.nvim_set_hl(0, "FlashCurrent", { fg = "#C08069", bg = "#000000", bold = true })
				vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#DADAA3", bg = "#E166D3", bold = true })
				vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = "#666666" }) -- darken background text
			end,
		},

		-- -----------------------------------------------------------------------
		-- Fugitive
		-- -----------------------------------------------------------------------
		{
			--     "tpope/vim-fugitive",
			--     lazy = false,
			--     config = function()
			--         -- :G opens Git status in a new tab
			--         vim.api.nvim_create_user_command("G", function(opts)
			--             if opts.args == "" then
			--                 vim.cmd("below Git")
			--             else
			--                 vim.cmd("Git " .. opts.args)
			--             end
			--         end,
			--         {
			--             nargs = "*",
			--             complete = "file"
			--         })
			--     end,
			--     keys = {
			--         { "<leader>gb", "<cmd>Git blame<CR>", desc = "Git Blame on the current file" },
			--         { "<leader>gl", "<cmd>below Git log<CR>", desc = "Git Log" },
			--         { "<leader>gc", "<cmd>below Git commit<CR>", desc = "Git Commit" },
			--         { "<leader>gp", "<cmd>Git pull<CR>", desc = "Git Pull" },
			--         { "<leader>gP", "<cmd>Git push<CR>", desc = "Git Push" },
			--     }
			"tpope/vim-fugitive",
			lazy = false,
			config = function()
				-- :G opens Git status in a new tab
				vim.api.nvim_create_user_command("G", function(opts)
					if opts.args == "" then
						-- vim.cmd("tab Git")
						vim.cmd("below Git")

					-- Open Git normally
					-- vim.cmd("Git")
					--
					-- -- Move current buffer to bottom split with 15 lines
					-- vim.cmd("wincmd J")  -- Move to bottom
					-- vim.cmd("resize 35") -- Set heig
					else
						vim.cmd("Git " .. opts.args)
					end
				end, {
					nargs = "*",
					complete = "file",
				})
			end,
			keys = {
				{ "<leader>gb", "<cmd>Git blame<CR>", desc = "Git Blame on the current file" },
				{ "<leader>gl", "<cmd>below Git log<CR>", desc = "Git Log" },
				{ "<leader>gc", "<cmd>below Git commit<CR>", desc = "Git Commit" },
				{ "<leader>gp", "<cmd>Git pull<CR>", desc = "Git Pull" },
				{ "<leader>gP", "<cmd>Git push<CR>", desc = "Git Push" },
			},

			-- Gvdiffsplit!
			-- middle work copy
			-- left side: HEAD
			-- right side: feat ranchA
			-- :diffget
		},

		-- -----------------------------------------------------------------------
		-- Git
		-- -----------------------------------------------------------------------
		{ "tpope/vim-fugitive" },
		{ "f-person/git-blame.nvim" },

		-- -----------------------------------------------------------------------
		-- Guess indent
		-- -----------------------------------------------------------------------
		{ "nmac427/guess-indent.nvim" },

		-- -----------------------------------------------------------------------
		-- Harpoon
		-- -----------------------------------------------------------------------
		{
			"theprimeagen/harpoon",
			lazy = false,
			branch = "harpoon2",
			require = { { "nvim-lua/plenary.nvim" } },
			config = function()
				local harpoon = require("harpoon")

				harpoon:setup()

				vim.keymap.set("n", "<C-a>", function()
					harpoon:list():add()
				end, { desc = "Harpoon Add File" })
				vim.keymap.set("n", "<C-e>", function()
					harpoon.ui:toggle_quick_menu(harpoon:list())
				end, { desc = "Harpoon Toggle Menu" })
				vim.keymap.set("n", "<C-n>", function()
					harpoon:list():select(1)
				end, { desc = "Harpoon Select 1" })
				vim.keymap.set("n", "<C-m>", function()
					harpoon:list():select(2)
				end, { desc = "Harpoon Select 2" })
			end,
		},

		-- -----------------------------------------------------------------------
		-- LSP
		-- -----------------------------------------------------------------------
		{
			"neovim/nvim-lspconfig",
			dependencies = {
				"mason-org/mason.nvim",
				"mason-org/mason-lspconfig.nvim",

				"hrsh7th/cmp-nvim-lsp",
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"hrsh7th/cmp-cmdline",
				"hrsh7th/nvim-cmp",
				"L3MON4D3/LuaSnip",
				"saadparwaiz1/cmp_luasnip",

				"j-hui/fidget.nvim",
				"onsails/lspkind.nvim",
				"nvim-telescope/telescope.nvim",
			},

			config = function()
				require("fidget").setup({})

				-- =====================================================
				-- Mason
				-- =====================================================
				local ensure_installed = {
					"lua-language-server",
					"typescript-language-server",
					"pyright",
					"gopls",
					"css-lsp",
					"eslint-lsp",
					"vue-language-server",
					"prisma-language-server",

					"prettier",
					"stylua",
					"shfmt",
					"flake8",
					"mypy",
					"shellcheck",
				}

				require("mason").setup({})
				require("mason-lspconfig").setup({
					ensure_installed = {
						"lua_ls",
						"ts_ls",
						"pyright",
						"gopls",
						"cssls",
						"eslint",
						"prismals",
					},
				})

				local mr = require("mason-registry")

				mr:on("package:install:success", function()
					vim.defer_fn(function()
						require("lazy.core.handler.event").trigger({
							event = "FileType",
							buf = vim.api.nvim_get_current_buf(),
						})
					end, 100)
				end)

				mr.refresh(function()
					for _, tool in ipairs(ensure_installed) do
						local pkg = mr.get_package(tool)
						if not pkg:is_installed() then
							if tool == "eslint-lsp" then
								pkg:install({ version = "4.8.0" })
							else
								pkg:install()
							end
						end
					end
				end)

				-- =====================================================
				-- LSP CONFIGS (API NOVA)
				-- =====================================================

				-- Lua
				vim.lsp.config("lua_ls", {
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
							},
						},
					},
				})

				-- TypeScript + Vue
				vim.lsp.config("ts_ls", {
					filetypes = {
						"javascript",
						"javascriptreact",
						"typescript",
						"typescriptreact",
						"vue",
					},
					init_options = {
						plugins = {
							{
								name = "@vue/typescript-plugin",
								location = vim.fn.expand("$MASON")
									.. "/packages/vue-language-server/node_modules/@vue/language-server",
								languages = { "javascript", "typescript", "vue" },
							},
						},
					},
				})

				-- ESLint
				vim.lsp.config("eslint", {
					on_attach = function(client)
						client.server_capabilities.hoverProvider = false
					end,
				})

				-- =====================================================
				-- ENABLE SERVERS
				-- =====================================================
				for _, server in ipairs({
					"lua_ls",
					"ts_ls",
					"pyright",
					"gopls",
					"cssls",
					"eslint",
					"prismals",
				}) do
					vim.lsp.enable(server)
				end

				-- =====================================================
				-- LSP KEYMAPS
				-- =====================================================
				vim.api.nvim_create_autocmd("LspAttach", {
					group = vim.api.nvim_create_augroup("LspAttach", {}),
					callback = function(args)
						local opts = { buffer = args.buf }
						local telescope = require("telescope.builtin")

						vim.keymap.set("n", "gd", telescope.lsp_definitions, opts)
						vim.keymap.set("n", "K", function()
							vim.lsp.buf.hover({ border = "rounded" })
						end, opts)
						vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
						vim.keymap.set("n", "gr", telescope.lsp_references, opts)
						vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)
						vim.keymap.set("i", "<C-k>", function()
							vim.lsp.buf.signature_help({ border = "rounded" })
						end, opts)
						vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
						vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

						vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
						vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
						vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float)
					end,
				})

				-- =====================================================
				-- Diagnostics
				-- =====================================================
				vim.diagnostic.config({
					virtual_text = true,
					signs = true,
					underline = true,
					update_in_insert = true,
					severity_sort = true,
					float = {
						focusable = true,
						style = "minimal",
						border = "rounded",
						source = true,
					},
				})

				-- =====================================================
				-- CMP
				-- =====================================================
				local cmp = require("cmp")

				cmp.setup({
					formatting = {
						format = require("lspkind").cmp_format({
							mode = "symbol_text",
							preset = "codicons",
							maxwidth = 50,
							ellipsis_char = "…",
						}),
					},
					window = {
						completion = cmp.config.window.bordered(),
						documentation = cmp.config.window.bordered(),
					},
					snippet = {
						expand = function(args)
							require("luasnip").lsp_expand(args.body)
						end,
					},
					mapping = cmp.mapping.preset.insert({
						["<C-u>"] = cmp.mapping.scroll_docs(-4),
						["<C-d>"] = cmp.mapping.scroll_docs(4),
						["<C-c>"] = cmp.mapping.complete(),
						["<C-e>"] = cmp.mapping.abort(),
						["<CR>"] = cmp.mapping.confirm({ select = true }),
					}),
					sources = cmp.config.sources({
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
						{ name = "buffer" },
						{ name = "path" },
					}),
				})
			end,
		},

		-- -----------------------------------------------------------------------
		-- Telescope
		-- -----------------------------------------------------------------------
		{
			"nvim-telescope/telescope.nvim",
			branch = "master",
			dependencies = {
				"nvim-lua/plenary.nvim",
				"nvim-tree/nvim-web-devicons",
				{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			},
			config = function()
				require("telescope").load_extension("fzf")
				local builtin = require("telescope.builtin")

				local function find_files()
					builtin.find_files({
						find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
					})
				end

				vim.keymap.set(
					"n",
					"<leader>ff",
					find_files,
					{ noremap = true, desc = "Telescope find files (including hidden ones)" }
				)
				vim.keymap.set("n", "<leader>fw", builtin.live_grep, { desc = "Telescope live grep" })
				vim.keymap.set(
					"n",
					"<leader>fg",
					builtin.git_files,
					{ desc = "Telescope git files (based on changes)" }
				)
				vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
			end,
		},

		-- -----------------------------------------------------------------------
		-- Theme
		-- -----------------------------------------------------------------------
		-- {
		-- 	"folke/tokyonight.nvim",
		-- 	lazy = false,
		-- 	opts = {
		-- 		style = "night",
		-- 		transparent = true, -- false
		-- 		styles = {
		-- 			sidebars = "transparent", -- "dark"
		-- 			floats = "transparent", -- "dark"
		-- 		},
		-- 	},
		-- 	config = function(_, opts)
		-- 		require("tokyonight").setup(opts)
		-- 		vim.cmd.colorscheme("tokyonight")
		-- 	end,
		-- },
		{
			"Mofiqul/vscode.nvim",
			lazy = false,
			priority = 1000,
			config = function(_, opts)
				-- require("vscode").setup({ transparent = true })
				require("vscode").setup(opts)
				vim.g.vscode_style = "dark"
				vim.g.vscode_transparent = true
				vim.g.vscode_enable_italic = true
				vim.g.vscode_enable_bold = true
				vim.cmd.colorscheme("vscode")
			end,
		},

		-- -----------------------------------------------------------------------
		-- TODO
		-- -----------------------------------------------------------------------
		{
			"viniciusteixeiradias/todo.nvim",
			-- version = "*",
			dependencies = { "nvim-telescope/telescope.nvim" },
			config = function()
				require("todo").setup({
					highlight_buffer = true,
					patterns = {
						TODO = { fg = "#ffee8c", bg = "" }, -- Light yellow font
						FIXME = { fg = "#fca5a5", bg = "" }, -- Light red font
					},
				})
			end,
			-- dir = "~/workspace/projects/neovim-todo",
			-- dependencies = { "nvim-telescope/telescope.nvim" },
			-- config = function()
			--   require("neovim-todo").setup({
			--   })
			-- end,
		},

		-- -----------------------------------------------------------------------
		-- Treesitter
		-- -----------------------------------------------------------------------
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
			event = { "BufReadPost", "BufNewFile" }, -- garante que carregue antes do config
			config = function()
				local ok, configs = pcall(require, "nvim-treesitter.configs")
				if not ok then
					return
				end

				configs.setup({
					ensure_installed = {
						"lua",
						"typescript",
						"javascript",
						"python",
						"go",
						"css",
						"scss",
						"vue",
						"json",
						"html",
						"yaml",
						"bash",
						"markdown",
						"markdown_inline",
						"toml",
						"dockerfile",
						"regex",
						"query",
					},

					sync_install = false,
					auto_install = true,

					indent = { enable = true },

					highlight = {
						enable = true,
						additional_vim_regex_highlighting = { "markdown" },
					},
				})
			end,
		},

		-- -----------------------------------------------------------------------
		-- Trouble
		-- -----------------------------------------------------------------------
		{
			"folke/trouble.nvim",
			cmd = "Trouble",
			opts = { use_diagnostic_signs = true },
			keys = { { "<leader>td", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Trouble Diagnostics" } } },
		},

		-- -----------------------------------------------------------------------
		-- VIM be good
		-- -----------------------------------------------------------------------
		{ "ThePrimeagen/vim-be-good" },

		-- -----------------------------------------------------------------------
		-- VIM tmux navigator
		-- -----------------------------------------------------------------------
		{
			"christoomey/vim-tmux-navigator",
			lazy = false,
		},

		-- -----------------------------------------------------------------------
		-- Whick key
		-- -----------------------------------------------------------------------
		{
			"folke/which-key.nvim",
			event = "VeryLazy",
			opts = {},
			config = function(_, opts)
				local which_key = require("which-key")
				which_key.setup(opts)

				which_key.add({
					{ "<leader>g", group = "Git" },
					{ "<leader>v", group = "Vim" },
					{ "<leader>t", group = "Trouble" },
					{ "<leader>f", group = "Telescope" },
				})
			end,
		},

		-- -----------------------------------------------------------------------
		-- Windsurf (AI completion)
		-- -----------------------------------------------------------------------
		{
			"Exafunction/windsurf.vim",
			event = "BufEnter",
		},
	},

	defaults = {
		lazy = false,
		version = false, -- always use the latest git commit
	},
	install = { colorscheme = { "tokyonight", "habamax" } },
	checker = { enabled = true }, -- automatically check for plugin updates
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				-- "matchit",
				-- "matchparen",
				-- "netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
