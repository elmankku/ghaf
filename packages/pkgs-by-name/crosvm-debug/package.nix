# SPDX-FileCopyrightText: 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  crosvm,
  ...
}:
let
  localSrc = builtins.getEnv "GHAF_CROSVM_SRC";
  srcPath =
    if localSrc == "" then
      throw ''
        GHAF_CROSVM_SRC is not set.
        Example:
          GHAF_CROSVM_SRC=$PWD/crosvm nix build --impure .#crosvm-debug
      ''
    else
      /. + localSrc;
in
crosvm.overrideAttrs (_finalAttrs: oldAttrs: {
  pname = "crosvm-debug";
  version = "${oldAttrs.version}-local";
  src = builtins.path {
    path = srcPath;
    name = "crosvm-local-source";
  };
  patches = [ ];
})
