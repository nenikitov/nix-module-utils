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
in rec
# Lib
{
  mkModule = {
    path ? [],
    config ? {},
    options ? {},
  }: let
    pathNamespace = [namespace];
    pathModule = pathNamespace ++ path;
    configs = {
      inherit configGlobal path;
      configNamespace = lib.attrByPath pathNamespace {} configGlobal;
      configModule = lib.attrByPath pathModule {} configGlobal;
    };
  in {
    options =
      lib.setAttrByPath
      pathModule
      options;
    config =
      applyIfFunction
      config
      configs;
  };

  mkEnableModule = {
    description,
    path ? [],
    config ? {},
    options ? {},
  }:
    mkModule {
      inherit path;
      options =
        options // {enable = lib.mkEnableOption description;};
      config = configs:
        lib.mkIf (enableOverride configs) (applyIfFunction config configs);
    };
}
