{
  lib,
  libCustom,
  ...
}: {
  namespace,
  outerArgs,
  enableOverride ? libCustom.enableCheckCurrentModule,
}:
# Utilities
let
  configGlobal = outerArgs.config;

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
    pathNamespace = [namesapce];
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
      options =
        options // {enable = lib.mkEnableOption description;};
      config = configs:
        lib.mkIf (enableOverride configs) (applyIfFunction config configs);
    };
}
