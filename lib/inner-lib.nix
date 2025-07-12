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
  }:
    mkModule {
      inherit path options;
      config = configs:
        lib.mkIf
        (enableOverride (mkConfigs pathParent))
        (applyIfFunction config configs);
    };

  mkEnableModule = {
    description,
    path ? [],
    config ? {},
    options ? {},
  }:
    mkEnableSubmodule {
      inherit path config;
      pathParent = path;
      options = options // {enable = lib.mkEnableOption description;};
    };
}
