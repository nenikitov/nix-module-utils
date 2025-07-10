{lib, ...} @ argsFlake: rec {
  overlayModule = {
    overlayArgs ? lib.id,
    overlayResults ? lib.id,
  }: module: args: {
    imports = lib.pipe module [
      (m: lib.modules.collectModules "" [module] (overlayArgs args))
      (map (m:
        lib.pipe m [
          (lib.filterAttrs (k: v: lib.elem k ["options" "config"]))
          overlayResults
          (lib.modules.setDefaultModuleLocation m._file)
        ]))
    ];
  };

  optionallyConfigureModule = module: args:
    if builtins.any (a: builtins.hasAttr a args) ["inputs" "lib" "config" "options" "pkgs"]
    then module {} args
    else module args;

  libModule = import ./inner-lib argsFlake;

  enableCheckCurrentModule = {configModule, ...}: configModule.enable;

  enableCheckCurrentModuleAndNamespace = {configNamespace, ...} @ args: configNamespace.enable && (enableCheckCurrentModule args);
}
