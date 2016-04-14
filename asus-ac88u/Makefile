CWD := $(shell dirname $(MAKEFILE_LIST))

NAME := asus-ac88u

## overridables
# repository
REPOSITORY ?= jessie
# distribution to draw packages from
DISTRIBUTION ?= nightly

# constants
TS := $(shell date +"%Y-%m-%dT%H%M%S")
HOST := $(shell hostname -s)
NETBOOT_HOST := netboot-server
# FIXME ?
ARCH := armel
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
VERSION := $(shell cat $(CWD)/../resources/VERSION)
BIN_DIR := $(CWD)/binary
TMP_DIR := $(CWD)/tmp
SQUASHFS_FILE := $(BIN_DIR)/dd-wrt.squashfs
KERNEL_FILE := $(BIN_DIR)/zImage-untangle
VMLINUZ_FILE := $(TMP_DIR)/vmlinuz.lzma
IMAGE_FILE := $(TMP_DIR)/image.bin
FIRMWARE_IMG := $(TMP_DIR)/$(NAME).bin
FULL_NAME := UNTANGLE-$(VERSION)_$(REPOSITORY)_$(ARCH)_chaos_$(TS)_$(HOST)
ROOTFS_ARCHIVE := /tmp/$(NAME)-rootfs.tar.bz2

.PHONY: all clean image rootfs push

all: image rootfs push

clean:
	rm -fr $(TMP_DIR) $(ROOTFS_ARCHIVE)

vmlinuz: $(VMLINUZ_FILE)
$(VMLINUZ_FILE): $(KERNEL_FILE) | $(TMP_DIR)
	$(BIN_DIR)/lzma_4k e $< $@

image: $(FIRMWARE_IMG)
$(FIRMWARE_IMG): $(VMLINUZ_FILE) $(SQUASHFS_FILE) | $(TMP_DIR)
	$(BIN_DIR)/trx -m 40000000 -o $(IMAGE_FILE) $(VMLINUZ_FILE) -a 131072 $(SQUASHFS_FILE)
	$(BIN_DIR)/trx_asus -i $(IMAGE_FILE) -r RT-AC88U,3.0.0.4.380.760,$(FIRMWARE_IMG)

$(TMP_DIR):
	mkdir $@

rootfs: $(ROOTFS_ARCHIVE)
$(ROOTFS_ARCHIVE):
	$(CWD)/make_chroot.sh $(REPOSITORY) $(DISTRIBUTION) $(ARCH) $(ROOTFS_ARCHIVE)

push:
	scp $(ROOTFS_ARCHIVE) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME).tar.bz2
	scp $(FIRMWARE_IMG) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME).img
