return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      -- No completion in git buffers (commit messages, rebase todos,
      -- gitignore, ...) — blink.cmp recipe: "Disable per filetype/buffer"
      opts.enabled = function()
        return not vim.bo.filetype:match("^git")
      end

      -- "Manual" selection mode (blink.cmp docs): nothing preselected, so
      -- <CR> is always a newline; <C-y> accepts the first/current item and
      -- <C-n>/<C-p> navigate the list
      opts.completion = opts.completion or {}
      opts.completion.list = vim.tbl_deep_extend("force", opts.completion.list or {}, {
        selection = { preselect = false, auto_insert = false },
      })
    end,
  },
}
