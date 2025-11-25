# Copyright 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  pkgs,
  qboot,
  fetchFromGitHub,
  ...
}:
# The package is x86_64 only; workaround for `nix flake show`.
if !stdenv.isx86_64 then
  (pkgs.runCommand "qboot-pkvm-unsupported" { } "mkdir $out").overrideAttrs (old: {
    meta = (old.meta or { }) // {
      platforms = [ "x86_64-linux" ];
    };
  })
else
  qboot.overrideAttrs (
    _finalAttrs: oldAttrs: {
      pname = oldAttrs.pname + "-pkvm";
      version = "unstable-2022-09-19";

      src = fetchFromGitHub {
        inherit (oldAttrs.src) owner;
        inherit (oldAttrs.src) repo;
        rev = "8ca302e86d685fa05b16e2b208888243da319941";
        sha256 = "sha256-YxVGFiyLdhq7yWaXARh7f0nBZgXfJuYvv1BxfyThupM=";
      };

      patches = [
        ./0001-qboot-Add-support-for-booting-pKVM-protected-VMs.patch
      ];
    }
  )
