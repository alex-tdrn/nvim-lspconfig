local util = require 'lspconfig.util'

-- Only Lake 3.0+ supports lake serve, so for old enough Lean 4,
-- we fallback to the builtin LSP.
local legacy_cmd = { 'lean', '--server' }

return {
  default_config = {
    cmd = { 'lake', 'serve', '--' },
    filetypes = { 'lean' },
    root_dir = function(fname)
      -- check if inside elan stdlib
      fname = util.path.sanitize(fname)
      local stdlib_dir
      do
        local _, endpos = fname:find '/lib/lean'
        if endpos then
          stdlib_dir = fname:sub(1, endpos)
        end
      end

      return util.root_pattern('lakefile.lean', 'lean-toolchain', 'leanpkg.toml')(fname)
        or stdlib_dir
        or util.find_git_ancestor(fname)
    end,
    on_new_config = function(config, root_dir)
      local lake_version = ''
      local lake_job = vim.fn.jobstart({ 'lake', '--version' }, {
        on_stdout = function(_, d, _)
          lake_version = table.concat(d, '\n')
        end,
        stdout_buffered = true,
      })
      if lake_job > 0 and vim.fn.jobwait({ lake_job })[1] == 0 then
        local major = lake_version:match 'Lake version (%d).'
        if major and tonumber(major) < 3 then
          config.cmd = legacy_cmd
        end
      end
      -- add root dir as command-line argument for `ps aux`
      table.insert(config.cmd, root_dir)
    end,
    single_file_support = true,
  },
  docs = {
    description = [[
https://github.com/leanprover/lean4

Lean installation instructions can be found
[here](https://leanprover-community.github.io/get_started.html#regular-install).

The Lean 4 language server is built-in with a Lean 4 install
(and can be manually run with, e.g., `lean --server`).

Note: that if you're using [lean.nvim](https://github.com/Julian/lean.nvim),
that plugin fully handles the setup of the Lean language server,
and you shouldn't set up `leanls` both with it and `lspconfig`.
    ]],
    default_config = {
      root_dir = [[root_pattern("lakefile.lean", "lean-toolchain", "leanpkg.toml", ".git")]],
    },
  },
}
