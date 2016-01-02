#!/bin/bash
## INFO ##
## INFO ##

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Constants
HELP="\
\033[1mNAME\033[0m

    install.sh - build and install project

\033[1mSYNOPSIS\033[0m

    install.sh [options]

\033[1mOPTIONS\033[0m

    \033[1m-c\033[0m CC          Specify C compiler
    \033[1m--compiler\033[0m CC  (default: gcc)

    \033[1m-i\033[0m PATH        Specify header install location
    \033[1m--include\033[0m PATH (default: /usr/local/include)

    \033[1m-l\033[0m PATH        Specify library install location
    \033[1m--library\033[0m PATH (default: /usr/local/lib)

    \033[1m-r\033[0m             Uninstall previously installed files
    \033[1m--remove\033[0m

    \033[1m-h\033[0m             Print this text
    \033[1m--help\033m
";
BUILD_DIR="build-install";
CONFIG_FILE="install.conf";


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Exit if any command failed
set -e;


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Set default values
compiler="gcc";
include="/usr/local/include";
library="/usr/local/lib";
remove="";

# Update values from config
if [ -f "$CONFIG_FILE" ];
then
    printf "[0] Reading configuration file ... ";
    # If free and UNIX-like platform
    if [ "$OSTYPE" == "linux-gnu" ] || [ "$OSTYPE" == "freebsd"* ];
    then
        # Set compiler if it is defined in config
        unix_compiler=`grep "^unix_compiler=.*$" "$CONFIG_FILE"`;
        unix_compiler=${unix_compiler:14};
        if [ -n "$unix_compiler" ];
        then
            compiler="$unix_compiler";
        fi;

        # Set include-path if it is defined in config
        unix_include=`grep "^unix_include=.*$" "$CONFIG_FILE"`;
        unix_include=${unix_include:13};
        if [ -n "$unix_include" ];
        then
            include="$unix_include";
        fi;

        # Set library-path if it is defined in config
        unix_library=`grep "^unix_library=.*$" "$CONFIG_FILE"`;
        unix_library=${unix_library:13};
        if [ -n "$unix_library" ];
        then
            library="$unix_library";
        fi;

    # If Mac OS X
    elif [ "$OSTYPE" == "darwin"* ];
    then
        # Set compiler if it is defined in config
        mac_compiler=`grep "^mac_compiler=.*$" "$CONFIG_FILE"`;
        mac_compiler=${mac_compiler:13};
        if [ -n "$mac_compiler" ];
        then
            compiler="$mac_compiler";
        fi;

        # Set include-path if it is defined in config
        mac_include=`grep "^mac_include=.*$" "$CONFIG_FILE"`;
        mac_include=${mac_include:12};
        if [ -n "$mac_include" ];
        then
            include="$mac_include";
        fi;

        # Set library-path if it is defined in config
        mac_library=`grep "^mac_library=.*$" "$CONFIG_FILE"`;
        mac_library=${mac_library:12};
        if [ -n "$mac_library" ];
        then
            library="$mac_library";
        fi;

    # If windows
    elif [ "$OSTYPE" == "win32" ];
    then
        # Set compiler if it is defined in config
        win_compiler=`grep "^win_compiler=.*$" "$CONFIG_FILE"`;
        win_compiler=${win_compiler:13};
        if [ -n "$win_compiler" ];
        then
            compiler="$win_compiler";
        fi;

        # Set include-path if it is defined in config
        win_include=`grep "^win_include=.*$" "$CONFIG_FILE"`;
        win_include=${win_include:12};
        if [ -n "$win_include" ];
        then
            include="$win_include";
        fi;

        # Set library-path if it is defined in config
        win_library=`grep "^win_library=.*$" "$CONFIG_FILE"`;
        win_library=${win_library:12};
        if [ -n "$win_library" ];
        then
            library="$win_library";
        fi;
    fi;
    printf "DONE\n";
fi;


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Parse arguments
printf "[1] Reading passed arguments ... ";
while [ -n "$1" ];
do
    if [ "$1" == "-c" ] || [ "$1" == "--compiler" ];
    then
        shift;
        compiler="$1";
    elif [ "$1" == "-i" ] || [ "$1" == "--include" ];
    then
        shift;
        include="$1";
    elif [ "$1" == "-l" ] || [ "$1" == "--library" ];
    then
        shift;
        library="$1";
    elif [ "$1" == "-r" ] || [ "$1" == "--remove" ];
    then
        remove="yes";
    elif [ "$1" == "-h" ] || [ "$1" == "--help" ];
    then
        printf "$HELP";
        exit;
    else
        printf "Invalid argument: $1\n";
        exit 1;
    fi;
    shift;
done;
printf "DONE\n";


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
__build()
{
    # Compile sources to objects
    mkdir -p $BUILD_DIR/build;
    for source in src/*.c;
    do
        printf "    Compiling $source ... ";
        fname=$(basename "$source");
        fname="${fname%.*}";
        $compiler -std=c11 \
                  -O3 \
                  -Iinclude \
                  -lpthread \
                  -fPIC \
                  -o $BUILD_DIR/build/$fname.o \
                  -c $source;
        printf "DONE\n";
    done;

    # Create both static and dynamic libraries
    printf "    Creating temporary dir '$BUILD_DIR/lib' ... ";
    mkdir -p $BUILD_DIR/lib;
    printf "DONE\n";
    printf "    Creating shared library '$BUILD_DIR/lib/lib$1.so' ... ";
    $compiler -shared \
              -o $BUILD_DIR/lib/lib$1.so \
              $BUILD_DIR/build/*.o;
    printf "DONE\n";
    printf "    Creating static library '$BUILD_DIR/lib/lib$1.a' ... ";
    ar rcs \
       -o $BUILD_DIR/lib/lib$1.a \
       $BUILD_DIR/build/*.o;
    printf "DONE\n";
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
__remove()
{
    sudo printf "    Removing header(s) and directory '$include/$1' ... ";
    sudo rm -rf "$include/$1";
    printf "DONE\n";
    printf "    Removing librari(es) '$library/lib$2*' ... ";
    sudo rm -f "$library/lib$2*";
    printf "DONE\n";
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
__install()
{
    sudo printf "    Copying header(s) to '$include/$1' ... ";
    sudo cp -r include/$1 $include;
    printf "DONE\n";
    printf "    Copying librari(es) to '$library/lib$2*' ... ";
    sudo cp $BUILD_DIR/lib/lib$2* $library;
    printf "DONE\n";
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
mininstall()
{
    if [ -z "$1" ];
    then
        printf "Missing arg(s): mininstall <include_dir> [<lib_name>]";
        exit;
    elif [ -z "$2" ];
    then
        lib_name="$1";
    fi;
    include_dir="$1";

    if [ -n "$remove" ];
    then
        printf "[2] Uninstalling lib$lib_name:\n";
        __remove $include_dir $lib_name;
        printf " -> lib$lib_name successfully removed!\n";
    else
        # Build library
        printf "[2] Building lib$lib_name:\n";
        __build "$lib_name";
        printf " -> lib$lib_name successfully built!\n";

        # Install library
        printf "[3] Installing lib$lib_name:\n";
        __install $include_dir $lib_name;
        printf " -> lib$lib_name successfully installed!\n";
    fi;
}
