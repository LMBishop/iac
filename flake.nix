{
  description = "IaC for selfhosted stuff";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, deploy-rs }: {
    deploy.nodes.bounce = {
      hostname = "10.42.0.1";
      # magicRollback = false;
      profiles = {
        system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.bounce;
          user = "root";
        };
      };
    };

    nixosConfigurations.bounce = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./bounce/configuration.nix
      ];
    };

    devShells.x86_64-linux.default =
      let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in
      pkgs.mkShell {
        buildInputs = [
          deploy-rs.packages.x86_64-linux.default
        ];
      };
  };
}
