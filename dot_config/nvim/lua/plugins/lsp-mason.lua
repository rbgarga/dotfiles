-- Mason ships glibc prebuilt binaries, which cannot run on FreeBSD and
-- musl-based Chimera. LSP servers installed as system packages get
-- mason = false so LazyVim enables them from PATH; servers with no binary
-- available are skipped entirely; and Mason tools covered by system
-- packages are removed from ensure_installed so Mason stops retrying
-- them on every startup.
local uname = vim.uv.os_uname()
local sysname = uname.sysname:lower()
local is_chimera = sysname == "linux" and vim.uv.fs_stat("/etc/chimera-release") ~= nil

local servers, disabled, mason_skip = {}, {}, {}
if sysname == "freebsd" then
  servers = { "gopls", "ruff", "clangd", "lua_ls", "terraformls", "neocmake" }
  disabled = { "taplo" }
  mason_skip = { "golangci-lint", "hadolint", "shfmt", "tflint", "stylua" }
elseif is_chimera then
  servers = { "gopls", "ruff", "clangd", "taplo" }
  disabled = { "lua_ls" }
  mason_skip = { "golangci-lint", "hadolint", "shfmt", "tflint", "stylua" }
end

-- shell LSP is not packaged for FreeBSD; Mason installs it via npm
local needs_mason_override = next(servers) ~= nil or next(mason_skip) ~= nil

local specs = {
  {
    "mason-org/mason.nvim",
    opts = function(_, o)
      if needs_mason_override then
        o.ensure_installed = vim.tbl_filter(function(tool)
          return not vim.tbl_contains(mason_skip, tool)
        end, o.ensure_installed or {})
      end
      if not vim.tbl_contains(o.ensure_installed or {}, "bash-language-server") then
        table.insert(o.ensure_installed or {}, "bash-language-server")
      end
    end,
  },
}

if next(servers) ~= nil or next(disabled) ~= nil then
  local server_opts = {}
  for _, name in ipairs(servers) do
    server_opts[name] = { mason = false }
  end
  for _, name in ipairs(disabled) do
    server_opts[name] = { enabled = false }
  end
  table.insert(specs, 1, {
    "neovim/nvim-lspconfig",
    opts = { servers = server_opts },
  })
end

return specs
