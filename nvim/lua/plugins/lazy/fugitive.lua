return {
	"tpope/vim-fugitive",
	config = function()
		vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Open Git Fugitive Panel" })

		local ThePrimeagen_Fugitive = vim.api.nvim_create_augroup("ThePrimeagen_Fugitive", {})

		local autocmd = vim.api.nvim_create_autocmd
		autocmd("BufWinEnter", {
			group = ThePrimeagen_Fugitive,
			pattern = "*",
			callback = function()
				if vim.bo.ft ~= "fugitive" then
					return
				end

				local bufnr = vim.api.nvim_get_current_buf()

				vim.keymap.set("n", "<leader>p", function()
					vim.cmd.Git("push")
				end, { buffer = bufnr, remap = false, desc = "Perform git [p]ush" })

				vim.keymap.set("n", "<leader>P", function()
					vim.cmd.Git({ "pull --rebase" })
				end, { buffer = bufnr, remap = false, desc = "Perform git [P]ull with rebase" })
			end,
		})

		vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>")
		vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>")
	end,
}
