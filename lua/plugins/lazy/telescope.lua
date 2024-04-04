return {
    "nvim-telescope/telescope.nvim",

    tag = "0.1.5",

    dependencies = {
        "nvim-lua/plenary.nvim"
    },

    config = function()
        require('telescope').setup({})

        -- vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        -- vim.keymap.set('n', '<leader>pws', function()
        --     local word = vim.fn.expand("<cword>")
        --     builtin.grep_string({ search = word })
        -- end)
        -- vim.keymap.set('n', '<leader>pWs', function()
        --     local word = vim.fn.expand("<cWORD>")
        --     builtin.grep_string({ search = word })
        -- end)
        -- vim.keymap.set('n', '<leader>sf', function()
        --     builtin.grep_string({ search = vim.fn.input("Grep > ") })
        -- end)

        -- Telescope mappings
        local builtin = require 'telescope.builtin'
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope [F]ind [F]iles' })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescop open help' })
        vim.keymap.set('n', '<leader>fw', builtin.live_grep, { desc = 'Telescop live grep' })
        vim.keymap.set('n', '<Leader>fb', builtin.buffers, { desc = 'Telescope list buffers' })
        vim.keymap.set('n', '<Leader>fo', builtin.commands, { desc = 'Telescope list commands' })

        -- Git things
        vim.keymap.set('n', '<Leader>fgs', builtin.git_status, { desc = 'Telescope Git status' })
        vim.keymap.set('n', '<Leader>fgf', builtin.git_files, { desc = 'Telescope Git files' })
        vim.keymap.set('n', '<Leader>fgc', builtin.git_commits, { desc = 'Telescope Display Git Commit History' })
        vim.keymap.set('n', '<Leader>fgb', builtin.git_branches, { desc = 'Telescope Display Git branches' })
        -- vim.keymap.set('n', '<Leader>fgt', builtin.git_stash, { desc = 'Telescope Git Stash' })
    end
}
