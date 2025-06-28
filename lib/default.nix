{
  lib,
  libCustom,
  ...
}: rec {
  scanModules = {
    namespace,
    dir,
  }:
    lib.pipe dir [
      lib.filesystem.listFilesRecursive
      (builtins.filter (e: builtins.baseNameOf e == "default.nix"))
      (builtins.map (e: {
        dir = lib.path.subpath.components (builtins.dirOf (lib.path.removePrefix dir e));
        path = e;
      }))
      # Print
      #(e: builtins.trace e e)
    ];
}
