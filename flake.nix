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
            pkgs.qt6.qtbase
            pkgs.qt6.qtwayland
            pkgs.lm_sensors
            pkgs.polkit
            pkgs.xdg-utils
            pkgs.coreutils
          ];
          text = ''
            # On NixOS, pkexec must come from wrappers to keep setuid.
            if [ -x /run/wrappers/bin/pkexec ]; then
              export PATH="/run/wrappers/bin:$PATH"
            fi

            # Ensure Qt platform plugins are visible when launching from profile/desktop.
            export QT_PLUGIN_PATH="${pkgs.qt6.qtbase}/lib/qt-6/plugins:${pythonEnv}/${pkgs.python3.sitePackages}/PyQt6/Qt6/plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
            export QT_QPA_PLATFORM="wayland;xcb"

            exec python ${./src}/main.py "$@"
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

        iconFiles = pkgs.runCommand "thinkfan-ui-icons" {} ''
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
            pkgs.qt6.qtbase
            pkgs.qt6.qtwayland
            pkgs.lm_sensors
            pkgs.polkit
            pkgs.xdg-utils
          ];
          shellHook = ''
            export QT_PLUGIN_PATH="${pkgs.qt6.qtbase}/lib/qt-6/plugins:${pythonEnv}/${pkgs.python3.sitePackages}/PyQt6/Qt6/plugins''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
            export QT_QPA_PLATFORM="wayland;xcb"
          '';
        };
      });
}
