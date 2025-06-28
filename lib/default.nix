{lib, ...}: rec {
  enableCheckModule = {configModule, ...}: configModule.enable;
  enableCheckModuleAndGlobal = {
    configNamespace,
    configModule,
  }:
    configNamespace.enable && configModule.enable;

  scanModules = {
    namespace,
    dir,
    enableCheck ? enableCheckModule,
  }:
    lib.pipe dir [
      lib.filesystem.listFilesRecursive
      (builtins.filter (e: builtins.baseNameOf e == "default.nix"))
      (builtins.map (
        e: {config, ...} @ inputs: let
          namespaceModule = [namespace] ++ (lib.path.subpath.components (builtins.dirOf (lib.path.removePrefix dir e)));
          configNamespace = lib.attrByPath [namespace] {} config;
          configModule = lib.attrByPath namespaceModule {} config;
          configs = {inherit configNamespace configModule;};
          mkModule = {
            description,
            opts ? {},
            cfg ? _: {},
          }: {
            options =
              lib.setAttrByPath
              namespaceModule
              (opts // {enable = lib.mkEnableOption description;});
            config =
              lib.mkIf
              (enableCheck configs)
              (cfg configs);
          };
        in
          lib.pipe e [
            import
            (m:
              if builtins.isFunction m
              then m inputs
              else m)
            mkModule
          ]
      ))
    ];
}
