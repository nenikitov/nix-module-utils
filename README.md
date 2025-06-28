# nix-module-utils

Simple Nix module generator

## Usage

1. Add as an input to your flake

    ```nix
    {
    inputs = {
        moduleUtils = {
        url = "github:nenikitov/nix-module-utils"
        inputs.nixpkgs.follows = "nixpkgs"
        };
    };
    outputs = { /* ... */ };
    }
    ```

2. Use when outputting modules (works both with `nixosModules` and `homeManagerModules`)

    ```nix
    {
      inputs = { /* ... */ };
      outputs = {...} @ inputs: {
        nixosModules.myModule = inputs.moduleUtils.lib.scanModules {
          namespace = "CUSTOM";
          dir = ./modules;
        };
      };
    }
    ```

3. Create directory structure (explanations assume the example configuration)

    A module must be declared in a `default.nix` file whose path will be used as a namespace.
    For example, a `core/programs/ly/default.nix` module options will be exposed in `CUSTOM.core.programs.ly`.

    There must be no other `default.nix` files, and there is no need to list all modules in `imports = []`.

    **Examples**
    - Multiple nested modules
        ```tree
        modules/
        |-- core/
        |   `-- programs/
        |       |-- ly/
        |       |   `-- default.nix
        |       `-- grub/
        |           `-- default.nix
        `-- optional/
            `-- programs/
                |-- neovim/
                |   `-- default.nix
                `-- fastfetch/
                    `-- default.nix
        ```

4. Create module files

    Module declaration can be a set or a function returning a set that contains at least a `description` and a `cfg` function.
    Optionally, a declaration can add additional options through `opts`.

    An `enable` option will be automatically generated with the `description`, and `cfg` function will run only if the `enable` option was activated.
    There is no need to define it in `opts`, and there is no need to for `lib.mkIf` to check if the module is `enable`d.

    **Examples**
    - No additional options
        ```nix
        {
          description = "my custom module";
          cfg = {
            time.timeZone = "America/New_York";
          };
        }
        ```

    - Additional options
        ```nix
        {lib, config, ...}: {
          description = "my custom module";
          opts = {
            customOption = lib.mkOption {
              description = "An additional option";
              example = 0.2;
              type = lib.types.numbers.between - 180 180;
            };
          };
          cfg = {
            configNamespace,
            configLocal,
          }: {
            # Notice that at this point we have 3 `config` variables
            # - `config` can be used to access any values from the global scope
            # - `configNamespace` can be used to access values from all modules defined in the CUSTOM namespace
            # - `configLocal` can be used to access values defined in `opts` of this module
            location.longitude = configLocal.customOption;
          };
        }
        ```
