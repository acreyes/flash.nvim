# flash.nvim
A neovim plugin for a [FLASH Code](https://flash.rochester.edu/site/) development workflow.

## WIP

Not fully complete, if anyone uses this open a pull request or issue if you have any improvements.

## Workflow

* You have multiple object directories with different FLASH setup options
* Within each object directory you're managing multiple run directories with their own parfiles
* You want to move back and forth between all of these without having to `cd` all over the place to for example `resetup`, `make` and `mpirun` FLASH
* Make new run directories and automatically copy all the necessary `DATAFILES` and select different parfiles from the `Simulation` directory
* Open the source file from the object directory you're working from and follow the symbolic link
* Access easily the files in your run or simulation directory from neovim

## Installation

Use your favorite neovim plugin manager

* requires [Plenary](https://github.com/nvim-lua/plenary.nvim) and [Telescope](https://github.com/nvim-telescope/telescope.nvim)

```lua
-- using packer
use { 'acreyes/flash.nvim',
  requires = {
    {'nvim-telescope/telescope.nvim'},
    {'nvim-lua/plenary.nvim'},
  },
}
```

## Usage

```lua
vim.api.nvim_create_user_command('Flaunch',
    function(opts)
      local fl = require("flash")
      local ui = require("flash.ui")
      local prompt = require("flash.prompts")
      local buf = require("flash.buffers")

      local FLASH_DIR = os.getenv('FLASH_DIR')
      fl.init(FLASH_DIR)

      vim.keymap.set("n", "<leader><leader>k", buf.kill_all)
      vim.keymap.set("n", "<leader>si", buf.send_stdin)
      vim.keymap.set("n", "<leader>fj", buf.toggle_win)
      vim.keymap.set("n", "<leader>ps", prompt.pickSim)
      vim.keymap.set("n", "<leader>pr", prompt.pickRun)
      vim.keymap.set("n", "<leader>po", prompt.pickObj)
      vim.keymap.set("n", "<leader>sh", prompt.switch)
      vim.keymap.set("n", "<leader>sr", prompt.switchRD)
      vim.keymap.set("n", "<leader>es", prompt.editSetup)
    end,
    {nargs=0,
})

```

`flash.nvim` is initialized with `require'flash'.init()` by passing the path to where you have the FLASH Code. This will cause the plugin to load the state of the stack from the last save. The stack is saved anytime an operation is done to change it. The plugin manages two stacks, one for the object directories and then within each of those there is a stack for the run directories. The stack stores the setup arguments for each object directory.

Often you can have multiple versions of the FLASH code across different directories, that could be SVN branches or git worktrees. The cached setup of `flash.nvim` is shared amongst all of these
but on load or switching `HEAD` the plugin will attempt to rebuild the object directory structure based on the stored information in the cache.

### Setup FLASH simulation
```vim
:Fsetup
```

### Compile FLASH
```vim
:Fmake -j4
```

### Run FLASH
```vim
:Flash4        " serial
:Fmpirun -np 4 " parallel
```

### Managing the Stacks

* push a new object directory to the stack, creates `$FLASH_DIR/nvim/object_name`
  
  ```vim
  :Fpush name
  ```
  * opens telescope prompt to select the simulation from `source/Simulation/SimulationMain` to set up
  * followed by an input prompt for the setup arguments
  * Finally a prompt for the name of a run directory, not specifying any will use the object directory as the run directory if none are defined
    * Making a run directory will open a telescope prompt to select a `*.par` from your simulation directory
    * Afterwards all `DATAFILES` specified in `Config` files from `source/Simulation/SimulationMain` up to your simulation directory will be copied to the run directory

* You can change the active object directory
  ```vim
  :lua require'flash.prompts'.switch()
  ```
  * This opens a telescope prompt to select from the object directories in the stack

* Telescope prompts to pick files from any of the object, simulation or run direcotories can be opened
  ```vim
  :lua require'flash.prompts'.pickObj()
  :lua require'flash.prompts'.pickSim()
  :lua require'flash.prompts'.pickRun()
  ```

* You can add a new run directory
  ```vim
  :FaddRun RUN
  ```
  * adds the directory `RUN` to the run stack
  * Opens a telescope prompt to select a `*.par` from your simulation directory
  * Afterwards all `DATAFILES` specified in `Config` files from `source/Simulation/SimulationMain` up to your simulation directory will be copied to the run directory

* `flash.nvim` will detect if your setup arguments include anything that would use the `CMake` build system, in which case your run directory
   will double as the cmake build directory and you can
  ```vim
  :Fcmake (OPTS)
  ```
 
* You can switch the active run directory
  ```vim
  :lua require'flash.prompts'.switchRD()
  ```
  * which opens a telescope prompt to select a run directory
