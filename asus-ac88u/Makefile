CWD := $(shell dirname $(MAKEFILE_LIST))

PKGTOOLS_DIR := $(CWD)/../../ngfw_pkgtools

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
MOUNT_SCRIPT := $(IMAGES_DIR)/mounts.py
VERSION := $(shell cat $(PKGTOOLS_DIR)/resources/VERSION)
BIN_DIR := $(CWD)/binary
TMP_DIR := $(CWD)/tmp
ASUS_REFERENCE_NAME := asus-ac88u-rootfs.tar.bz2
ASUS_REFERENCE_URL := $(NETBOOT_HOST)/$(ASUS_REFERENCE_NAME)
SQUASHFS_FILE := $(BIN_DIR)/dd-wrt.squashfs
KERNEL_FILE := $(BIN_DIR)/zImage-untangle
VMLINUZ_FILE := $(TMP_DIR)/vmlinuz.lzma
IMAGE_FILE := $(TMP_DIR)/image.bin
FIRMWARE_IMG := $(TMP_DIR)/$(NAME).bin
FULL_NAME := UNTANGLE-$(VERSION)_$(REPOSITORY)_$(ARCH)_chaos_$(TS)_$(HOST)
ROOTFS_IMAGE := /tmp/$(NAME).rootfs

.PHONY: all clean image rootfs push download-asus-rootsf

all: image rootfs

clean:
	rm -fr $(TMP_DIR) $(ROOTFS_IMAGE) $(ASUS_REFERENCE_NAME)

download-asus-rootsf: $(ASUS_REFERENCE_NAME)
$(ASUS_REFERENCE_NAME):
	curl -s -o $@ $(ASUS_REFERENCE_URL)

vmlinuz: $(VMLINUZ_FILE)
$(VMLINUZ_FILE): $(KERNEL_FILE) | $(TMP_DIR)
	$(BIN_DIR)/lzma_4k e $< $@

image: $(FIRMWARE_IMG)
$(FIRMWARE_IMG): $(VMLINUZ_FILE) $(SQUASHFS_FILE) | $(TMP_DIR)
	$(BIN_DIR)/trx -m 40000000 -o $(IMAGE_FILE) $(VMLINUZ_FILE) -a 131072 $(SQUASHFS_FILE)
	$(BIN_DIR)/trx_asus -i $(IMAGE_FILE) -r RT-AC88U,3.0.0.4,380,760,$(FIRMWARE_IMG)

$(TMP_DIR):
	mkdir $@

rootfs: $(ROOTFS_IMAGE)
$(ROOTFS_IMAGE): $(ASUS_REFERENCE_NAME)
	$(CWD)/make_chroot.sh $(REPOSITORY) $(DISTRIBUTION) $(ARCH) $(ASUS_REFERENCE_NAME) $(ROOTFS_IMAGE)

push:
	scp $(ROOTFS_IMAGE) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME).rootfs
	scp $(FIRMWARE_IMG) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME).firmware
	ssh $(NETBOOT_HOST) "sudo python $(MOUNT_SCRIPT) all foo foo foo $(REPOSITORY)"
