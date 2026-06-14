CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=gnu11 -fPIC
LDFLAGS = -shared
PKGS = vlc-plugin

PLUGIN_NAME = libcrt_scanline_plugin
SRC = src/crt_scanline.c
OUT_DIR = build
TARGET = $(OUT_DIR)/$(PLUGIN_NAME).so

# Check if pkg-config is available and the package exists
PKG_CHECK := $(shell pkg-config --exists $(PKGS) && echo yes || echo no)

ifeq ($(PKG_CHECK),yes)
    CFLAGS += $(shell pkg-config --cflags $(PKGS))
    LIBS += $(shell pkg-config --libs $(PKGS))
else
    # Fallback to common paths if pkg-config fails
    CFLAGS += -I/usr/include/vlc/plugins -Isrc
    # On many distros, we don't actually need to link libvlccore for plugins
    # but let's keep it flexible.
    LIBS += -lvlccore
endif

CFLAGS += -D__PLUGIN__ -DMODULE_STRING=\"crtscanline\"

.PHONY: all clean install

all: $(TARGET)

$(TARGET): $(SRC)
	mkdir -p $(OUT_DIR)
	$(CC) $(CFLAGS) $(SRC) -o $@ $(LDFLAGS) $(LIBS)

clean:
	rm -rf $(OUT_DIR)

install: all
	@if [ "$$USER_INSTALL" = "1" ]; then \
		VLC_PLUGIN_DIR="$$HOME/.local/share/vlc/plugins/video_filter"; \
		VLC_DATA_DIR="$$HOME/.local/share/vlc"; \
		SUDO=""; \
	else \
		VLC_PLUGIN_DIR=$$(pkg-config --variable=pluginsdir vlc-plugin 2>/dev/null || echo /usr/lib/vlc/plugins)/video_filter; \
		VLC_DATA_DIR=$$(pkg-config --variable=datadir vlc-plugin 2>/dev/null || echo /usr/share/vlc); \
		SUDO="sudo"; \
	fi; \
	echo "Installing plugin to $$VLC_PLUGIN_DIR..."; \
	$$SUDO mkdir -p "$$VLC_PLUGIN_DIR"; \
	$$SUDO cp $(TARGET) "$$VLC_PLUGIN_DIR/"; \
	echo "Installing Lua controller..."; \
	if [ "$$USER_INSTALL" = "1" ]; then \
		LUA_PATH="$$VLC_DATA_DIR/lua/extensions"; \
	else \
		LUA_PATH="$$VLC_DATA_DIR/lua/extensions"; \
	fi; \
	$$SUDO mkdir -p "$$LUA_PATH"; \
	$$SUDO cp lua/crt_scanline_controller.lua "$$LUA_PATH/"; \
	echo "Done. Please restart VLC and enable the filter."
