return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local lazy_status = require("lazy.status") -- to configure lazy pending updates count
            local function branch_name(branch)
                if not branch or branch == "" then
                    return ""
                end
                return branch
            end
            require("lualine").setup({
                options = {
                    theme = "catppuccin-macchiato",
                    globalstatus = true,
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "█", right = "█" },
                },
                sections = {
                    lualine_b = {
                        { "branch", icon = "", fmt = branch_name },
                        "diff",
                        "diagnostics",
                    },
                    lualine_c = {
                        { "filename", path = 1 },
                    },
                    lualine_x = {
                        {
                            lazy_status.updates,
                            cond = lazy_status.has_updates,
                            color = { fg = "#ff9e64" },
                        },
                        { "filetype" },
                    },
                },
            })
        end,
    },
}
