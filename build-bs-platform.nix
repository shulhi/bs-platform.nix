{ stdenv, fetchFromGitHub, ninja, runCommand, nodejs, python3,
  ocaml-version, version, src,
  ocaml ? (import ./ocaml.nix {
    version = ocaml-version;
    inherit stdenv;
    src = "${src}/ocaml";
  }),
  custom-ninja ? (ninja.overrideAttrs (attrs: {
    src = runCommand "ninja-patched-source" {} ''
      mkdir -p $out
      tar zxvf ${src}/vendor/ninja.tar.gz -C $out
    '';
    patches = [];
  }))
}:
stdenv.mkDerivation {
  inherit src version;
  pname = "bs-platform";
  BS_RELEASE_BUILD = "true";
  buildInputs = [ nodejs python3 custom-ninja ];

  patchPhase = ''
    sed -i 's:./configure.py --bootstrap:python3 ./configure.py --bootstrap:' ./scripts/install.js

    mkdir -p ./native/${ocaml-version}/bin
    ln -sf ${ocaml}/bin/*  ./native/${ocaml-version}/bin
  '';

  dontConfigure = true;

  buildPhase = ''
    # release build https://github.com/BuckleScript/bucklescript/issues/4091#issuecomment-574514891
    node scripts/install.js
  '';

  installPhase = ''
    mkdir -p $out/bin

    cp -rf jscomp lib linux vendor odoc_gen native $out
    cp bsconfig.json package.json $out

    ln -s $out/linux/bsb.exe $out/bin/bsb
    ln -s $out/linux/bsb_helper.exe $out/bin/bsb_helper
    ln -s $out/linux/bsc.exe $out/bin/bsc
    ln -s $out/linux/refmt.exe $out/bin/bsrefmt
    ln -s $out/linux/refmt.exe $out/bin/refmt
  '';
}
