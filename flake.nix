{
  description = "Build FreeCAD with Qt6 using Nix Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }: {
    devShell.x86_64-linux =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      in pkgs.mkShell {
        buildInputs = [
          pkgs.cmake
          pkgs.ccache
          pkgs.swig
          pkgs.ninja
          pkgs.qt6.qtbase
          pkgs.qt6.qttools
          pkgs.qt6.qtsvg
          pkgs.qt6.qtdeclarative
          pkgs.boost
          pkgs.python312
          pkgs.python312Packages.pyside6
          pkgs.python312Packages.boost
          pkgs.python312Packages.shiboken6
          pkgs.python312Packages.matplotlib
          pkgs.python312Packages.pivy
          pkgs.python312Packages.pybind11
          pkgs.python312Packages.gmsh
          pkgs.coin3d
          pkgs.opencascade-occt
          pkgs.zlib
          pkgs.yaml-cpp
          pkgs.xercesc
          pkgs.libGLU
          pkgs.vtk
          pkgs.medfile
          pkgs.hdf5
          pkgs.eigen
          pkgs.libspnav
          pkgs.mpi
        ];

        shellHook = ''
          echo "Entering FreeCAD development shell with Qt6 support"
          export QT_PLUGIN_PATH=${pkgs.qt6.qtbase}/lib/qt6/plugins
        '';
      };
  };
}

