CWD := $(shell dirname $(MAKEFILE_LIST))
NAME := $(shell basename $CWD)

include $(CWD)/image.conf

PKGTOOLS_DIR := $(CWD)/../../ngfw_pkgtools

## overridables
# repository
REPOSITORY ?= jessie
# distribution to draw packages from
DISTRIBUTION ?= nightly

# constants
TS := $(shell date +"%Y-%m-%dT%H%M%S")
HOST := $(shell hostname -s)
NETBOOT_HOST := netboot-server
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
MOUNT_SCRIPT := $(IMAGES_DIR)/mounts.py
VERSION := $(shell cat $(PKGTOOLS_DIR)/resources/VERSION)
BIN_DIR := $(CWD)/binary
TMP_DIR := $(CWD)/tmp
VENDOR_REFERENCE_NAME := $(NAME)-rootfs.tar.bz2
VENDOR_REFERENCE_URL := $(NETBOOT_HOST)/$(VENDOR_REFERENCE_NAME)
SQUASHFS_FILE := $(BIN_DIR)/dd-wrt.squashfs
KERNEL_FILE := $(BIN_DIR)/uImage-untangle
FIRMWARE_IMG := $(TMP_DIR)/$(NAME).bin
FULL_NAME := UNTANGLE-$(VERSION)_$(REPOSITORY)_$(ARCH)_chaos_$(TS)_$(HOST)_$(NAME)
ROOTFS_IMAGE := /tmp/$(NAME).rootfs

.PHONY: all clean image rootfs push

all: image rootfs

clean:
	rm -fr $(TMP_DIR) $(ROOTFS_IMAGE) $(VENDOR_REFERENCE_NAME)

download-vendor-rootfs: $(VENDOR_REFERENCE_NAME)
$(VENDOR_REFERENCE_NAME):
	curl -s -o $@ $(VENDOR_REFERENCE_URL)

image: $(FIRMWARE_IMG)
$(FIRMWARE_IMG): $(VMLINUZ_FILE) $(SQUASHFS_FILE) | $(TMP_DIR)
	(dd if=$(KERNEL_FILE) bs=3072k conv=sync; dd if=$(SQUASHFS_FILE) bs=2048 conv=sync; ) > $(FIRMWARE_IMG)

$(TMP_DIR):
	mkdir $@

rootfs: $(ROOTFS_IMAGE)
$(ROOTFS_IMAGE): $(VENDOR_REFERENCE_NAME)
	$(CWD)/make_chroot.sh $(REPOSITORY) $(DISTRIBUTION) $(ARCH) $(VENDOR_REFERENCE_NAME) $(ROOTFS_IMAGE)

push:
	scp $(ROOTFS_IMAGE) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME).rootfs
	scp $(FIRMWARE_IMG) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME).firmware
	ssh $(NETBOOT_HOST) "sudo python $(MOUNT_SCRIPT) all foo foo foo $(REPOSITORY)"
