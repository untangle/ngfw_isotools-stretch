BUFFALO_DIR := $(shell dirname $(MAKEFILE_LIST))

## overridables
# repository
REPOSITORY ?= wheezy
# distribution to draw packages from
DISTRIBUTION ?= nightly

# constants
TS := $(shell date +"%Y-%m-%dT%H%M%S")
HOST := $(shell hostname -s)
NETBOOT_HOST := netboot-server
# FIXME ?
ARCH := armel
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
VERSION := $(shell cat $(BUFFALO_DIR)/../resources/VERSION)
FMK_DIR := $(BUFFALO_DIR)/firmware-mod-kit
BIN_DIR := $(BUFFALO_DIR)/binary
KERNEL_FILE := $(BIN_DIR)/zImage-untangle
TRX_FILE := $(BIN_DIR)/kong-trx-header
HEADER_IMG := $(FMK_DIR)/fmk/image_parts/header.img
FIRMWARE_IMG := $(FMK_DIR)/fmk/new-firmware.bin
FULL_NAME := UNTANGLE-$(VERSION)_$(REPOSITORY)_$(ARCH)_chaos_$(TS)_$(HOST)
ROOTFS_ARCHIVE := /tmp/buffalo-rootfs.tar.bz2

.PHONY: all clean image rootfs push

all: image rootfs push

clean:
	rm -fr $(BUFFALO_DIR)/tmp $(ISO_DIR) $(BUFFALO_DIR)/debian-installer*
	rm -f $(HEADER_IMG) $(FIRMWARE_IMG) $(ROOTFS_ARCHIVE)
	rm -fr /tmp/debootstrap.*

image: $(FIRMWARE_IMG)
$(FIRMWARE_IMG): $(HEADER_IMG)
	cd $(FMK_DIR) ; ./build-firmware.sh -min
$(HEADER_IMG): $(TRX_FILE) $(KERNEL_FILE)
	cp $(TRX_FILE) $(HEADER_IMG)
	# need to apt-get install lzma for this one to do the right
	# thing (lzma from the xz package won't do)
	lzma -k -1 -c $(KERNEL_FILE) >> $(HEADER_IMG) 

rootfs: $(ROOTFS_ARCHIVE)
$(ROOTFS_ARCHIVE):
	$(BUFFALO_DIR)/make_chroot.sh $(REPOSITORY) chaos $(ROOTFS_ARCHIVE)

push:
	scp $(ROOTFS_ARCHIVE) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME).tar.bz2
	scp $(FIRMWARE_IMG) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME).img
