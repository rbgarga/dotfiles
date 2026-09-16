-- Mason ships glibc prebuilt binaries, which cannot run on FreeBSD and
-- musl-based Chimera. For the LSP servers installed as system packages,
-- set mason = false so LazyVim enables them from PATH instead of waiting
-- for a Mason install that never lands.
local uname = vim.uv.os_uname()
local sysname = uname.sysname:lower()
local servers = {}

if sysname == "freebsd" then
  servers = { "gopls", "lua-language-server", "terraform-ls", "clangd", "ruff" }
elseif sysname == "linux" and vim.uv.fs_stat("/etc/chimera-release") then
  servers = { "gopls", "ruff", "clangd" }
end

if next(servers) == nil then
  return {}
end

local opts = { servers = {} }
for _, name in ipairs(servers) do
  opts.servers[name] = { mason = false }
end

return {
  { "neovim/nvim-lspconfig", opts = opts },
}
