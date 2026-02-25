# SPDX-FileCopyrightText: 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# pKVM target constructors.
#
# pKVM with Intel IOMMU scalable mode enabled depend on NEST support. Some
# platforms, like X1 Carbon Gen12, lack that and must use IOMMU legacy mode
# (sm_off).
{ lib }:
let
  mkPkvmTarget =
    t:
    t
    // rec {
      name = "${lib.removeSuffix "-${t.variant}" t.name}-pkvm-${t.variant}";
      hostConfiguration = t.hostConfiguration.extendModules {
        modules = [
          {
            ghaf.virtualization.pkvm.enable = true;
          }
        ];
      };
      package = hostConfiguration.config.system.build.ghafImage;
    };

  mkPkvmSmOffTarget =
    t:
    let
      kernelParams = t.hostConfiguration.config.ghaf.hardware.definition.host.kernelConfig.kernelParams;
      intelIommuParams = lib.filter (param: lib.hasPrefix "intel_iommu=" param) kernelParams;
      overriddenKernelParams =
        if intelIommuParams != [ "intel_iommu=on,sm_on" ] then
          throw "pKVM Intel IOMMU override requires exactly intel_iommu=on,sm_on"
        else
          map (
            param: if lib.hasPrefix "intel_iommu=" param then "intel_iommu=on,sm_off" else param
          ) kernelParams;
      pkvmTarget = mkPkvmTarget t;
    in
    pkvmTarget
    // rec {
      name = "${lib.removeSuffix "-${t.variant}" t.name}-pkvm-sm-off-${t.variant}";
      hostConfiguration = pkvmTarget.hostConfiguration.extendModules {
        modules = [
          {
            ghaf.hardware.definition.host.kernelConfig.kernelParams = lib.mkForce overriddenKernelParams;
          }
        ];
      };
      package = hostConfiguration.config.system.build.ghafImage;
    };
in
{
  inherit mkPkvmTarget mkPkvmSmOffTarget;
}
