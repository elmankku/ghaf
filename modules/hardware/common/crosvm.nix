# SPDX-FileCopyrightText: 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    optionalAttrs
    types
    ;
in
{
  _file = ./crosvm.nix;

  options.ghaf.crosvm = {
    guivm = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra Crosvm arguments for GuiVM";
    };
    audiovm = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra Crosvm arguments for AudioVM";
    };
    netvm = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra Crosvm arguments for NetVM";
    };
  };

  config = {
    ghaf.crosvm = {
      guivm = optionalAttrs (config.ghaf.type == "host") {
        microvm.crosvm.extraArgs = [
          "--disable-sandbox"
          "--pci-hotplug-slots=32"
        ];
      };
    };
  };
}
