return {
    'rmagatti/auto-session',
    config = function()
        require("auto-session").setup {
            log_levl = "error",
            auto_session_enabled = true,
            auto_save_enabled = true,
            auto_restore_enabled = true,
            auto_session_use_git_branch = false,
            auto_session_suppress_dirs = { '~/', '~/dev' },
            auto_clean_after_session_restore = true, -- Automatically clean up broken neo-tree buffers saved in sessions
            bypass_session_save_file_types = {
                "alpha",
                "NvimTree",
                "dashboard",
                "noice",
                "notify",
                "telescope",
                "fzf",
                "fugitive",
                "git",
                "gitcommit",
                "gitrebase",
                "gitmerge",
                "gitmessenger",
                "gitstatus",
                "NeogitStatus",
                "gitblame",
                "packer",
                "neogit",
                "neo-tree"
            },
            -- as
            pre_save_cmds = { "Neotree close", "BDelete! nameless", "BDelete! hidden", "BDelete glob=yode*", "cclose" }
        }
    end
}
