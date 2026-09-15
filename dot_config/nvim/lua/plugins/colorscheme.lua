return {
  -- Gruvbox is the active colorscheme (ghostty and tmux use the same
  -- palette); catppuccin stays installed for easy comparison
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
  { "ellisonleao/gruvbox.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
}
