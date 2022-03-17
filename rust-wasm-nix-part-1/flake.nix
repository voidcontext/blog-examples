{
  description = "Developing a Rust WebAssembly project using nix";

  # Use the current stable release of nixpkgs
  inputs.nixpkgs.url = "nixpkgs/release-21.11";

  # flake-utils helps removing some boilerplate
  inputs.flake-utils.url = "github:numtide/flake-utils";

  # Oxalica's rust overlay to easyly add rust build targets using rustup from nix
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";
  inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";


  outputs = { self, ... }@inputs:
    # In nix flakes we'd need to define outputs for each system
    # individually, see https://nixos.wiki/wiki/Flakes#Output_schema
    # flake-utils helps removing this boilerplate
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ inputs.rust-overlay.overlay ];

        pkgs = import inputs.nixpkgs { inherit system overlays; };

        rustWithWasmTarget = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

        rustPackages = [
          rustWithWasmTarget
          pkgs.binaryen
          pkgs.wasm-bindgen-cli
        ];

      in
      {
        # expose cargo so that we can run the cargo commands from our shell
        apps.cargo = {
          type = "app";
          program = "${pkgs.cargo}/bin/cargo";
        };

        defaultPackage = pkgs.rustPlatform.buildRustPackage {
          pname = "rust-wasm-hello-world";
          version = "0.1.1";

          src = ./.;

          cargoLock = {
            lockFile = ././Cargo.lock;
          };

          nativeBuildInputs = rustPackages;

          buildPhase = ''
            cargo build --target=wasm32-unknown-unknown --release &&              \
            wasm-bindgen                                                          \
              --target web                                                        \
              --out-dir dist                                                      \
              target/wasm32-unknown-unknown/release/rust_wasm_hello_world.wasm

          '';

          installPhase = ''
            mkdir -p $out/js                               && \
            cp dist/rust_wasm_hello_world.js $out/js/      && \
            cp dist/rust_wasm_hello_world_bg.wasm $out/js  && \

            cp index.html $out/
          '';

          doCheck = false;

        };

        devShell = pkgs.mkShell {
          packages = rustPackages ++ [
            pkgs.rust-analyzer
          ];
        };
      }
    );
}
