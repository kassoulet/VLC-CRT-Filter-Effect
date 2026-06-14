#!/bin/bash
# ============================================================================
#  Install CRT Scanline plugin + Lua controller to VLC on Linux
# ============================================================================

set -e

PLUGIN_NAME="libcrt_scanline_plugin.so"
LUA_NAME="crt_scanline_controller.lua"
BUILD_DIR="./build"
LUA_DIR="./lua"

USE_USER_PATH=false
if [[ "$1" == "--user" ]]; then
    USE_USER_PATH=true
fi

# Attempt to find VLC plugin directory
if [ "$USE_USER_PATH" = true ]; then
    VLC_PLUGIN_DIR="$HOME/.local/share/vlc/plugins/video_filter"
    VLC_DATA_DIR="$HOME/.local/share/vlc"
    SUDO=""
else
    if pkg-config --exists vlc-plugin; then
        VLC_PLUGIN_DIR="$(pkg-config --variable=libdir vlc-plugin)/vlc/plugins/video_filter"
        VLC_DATA_DIR="$(pkg-config --variable=datadir vlc-plugin)"
    else
        # Fallback paths for common distributions
        VLC_PLUGIN_DIR="/usr/lib/vlc/plugins/video_filter"
        VLC_DATA_DIR="/usr/share/vlc"
        
        if [ ! -d "/usr/lib/vlc" ] && [ -d "/usr/lib/x86_64-linux-gnu/vlc" ]; then
            VLC_PLUGIN_DIR="/usr/lib/x86_64-linux-gnu/vlc/plugins/video_filter"
        fi
    fi
    SUDO="sudo"
fi

if [ ! -f "$BUILD_DIR/$PLUGIN_NAME" ]; then
    echo "ERROR: Plugin not built yet. Run 'make' first."
    exit 1
fi

echo "Installing video filter plugin to $VLC_PLUGIN_DIR..."
$SUDO mkdir -p "$VLC_PLUGIN_DIR"
$SUDO cp "$BUILD_DIR/$PLUGIN_NAME" "$VLC_PLUGIN_DIR/"

echo "Installing Lua controller extension..."
if [ "$USE_USER_PATH" = true ]; then
    LUA_EXT_DIR="$VLC_DATA_DIR/lua/extensions"
    mkdir -p "$LUA_EXT_DIR"
    cp "$LUA_DIR/$LUA_NAME" "$LUA_EXT_DIR/"
    echo "Installed to $LUA_EXT_DIR"
else
    # Try to install to system path first if we have sudo/root, otherwise fallback to user path
    LUA_EXT_DIR="$VLC_DATA_DIR/lua/extensions"
    if [ -w "$VLC_DATA_DIR/lua" ]; then
        $SUDO mkdir -p "$LUA_EXT_DIR"
        $SUDO cp "$LUA_DIR/$LUA_NAME" "$LUA_EXT_DIR/"
        echo "Installed to $LUA_EXT_DIR"
    else
        # Fallback to user-specific path
        USER_LUA_EXT_DIR="$HOME/.local/share/vlc/lua/extensions"
        if [ "$SUDO_USER" ]; then
            USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
            USER_LUA_EXT_DIR="$USER_HOME/.local/share/vlc/lua/extensions"
        fi
        mkdir -p "$USER_LUA_EXT_DIR"
        cp "$LUA_DIR/$LUA_NAME" "$USER_LUA_EXT_DIR/"
        # If we are root, make sure the user owns the folder
        if [ "$SUDO_USER" ]; then
            chown -R "$SUDO_USER:$SUDO_USER" "$(dirname $(dirname $USER_LUA_EXT_DIR))" 2>/dev/null || true
        fi
        echo "Installed to $USER_LUA_EXT_DIR"
    fi
fi

echo ""
echo "============================================"
echo " INSTALLED SUCCESSFULLY"
echo "============================================"
echo ""
echo "Setup (one-time):"
echo "  1. Start VLC"
echo "  2. Enable the filter:"
echo "     Tools > Preferences > Show settings: All > Video > Filters"
echo "     Check 'CRT Scanline video filter' > Save"
echo "  3. Restart VLC"
echo ""
echo "Live control:"
echo "  View > CRT Scanline Controller"
echo ""
