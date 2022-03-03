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
      in
      {
        # expose cargo so that we can run the cargo commands from our shell
        apps.cargo = {
          type = "app";
          program = "${pkgs.cargo}/bin/cargo";
        };

        devShell = pkgs.mkShell {
          packages = [
            rustWithWasmTarget
            pkgs.binaryen
            pkgs.wasm-bindgen-cli
          ];
        };
      }
    );
}
