-- FreeBSD ships bmake as `make`, which cannot parse GNU Makefiles;
-- prefer gmake when available
return {
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = vim.fn.executable("gmake") == 1 and "gmake" or "make",
  },
}
