{
  description = "Thinkfan UI (PyQt6)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        pythonEnv = pkgs.python3.withPackages (ps: [
          ps.pyqt6
        ]);

        launcher = pkgs.writeShellApplication {
          name = "thinkfan-ui";
          runtimeInputs = [
            pythonEnv
            pkgs.lm_sensors
            pkgs.polkit
            pkgs.xdg-utils
            pkgs.coreutils
          ];
          text = ''
            exec python ${./src/main.py} "$@"
          '';
        };

        desktopItem = pkgs.makeDesktopItem {
          name = "thinkfan-ui";
          desktopName = "Thinkfan UI";
          exec = "thinkfan-ui";
          icon = "thinkfan-ui";
          terminal = false;
          startupNotify = true;
          categories = [ "System" "Utility" ];
        };

        iconFiles = pkgs.runCommandNoCC "thinkfan-ui-icons" {} ''
          mkdir -p $out/share/icons/hicolor/scalable/apps
          cp ${./linux_packaging/thinkfan-ui.svg} $out/share/icons/hicolor/scalable/apps/thinkfan-ui.svg
        '';
      in
      {
        packages.default = pkgs.symlinkJoin {
          name = "thinkfan-ui";
          paths = [
            launcher
            desktopItem
            iconFiles
          ];
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/thinkfan-ui";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pythonEnv
            pkgs.lm_sensors
            pkgs.polkit
            pkgs.xdg-utils
          ];
        };
      });
}
