CWD := $(shell dirname $(MAKEFILE_LIST))
NAME := $(shell basename $(shell readlink -f $(CWD)))

PKGTOOLS_DIR := $(CWD)/../../ngfw_pkgtools

## overridables
# repository
REPOSITORY ?= jessie
# distribution to draw packages from
DISTRIBUTION ?= current

# constants
ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)
TS := $(shell date +"%Y-%m-%dT%H%M%S")
HOST := $(shell hostname -s)
VERSION := $(shell cat $(PKGTOOLS_DIR)/resources/VERSION)
IMAGE_FILE := $(TMP_DIR)/image.bin
TMP_DIR := $(CWD)/tmp
TMP_IMAGE := $(TMP_DIR)/image.raw
# FIXME: find device dynamically, and then derive its ID
EBS_DEVICE := /dev/xvdf
EBS_ID := vol-06da60b13f650af2a
FULL_NAME := untangle-$(VERSION)_$(REPOSITORY)_$(ARCH)_current_$(TS)_$(HOST)_$(NAME)

.PHONY: all clean image push

all: image

clean:
	rm -fr $(TMP_DIR)

$(TMP_DIR):
	mkdir -p $@

# FIXME: extract AMI ID once done
image: $(TMP_DIR)
	fai-diskimage --hostname untangle-image --size 3G --class DEBIAN,JESSIE,BACKPORTS,GRUB_PC,CLOUD,EC2,UNTANGLE $(TMP_IMAGE)
	dd if=$(TMP_IMAGE) of=$(EBS_DEVICE) bs=300M
	bash volume-to-ami.sh $(EBS_ID)

# FIXME: share/make public ?
push:
