-- Filetype rules restored from the old vimrc plus Chimera/FreeBSD/CI files
vim.filetype.add({
  extension = {
    inc = "php",      -- pfSense PHP includes
    ucl = "json",     -- FreeBSD pkg base UCL (no ucl parser; json is close)
    cli = "cligen",   -- cligen/clixon CLI DSL
  },
  filename = {
    Jenkinsfile = "groovy",
  },
  pattern = {
    [".*%.pkrvars?%.hcl"] = "hcl", -- HashiCorp Packer
    ["^Jenkinsfile%..*"] = "groovy",
  },
})

-- Indent rules from the old vimrc (ts=8 sts=4 sw=4)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "cligen", "yang" },
  callback = function(args)
    vim.bo[args.buf].tabstop = 8
    vim.bo[args.buf].softtabstop = 4
    vim.bo[args.buf].shiftwidth = 4
  end,
})

return {}
