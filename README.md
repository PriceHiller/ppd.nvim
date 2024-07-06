# `PPD.nvim`

An implementation of shell `pushd` & `popd` commands for Neovim versions `0.10.0+`.

## Installation/Setup

- [lazy.nvim](https://github.com/folke/lazy.nvim):

  ```lua
  {
    "PriceHiller/ppd.nvim",
    config = true
  }
  ```

  or

  ```lua
  {
    "PriceHiller/ppd.nvim",
    config = function()
      require("ppd").setup({})
    end
  }
  ```

## Configuration

The default configuration is provided below:

```lua
require("ppd").setup({
    -- Automatically push paths from DirChanged events onto the stack
    auto_cd = true,
    dedup = {
        -- Do not push a path that is the same as the newest path on the stack
        top = true,
        -- Do not push any duplicates onto the stack
        all = false,
    },
    notify = {
        -- Display the stack on all pushd invocations
        on_pushd = true,
        -- Display the stack on all popd invocations
        on_popd = true,
    },
})
```

## Usage

`PPD.nvim` provides a few user commands relating to different scopes, read `:h current-directory`. For most users using
only the globally scoped commands is recommended.

| Scope  | Push Directory Command | Pop Directory Command |
| ------ | ---------------------- | --------------------- |
| Global | `Pushd`                | `Popd`                |
| Tab    | `TPushd`               | `TPopd`               |
| Window | `LPushd`               | `LPopd`               |

The push directory commands push a given path onto the stack and the pop directory commands pop the latest path off the
stack. Both commands will change your current directory for their given scopes.

Invoking any push directory command (e.g. `Pushd`) without an argument will display the current paths on the stack.

All pop directory commands (e.g. `LPopd`) support receiving a number of times to pop items off the stack.
