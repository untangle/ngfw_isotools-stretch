OVA_DIR := $(shell dirname $(MAKEFILE_LIST))

## overridables
# repository
REPOSITORY ?= jessie
# distribution to draw packages from
DISTRIBUTION ?= nightly
# architecture
ARCH ?= i386

## constants
TS := $(shell date --iso-8601=seconds)
HOST := $(shell hostname -s)
NETBOOT_HOST := netboot-server
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
VERSION := $(shell cat $(OVA_DIR)/../resources/VERSION)
VMDK_REFERENCE_NAME := jessie.vmdk
VMDK_REFERENCE_URL := $(NETBOOT_HOST)/$(VMDK_REFERENCE_NAME)
VMDK_NAME := untangle.vmdk
QCOW2_NAME := untangle.qcow2
OVF_FILE := Untangle.ovf
OVA_NAME := Untangle.ova
FULL_NAME := UNTANGLE-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_$(TS)_$(HOST).ova

## targets
.PHONY: all clean download-jessie-vmdk vmdk ova push

all: download-jessie-vmdk vmdk ova push

clean:
	rm -fr $(VMDK_REFERENCE_NAME) $(QCOW2_NAME) $(VMDK_NAME) *.ova

download-jessie-vmdk: $(VMDK_REFERENCE_NAME)
$(VMDK_REFERENCE_NAME):
	curl -s -o $@ $(VMDK_REFERENCE_URL)

vmdk: $(VMDK_NAME)
$(VMDK_NAME): $(VMDK_REFERENCE_NAME)
	$(OVA_DIR)/vmdk.sh $(REPOSITORY) $(DISTRIBUTION) $< $@

ova: $(OVA_NAME)
$(OVA_NAME): $(OVF_FILE) $(VMDK_NAME)
	tar cvf $@ $^
	chmod 644 $@

push:
	scp `ls --sort=time *ova | head -1` $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/$(FULL_NAME)
