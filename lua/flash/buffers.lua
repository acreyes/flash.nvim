local M = {}
M._buf = nil
M._win = nil
local jobs = {}

M.get_buf = function()

    if not M._buf then
        M._buf = vim.api.nvim_create_buf(true, true)
    end
    local next = next(vim.fn.win_findbuf(M._buf))
    if not next then
        vim.cmd('botright vsplit')
        vim.api.nvim_win_set_width(0,50)
        M._win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(M._win, M._buf)
        vim.api.nvim_command('wincmd p')
    end
end

M.clear_buf = function(maxLines)
    maxLines = maxLines or 100
    local Nlines = vim.api.nvim_buf_line_count(M._buf)
    if Nlines > maxLines then
        vim.api.nvim_buf_set_lines(M._buf, 0, -maxLines, false, {""})
    end
end

M.close_win = function()
    if M._win then
        vim.api.nvim_win_close(M._win, false)
        M._win = nil
    end
end

-- scroll target buffer to end (set cursor to last line)
local scroll_to_end = function(bufnr)
  local cur_win = vim.api.nvim_get_current_win()

  -- switch to buf and set cursor
  vim.api.nvim_buf_call(bufnr, function()
    local target_win = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(target_win)

    local target_line = vim.tbl_count(vim.api.nvim_buf_get_lines(0, 0, -1, true))
    vim.api.nvim_win_set_cursor(target_win, { target_line, 0 })
  end)

  -- return to original window
  vim.api.nvim_set_current_win(cur_win)
end

M.write_stdout = function(data)
    -- local prev_data = vim.api.nvim_buf_get_lines(M._buf,0,-1,false)
    -- print(vim.inspect(prev_data))
    vim.api.nvim_buf_set_lines(M._buf, -1, -1, false, data)
    scroll_to_end(M._buf)
end

M.run_buf = function(command, optsIN)
    optsIN = optsIN or {}
    M.get_buf()
    M.clear_buf()
    local opts = {
        stdout_buffered=false,
        on_stdout = function(_, data)
            if data then
                M.write_stdout(data)
            end
        end,
        on_stderr = function(_, data)
            if data then
                M.write_stdout(data)
            end
        end,
    }
    for key, val in pairs(optsIN) do
        opts[key] = val
    end
    local jid = vim.fn.jobstart(command, opts)
    jobs[jid] = jid
end

M.kill_all = function()
    for id, _ in pairs(jobs) do
        vim.fn.jobstop(id)
    end
end

return M
