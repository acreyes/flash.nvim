local M = {}
M._buf = nil
M._win = nil

M.get_buf = function()

    if not M._buf then
        M._buf = vim.api.nvim_create_buf(true, true)
    end
    if not M._win then
        vim.cmd('botright vsplit')
        vim.api.nvim_win_set_width(0,50)
        M._win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(M._win, M._buf)
        vim.api.nvim_command('wincmd p')
    end
end

M.close_win = function()
    if M._win then
        vim.api.nvim_win_close(M._win, false)
        M._win = nil
    end
end

M.write_stdout = function(data)
    vim.api.nvim_buf_set_lines(M._buf, -1, -1, false, data)
end

return M
