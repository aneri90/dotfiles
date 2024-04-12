return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
		},
		keys = {
			{ "<leader>f/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer search" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find All Files" },
			{ "<leader>fw", "<cmd>Telescope live_grep<cr>", desc = "Ripgrep" },
			{ "<leader>fs", "<cmd>Telescope grep_string<cr>", desc = "Grep String" },
			-- Utils
			{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
			{ "<leader>fch", "<cmd>Telescope command_history<cr>", desc = "History" },
			{ "<leader>fl", "<cmd>Telescope lsp_references<cr>", desc = "Lsp References" },
			{ "<leader>fo", "<cmd>Telescope oldfiles<cr>", desc = "Old files" },
			{ "<leader>ft", "<cmd>Telescope treesitter<cr>", desc = "Treesitter" },
			-- Git things
			{ "<leader>fgf>", "<cmd>Telescope git_files<cr>", desc = "Git files" },
			{ "<leader>fgc", "<cmd>Telescope git_commits<cr>", desc = "Commits" },
			{ "<leader>fgb", "<cmd>Telescope git_branches<cr>", desc = "Branches" },
			{ "<leader>fgs", "<cmd>Telescope git_status<cr>", desc = "Status" },
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				pickers = {
					live_grep = {
						file_ignore_patterns = { "node_modules", ".git/", ".venv", "yarn.lock", "package-lock.json" },
						additional_args = function(_)
							return { "--hidden" }
						end,
					},
					find_files = {
						file_ignore_patterns = { "node_modules", ".git/", ".venv", "yarn.lock", "package-lock.json" },
						hidden = true,
					},
				},
			})
		end,
	},
}
