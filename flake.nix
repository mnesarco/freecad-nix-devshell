# MIT License
#
# Copyright (c) 2024 Frank David Martinez Muñoz <mnesarco>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

{
  description = "Build FreeCAD with Qt6 using Nix Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      commonBuildInputs = pkgs:
        let
          pythonEnv = pkgs.python312.withPackages (ps: with ps; [
            pip
            setuptools
            wheel
            boost
            pyside6
            shiboken6
            matplotlib
            pivy
            pybind11
            gmsh
            setuptools
            numpy
          ]);

        in [

        # ------------------------
        # Python
        # ------------------------
        pythonEnv

        # ------------------------
        # Compilers
        # ------------------------
        pkgs.cmake
        pkgs.ccache
        pkgs.swig
        pkgs.ninja
        pkgs.llvmPackages_19.clang-tools

        # ------------------------
        # Qt6
        # ------------------------
        pkgs.qt6.full
        pkgs.qt6.qttools

        # ------------------------
        # Libs
        # ------------------------
        pkgs.boost
        pkgs.coin3d
        pkgs.opencascade-occt
        pkgs.zlib
        pkgs.yaml-cpp
        pkgs.xercesc
        pkgs.vtk
        pkgs.medfile
        pkgs.hdf5
        pkgs.eigen
        pkgs.libspnav
        pkgs.mpi

        # ------------------------
        # OpenGL
        # ------------------------
        pkgs.libGLU
        pkgs.libGL

        # ------------------------
        # X11 runtime
        # ------------------------
        pkgs.xorg.libxcb
        pkgs.xorg.xcbutil
        pkgs.xorg.xcbutilwm
        pkgs.xorg.xcbutilimage
        pkgs.xorg.xcbutilkeysyms
        pkgs.xorg.xcbutilrenderutil
        pkgs.xorg.libXinerama
        pkgs.xcb-util-cursor
        pkgs.xorg.libX11


        # ------------------------
        # TODO: Missing deps
        # ------------------------
        # pkgs.rPackages.netgen  !!! Broken pkg


      ];

      createDevShell = system: shellName:
        let
          pkgs = import nixpkgs { system = system; };
          packages = commonBuildInputs pkgs;

        in pkgs.mkShell {
          LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
          packages = packages;
          buildInputs = packages;
          shellHook = ''
            echo "Entering FreeCAD development shell with Qt6 support (${shellName})"

            # Setup QT ------------------------------------------------
            export QT_PLUGIN_PATH=${pkgs.qt6.qtbase}/lib/qt-6/plugins
            export QT_DEBUG_PLUGINS=0
            export DISPLAY=:0

            # Setup Shell ---------------------------------------------
            export PS1="\e[0;32mnix:\e[0m\e[0;36m\W\e[0m\$ "
            export DEVSHELL=${pkgs.bash}/bin/bash

            # Setup Python --------------------------------------------
            export PYLIB0=$(dirname $(dirname "$(which python)"))

            # Setup FreeCAD -------------------------------------------
            export FREECAD_REPO="https://github.com/FreeCAD/FreeCAD.git"
            export BUILD_BASE="$(pwd)"
            export FREECAD_USER_HOME="$BUILD_BASE/var"
            mkdir -p $FREECAD_USER_HOME

            alias clone="cd $BUILD_BASE && git clone $FREECAD_REPO && cd FreeCAD && git submodule update --init --recursive"
            alias config="mkdir -p $BUILD_BASE/build && cd $BUILD_BASE/build && cmake -GNinja -DFREECAD_USE_PYBIND11=ON -DCMAKE_INSTALL_PREFIX=/usr/local $BUILD_BASE/FreeCAD"
            alias compile="cmake --build $BUILD_BASE/build"
            alias freecad="$BUILD_BASE/build/bin/FreeCAD -P $PYLIB0/lib -P $PYLIB0/lib/python3.12/site-packages"
          '';
        };

    in {
      devShell.x86_64-linux = createDevShell "x86_64-linux" "Linux";
      devShell.aarch64-linux = createDevShell "aarch64-linux" "ARM Linux";
      devShell.x86_64-darwin = createDevShell "x86_64-darwin" "macOS";
    };
}
