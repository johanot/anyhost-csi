{
  description = "anyhost-csi";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, nixpkgs, crane }:
  let
    pname = "anyhost-csi";
    version = "0.1.0";
    system = "x86_64-linux";
    crane-overlay = final: prev: {
      # crane's lib is not exposed as an overlay in its flake (should be added
      # upstream ideally) so this interface might be brittle, but avoids
      # accidentally passing a detached nixpkgs from its flake (or its follows)
      # on to consumers.
      craneLib = crane.mkLib prev;
    };
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ self.overlays.default crane-overlay ];
    };
    lib = nixpkgs.lib;
    buildInputs = with pkgs; [
      protobuf
    ];

    outputPackages = {
      ${pname} = {
        buildInputs = [
          "protobuf"
        ];
      };
    };
  in {
    packages.${system} = lib.mapAttrs (n: _: pkgs.${n}) outputPackages;
    defaultPackage.${system} = self.packages.${system}.${pname};

    overlays.default = final: prev:
    let
      cratePackage = name: opts:
        (final.craneLib.buildPackage {
          pname = name;
          inherit version;
          src = with final; lib.cleanSourceWith {
            src = ./.;
            filter = path: type: true;
          };
          nativeBuildInputs = with final; [
            pkg-config
          ];
          buildInputs = map (p: final.${p}) opts.buildInputs;
          cargoExtraArgs = opts.cargoExtraArgs or "";
        });
    in
      lib.mapAttrs cratePackage outputPackages;

    devShell.${system} = with pkgs; mkShell {
      PROTOC="${pkgs.protobuf}/bin/protoc";
      buildInputs = [
        cargo
        openssl.dev
        pkg-config
        rustc
        rustfmt
      ] ++ buildInputs;
    };
  };
}
