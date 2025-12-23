# Copyright 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  virtiofsd,
  fetchFromGitLab,
  ...
}:
virtiofsd.overrideAttrs (
  _finalAttrs: oldAttrs: rec {
    # Use this until the feature is merged to mainline
    src = fetchFromGitLab {
      owner = "hreitz";
      repo = "virtiofsd-rs";
      rev = "4adef6248a399006c06e55b51eb0a285449bbcdd";
      hash = "sha256-uBfX2w7nzXP/z7CPKXmxBEys/cCmLk1vm9uL+cEfYbo=";
    };

    cargoHash = "sha256-6fiYh3KwDDXhQ4wrn3+mzWjGDZdsrEhbp3k6hYDbTxs=";

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = cargoHash;
    };

    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
      pkgs.rustPlatform.bindgenHook
    ];
  }
)
