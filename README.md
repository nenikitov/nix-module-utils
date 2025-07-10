# nix-module-utils

Simple Nix module generator

## Usage

1. Add as an input to your flake

  ```nix
  {
    inputs = {
      moduleUtils = {
        url = "github:nenikitov/nix-module-utils";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };
    outputs = { /* ... */ };
  }
  ```

## Use cases

- Modify module arguments (to inject custom library)

  ```nix
  {
    inputs = { /* ... */ };
    outputs = {...} @ inputs: {
      nixosModules.myModule =
        inputs.moduleUtils.lib.overlayModule {
          overlayArgs = args:
            args
            // {
              someMagicConstant = 42;
              veryComplicatedUtilityFunction = x: x + 10;
            };
        }
        ./modules;
    };
  }
  ```

- Optionally add a configuration to module outputs

  ```nix
  {
    inputs = { /* ... */ };
    outputs = {...} @ inputs: {
      nixosModules.myModule = inputs.moduleUtils.lib.optionallyConfigureModule ({someMagicConstant ? 42}:
        _: { location.longitude = someMagicConstant; })
    };
  }
  ```

  Note:
  - All arguments to the module (in the example `someMagicConstant`) must be optional with a default value
  - Configuration arguments may not be any of `inputs`, `lib`, `config`, `options`, or `pkgs` because these names are used to check if configuration or real arguments are passed to the module
  - A module returned after configuration must itself be a function, not a path or a set. You may need to manually `import` it

- Minimize module boilerplate

  ```nix
  {
    inputs = { /* ... */ };
    outputs = {...} @ inputs: {
      nixosModules.myModule =
        inputs.moduleUtils.lib.overlayModule {
          overlayArgs = args:
            args
            // {
              libModule = inputs.moduleUtils.lib.libModule {
                # Namespace under which all options will reside
                namespace = "CUSTOM_NAMESPACE";
                # Boilerplate
                outerArgs = args;
                # Function that overwrites whether the current module should be enabled
                # - Takes in `{configGlobal, configNamespace, configModule, path}` (explained later), returns boolean
                # - Does not change the enable value by default (it is always false)
                # - Internally, it is the condition that is passed to `lib.mkIf` to set configurations made by the current module
                # - This flake provides `inputs.moduleUtils.lib.enableCheckCurrentModule` and `inputs.moduleUtils.lib.enableCheckCurrentModuleAndNamespace` utility functions
                # OPTIONAL: defaults to checking whether the current module is enabled (aka `inputs.moduleUtils.lib.enableCheckCurrentModule`)
                enableCheck = _: true;
              };
            };
        }
        ./modules;
    };
  }
  ```
  
  Then, `mkModule` will be available in module arguments and can be used like this
  
  ```nix
  {
    lib,
    libModule,
    ...
  }:
  libModule.mkEnableModule {
    # Description for `enable` option
    description = "my custom module";
    # Namespace from `overlayModule` + path will dictate the path to the module
    # OPTIONAL: defaults to `[]`
    path = ["settings" "mySetting"];
    # Additional options that the module defines
    # - Notice we don't need to have `enable` option - it is created automatically
    # OPTIONAL: defaults to `{}`
    options = {
      customOption = lib.mkOption {
        description = "An additional option";
        example = 0.2;
        type = lib.types.numbers.between (-180) 180;
      };
    };
    # Configurations module makes when enabled
    # - Notice we don't need to check for `enable` option - it is done automatically
    # - Can be an attribute set instead of a function if there is no need to reference any defined options
    # OPTIONAL: defaults to `{}`
    config = {
      # Any options defined globally, alias to `config` argument
      configGlobal,
      # Any options defined in the current namespace, alias to `config."${WHATEVER_NAMESPACE_IS}"`
      configNamespace,
      # Any options defined in the current module, alias to `config."${WHATEVER_NAMESPACE_IS}"."${WHATEVER}"."${PATH}"."${IS}"`
      configModule,
      # Path passed to this module
      path,
    }: {
      location.longitude = configLocal.customOption;
    };
  }
  ```

  There is a simpler `libModule.mkModule` function to generate a module without an `enable` option (it will always be enabled) that has the same signature minus the `description` argumnent.
