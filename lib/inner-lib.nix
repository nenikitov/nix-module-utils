{
  lib,
  libCustom,
  ...
}: {
  namespace,
  args,
  enableOverride ? libCustom.enableCheckCurrentModule,
}:
# Utilities
let
  configGlobal = args.config;

  applyIfFunction = obj: args:
    if builtins.isFunction obj
    then obj args
    else obj;

  mkConfigs = path: rec {
    inherit configGlobal path;
    configNamespace = configGlobal."${namespace}";
    configModule = lib.attrByPath path {} configNamespace;
  };
in rec
# Lib
{
  scanDir = { dir, exclude ? [] }: let
    excludeList = if builtins.isList exclude then exclude else [exclude];
  in lib.pipe dir [
    builtins.readDir
    builtins.attrNames
    (builtins.map (lib.path.append dir))
    (builtins.filter (p: !builtins.elem p excludeList))
  ];

  # Create a module without `enable` option
  mkModule = {
    path ? [],
    options ? {},
    config ? {},
  }: {
    options."${namespace}" =
      lib.setAttrByPath
      path
      options;
    config =
      applyIfFunction
      config
      (mkConfigs path);
  };

  # Create a module that depends on other module `enable` option
  mkEnableSubmodule = {
    path ? [],
    pathParent ? [],
    options ? {},
    config ? {},
  }: let
      configsParent = mkConfigs pathParent;
    in
    mkModule {
      inherit path options;
      config = configs:
        lib.mkIf
        (enableOverride configsParent)
        (applyIfFunction config ({
          inherit pathParent;
          configModuleParent = configsParent.configModule;
        } // configs));
    };

  mkEnableModule = {
    description ? [],
    defaultEnable ? false,
    path ? [],
    options ? {},
    config ? {},
  }:
    mkModule {
      inherit path;
      options = options // {
        enable = (lib.mkEnableOption description) // { default = defaultEnable; };
      };
      config = configs:
        lib.mkIf
        (enableOverride (mkConfigs path))
        (applyIfFunction config configs);
    };
}
