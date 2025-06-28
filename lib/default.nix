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
  }: {
    # HACK: `pkgs` aren't passed down if they aren't explicitely declared here
    pkgs,
    config,
    ...
  } @ inputs:
    lib.pipe dir [
      lib.filesystem.listFilesRecursive
      (builtins.filter (p: builtins.baseNameOf p == "default.nix"))
      (builtins.map (
        p: let
          namespaceModule = [namespace] ++ (lib.path.subpath.components (builtins.dirOf (lib.path.removePrefix dir p)));
          configs = {
            configNamespace = lib.attrByPath [namespace] {} config;
            configModule = lib.attrByPath namespaceModule {} config;
          };
          mkModule = {
            description,
            opts ? {},
            cfg ? {},
          }: {
            options =
              lib.setAttrByPath
              namespaceModule
              (opts // {enable = lib.mkEnableOption description;});
            config =
              lib.mkIf
              (enableCheck configs)
              (
                if builtins.isFunction cfg
                then cfg configs
                else cfg
              );
          };
        in
          lib.pipe p [
            import
            (m:
              if builtins.isFunction m
              then (m inputs)
              else m)
            mkModule
          ]
      ))
      (m: {
        options = lib.pipe m [
          (builtins.map (m: m.options))
          (builtins.foldl' lib.recursiveUpdate {})
        ];
        config = lib.pipe m [
          (builtins.map (m: m.config))
          lib.mkMerge
        ];
      })
    ];
}
