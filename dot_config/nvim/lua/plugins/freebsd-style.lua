-- Load the FreeBSD kernel source coding style, if available
if vim.fn.has("autocmd") == 1 then
  vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = { "*.php", "*.inc", "*.c" },
    callback = function()
      local style = vim.fs.normalize("~/.vim/freebsd.vim")
      if vim.fn.filereadable(style) == 1 then
        vim.cmd.source(style)
        if vim.fn.exists("*FreeBSD_Style") == 1 then
          vim.fn.FreeBSD_Style()
        end
        -- freebsd.vim maps <Leader>f, shadowing LazyVim's find group;
        -- move the style function to <leader>fs instead
        pcall(vim.cmd, "silent! nunmap <Leader>f")
        vim.keymap.set("n", "<leader>fs", function()
          vim.fn.FreeBSD_Style()
        end, { desc = "FreeBSD style", buffer = true })
      end
    end,
  })
end

return {}
