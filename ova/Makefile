OVA_DIR := $(shell dirname $(MAKEFILE_LIST))

PKGTOOLS_DIR := $(OVA_DIR)/../../ngfw_pkgtools

## overridables
# repository
REPOSITORY ?= jessie
# distribution to draw packages from
DISTRIBUTION ?= current
# architecture
ARCH ?= amd64
# FLAVOR
FLAVOR ?= untangle

## constants
TS := $(shell date --iso-8601=seconds)
HOST := $(shell hostname -s)
NETBOOT_HOST := netboot-server
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
MOUNT_SCRIPT := $(IMAGES_DIR)/mounts.py
VERSION := $(shell cat $(PKGTOOLS_DIR)/resources/VERSION)
VMDK_REFERENCE_NAME := jessie.vmdk
VMDK_REFERENCE_URL := $(NETBOOT_HOST)/$(VMDK_REFERENCE_NAME)
VMDK_NAME := $(FLAVOR).vmdk
QCOW2_NAME := $(FLAVOR).qcow2
OVF_FILE := $(FLAVOR).ovf
OVA_NAME := $(FLAVOR).ova
FULL_NAME := $(FLAVOR)-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_$(TS)_$(HOST).ova

## targets
.PHONY: all clean download-jessie-vmdk vmdk ova push

all: download-jessie-vmdk vmdk image

clean:
	rm -fr *-stamp $(VMDK_REFERENCE_NAME) $(QCOW2_NAME) $(VMDK_NAME) *.ova

$(VMDK_REFERENCE_NAME):
	curl -s -o $@ $(VMDK_REFERENCE_URL)

vmdk: $(VMDK_NAME)
$(VMDK_NAME): $(VMDK_REFERENCE_NAME)
	$(OVA_DIR)/vmdk.sh $(REPOSITORY) $(DISTRIBUTION) $(ARCH) $(FLAVOR) $< $@ $(shell xargs < ../profiles/$(FLAVOR).packages)

image: $(OVA_NAME)
$(OVA_NAME): $(OVF_FILE) $(VMDK_NAME)
	tar cvf $@ $^
	chmod 644 $@

push:
	scp $(shell ls --sort=time *ova | head -1) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME)
	ssh $(NETBOOT_HOST) "sudo python $(MOUNT_SCRIPT) all foo foo foo $(REPOSITORY)"
