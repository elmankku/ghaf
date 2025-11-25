# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ final, prev }:
prev.virtiofsd.overrideAttrs (oldAttrs: rec {
  version = "${oldAttrs.version}-iommu";

  # Use this until the feature is merged to mainline
  src = final.fetchFromGitLab {
    owner = "hreitz";
    repo = "virtiofsd-rs";
    rev = "iommu";
    hash = "sha256-laq+wYjNXTDDfMLEzeyqlPecgB++udqzBq1MhYOXSF8=";
  };

  cargoHash = "sha256-dZgFPwtXmPB7DJ6DX3i+++uanGczcrybN8BzTozt0Yo=";

  cargoDeps = final.rustPlatform.fetchCargoVendor {
    inherit src version;
    hash = cargoHash;
  };

  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
    final.pkgs.rustPlatform.bindgenHook
  ];
})
