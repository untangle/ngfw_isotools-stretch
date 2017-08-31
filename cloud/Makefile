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
TMP_DIR := $(shell mktemp -d $(CWD)/tmp-aws-XXXX)
AMI_LOG := $(shell mktemp $(TMP_DIR)/ami-XXXX.log)
TMP_IMAGE := $(shell mktemp $(TMP_DIR)/ami-XXXX.raw)
NETBOOT_HOST := $(shell dig +short @10.112.0.1 netboot-server.untangle.int)
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
# FIXME: find device dynamically, and then derive its ID
EBS_DEVICE := /dev/xvdf
EBS_ID := vol-06da60b13f650af2a
FULL_NAME := untangle-$(VERSION)_$(REPOSITORY)_$(ARCH)_current_$(TS)_$(HOST)_$(NAME).ami.txt

.PHONY: all clean image push

all: image

clean:
	rm -fr $(TMP_DIR)

# FIXME: extract AMI ID once done
aws-image:
	fai-diskimage --hostname untangle-image --size 3G --class DEBIAN,JESSIE,BACKPORTS,GRUB_PC,CLOUD,EC2,UNTANGLE $(TMP_IMAGE)
	dd if=$(TMP_IMAGE) of=$(EBS_DEVICE) bs=300M
	bash volume-to-ami.sh $(EBS_ID) | tee $(AMI_LOG)

# FIXME: share/make public ?
aws-push:
	$(eval ami_log := $(shell ls --sort=time tmp-aws*/ami-*.log | head -1))
	awk '/"ImageId":/ { gsub(/"/,"",$$2); print $$2 }' $(ami_log) | ssh $(NETBOOT_HOST) "cat > $(IMAGES_DIR)/$(VERSION)/$(FULL_NAME)"
