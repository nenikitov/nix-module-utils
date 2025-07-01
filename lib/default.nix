{lib, ...}: rec {
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

  mkModule = namespace: argsConfig: {
    description,
    path ? [],
    config ? {},
    options ? {},
    enableCheck ? enableCheckCurrentModule,
  }: let
    namespaceModule = [namespace] ++ path;
    configs = {
      configGlobal = config;
      configNamespace = lib.attrByPath [namespace] {} argsConfig;
      configModule = lib.attrByPath namespaceModule {} argsConfig;
    };
  in {
    options =
      lib.setAttrByPath
      namespaceModule
      (options // {enable = lib.mkEnableOption description;});
    config =
      lib.mkIf
      (enableCheck configs)
      (
        if builtins.isFunction config
        then config configs
        else config
      );
  };

  enableCheckCurrentModule = {configModule, ...}: configModule.enable;
  enableCheckCurrentModuleAndNamespace = {configNamespace, ...}@args: configNamespace.enable && (enableCheckCurrentModule args);
}
