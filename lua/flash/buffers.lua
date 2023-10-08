local M = {}
M._buf = nil
M._win = nil
local job = nil

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

M.toggle_win = function()
    local wins = vim.fn.win_findbuf(M._buf)
    local nxt = next(wins)
    if not nxt then
        -- buffer not open in any window
        M.get_buf()
    else
        -- close window
        vim.api.nvim_win_close(wins[1], false)
    end
end

M.clear_buf = function(maxLines)
    maxLines = maxLines or 100
    local Nlines = vim.api.nvim_buf_line_count(M._buf)
    if Nlines > maxLines then
        vim.api.nvim_buf_set_lines(M._buf, 1, -maxLines, false, {""})
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
    vim.api.nvim_buf_set_lines(M._buf, -2, -1, false, data)
    scroll_to_end(M._buf)
end

local clear_job = function()
    job = nil
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
        on_exit = function()
            clear_job()
        end,
    }
    for key, val in pairs(optsIN) do
        opts[key] = val
    end
    if job then
        vim.fn.jobwait({job})
        job = vim.fn.jobstart(command, opts)
    else
        job = vim.fn.jobstart(command, opts)
    end
end

M.send_stdin = function()
    if job then
        local msg = vim.fn.input('stdin: ')
        vim.fn.chansend(job, msg)
        vim.fn.chanclose(job, 'stdin')
    else
        print('No Running job')
    end
end


M.kill_all = function()
    vim.fn.jobstop(job)
end

return M
