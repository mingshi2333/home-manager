{
  config,
  lib,
  pkgs,
  ...
}:

let
  types = lib.types;
  nvidiaVersionFile = ../nvidia/version;
  nvidiaHashFile = ../nvidia/hash;
  fcitxEnv = import ./fcitx-env.nix;
  nvidiaVersion =
    let
      versionMatch = builtins.match ".*  ([0-9]+\\.[0-9]+\\.[0-9]+)  .*" (
        builtins.readFile nvidiaVersionFile
      );
    in
    if versionMatch != null then
      builtins.head versionMatch
    else
      throw "Unable to parse NVIDIA version from nvidia/version";
  nvidiaHash =
    let
      hash = builtins.replaceStrings [ "\n" "\r" ] [ "" "" ] (builtins.readFile nvidiaHashFile);
    in
    if builtins.match "sha256-[A-Za-z0-9+/=]+" hash != null then
      hash
    else
      throw "Invalid NVIDIA hash in nvidia/hash";
  nixglPackages = pkgs.callPackage ../nixgl-noimpure.nix {
    inherit
      nvidiaVersionFile
      nvidiaVersion
      nvidiaHash
      ;
  };
  nixGLPackage = nixglPackages.nixGLNvidia;
  nixGLBin = "${nixGLPackage}/bin/nixGLNvidia-${nvidiaVersion}";
  nixglApps = import ../nixgl-apps.nix {
    inherit
      config
      pkgs
      nixGLBin
      fcitxEnv
      ;
  };
  dedupApps = (builtins.attrNames nixglApps.desktopEntries) ++ [
    "telegram-desktop"
    "org.telegram.desktop"
    "telegram"
  ];
in
{
  options.local.nixgl = {
    enabledApps = lib.mkOption {
      type = types.listOf types.str;
      readOnly = true;
    };
    fcitxEnv = lib.mkOption {
      type = types.attrsOf types.str;
      readOnly = true;
    };
    nvidiaVersion = lib.mkOption {
      type = types.str;
      readOnly = true;
    };
    nvidiaHash = lib.mkOption {
      type = types.str;
      readOnly = true;
    };
    package = lib.mkOption {
      type = types.package;
      readOnly = true;
    };
    bin = lib.mkOption {
      type = types.str;
      readOnly = true;
    };
    appPackages = lib.mkOption {
      type = types.listOf types.package;
      readOnly = true;
    };
    compatibilityPolicies = lib.mkOption {
      type = types.attrsOf types.anything;
      readOnly = true;
    };
    appInventory = lib.mkOption {
      type = types.attrsOf types.anything;
      readOnly = true;
    };
    electronRepairProfiles = lib.mkOption {
      type = types.attrsOf types.anything;
      readOnly = true;
    };
    shellAliases = lib.mkOption {
      type = types.attrsOf types.str;
      readOnly = true;
    };
    binScripts = lib.mkOption {
      type = types.attrsOf types.anything;
      readOnly = true;
    };
    desktopEntries = lib.mkOption {
      type = types.attrsOf types.anything;
      readOnly = true;
    };
    mimeAssociations = lib.mkOption {
      type = types.attrsOf types.anything;
      readOnly = true;
    };
    dedupApps = lib.mkOption {
      type = types.listOf types.str;
      readOnly = true;
    };
  };

  config.local.nixgl = {
    enabledApps = nixglApps.enabledApps;
    inherit
      fcitxEnv
      nvidiaVersion
      nvidiaHash
      dedupApps
      ;
    package = nixGLPackage;
    bin = nixGLBin;
    appPackages = nixglApps.packages;
    compatibilityPolicies = nixglApps.compatibilityPolicies;
    appInventory = nixglApps.appInventory;
    electronRepairProfiles = nixglApps.electronRepairProfiles;
    shellAliases = nixglApps.shellAliases;
    binScripts = nixglApps.binScripts;
    desktopEntries = nixglApps.desktopEntries;
    mimeAssociations = nixglApps.mimeAssociations;
  };
}
