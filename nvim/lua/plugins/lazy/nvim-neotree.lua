return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			filesystem = {
				follow_current_file = { enabled = true },
				hijack_netrw_behavior = "open_current",
				use_libuv_file_watcher = vim.fn.has("win32") ~= 1,
			},
		})
		vim.keymap.set("n", "<leader>ee", ":Neotree filesystem reveal left<CR>", {})
		vim.keymap.set("n", "<leader>eb", ":Neotree buffers reveal float<CR>", {})
		vim.keymap.set("n", "<leader>et", ":Neotree toggle<cr>", { desc = "Toggle [N]eotree window" })
	end,
}
