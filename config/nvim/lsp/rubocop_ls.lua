---@source https://github.com/qompassai/Diver
return ---@type vim.lsp.Config
{
    cmd = {
        'bundle',
        'exec',
        'rubocop',
        '--lsp',
    },
    filetypes = {
        'ruby',
    },
    root_markers = {
        'Gemfile',
        '.git',
    },
    settings = {},
}
