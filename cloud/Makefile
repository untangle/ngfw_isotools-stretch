CWD := $(shell dirname $(shell readlink -f MAKEFILE_LIST))
NAME := $(shell basename $(shell readlink -f $(CWD)))

PKGTOOLS_DIR := $(CWD)/../../ngfw_pkgtools

## overridables
# repository
REPOSITORY ?= stretch
# distribution to draw packages from
DISTRIBUTION ?= current
# license
LICENSE ?= BYOL

# constants
ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)
TS := $(shell date +"%Y-%m-%dT%H%M%S")
HOST := $(shell hostname -s)
VERSION ?= $(shell cat $(PKGTOOLS_DIR)/resources/VERSION)
TMP_DIR := $(CWD)/tmp-$(REPOSITORY)-$(DISTRIBUTION)-$(LICENSE)
CLOUD_LOG := $(TMP_DIR)/cloud.log
TMP_IMAGE := $(TMP_DIR)/cloud.raw
AZURE_IMAGE := $(TMP_DIR)/cloud.vhd
NETBOOT_HOST := netboot-server.untangle.int
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
UNTANGLE_FAI_CONF := $(CWD)/class/UNTANGLE.var
UNTANGLE_FAI_CONF_TPL := $(UNTANGLE_FAI_CONF).tpl
# FIXME: find device dynamically, and then derive its ID
EBS_DEVICE := /dev/xvdf
EBS_ID := vol-06da60b13f650af2a
# FIXME: not necessarily ec2, so handle name in %-push instead
EC2_FULL_NAME := untangle-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_$(TS)_$(HOST)_$(NAME)_ec2_$(LICENSE).txt
AZURE_FULL_NAME := untangle-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_$(TS)_$(HOST)_$(NAME)_azure_$(LICENSE).txt
AZURE_SHORT_NAME := untangle-$(VERSION)_$(REPOSITORY)_$(TS)
AZURE_BLOB_NAME := $(AZURE_SHORT_NAME).vhd
AZURE_ACCOUNT := untangledeploy
AZURE_BASE_URL := https://$(AZURE_ACCOUNT).blob.core.windows.net
AZURE_CONTAINER := untangle-vhd
AZURE_RESOURCE_GROUP := untangledeploy

all: aws-image

clean:
	rm -fr $(TMP_DIR) $(UNTANGLE_FAI_CONF)

$(TMP_DIR):
	mkdir -p $(TMP_DIR)

conf:
	perl -pe 's/\+UNTANGLE_REPOSITORY\+/'$(REPOSITORY)'/ ; s/\+UNTANGLE_RELEASE\+/'$(DISTRIBUTION)'/' $(UNTANGLE_FAI_CONF_TPL) > $(UNTANGLE_FAI_CONF)

ec2-image: $(TMP_DIR) conf
	export CLOUD_BUILD_BASENAME=$(TMP_IMAGE) ; fai-diskimage -v --cspace $(CWD) --hostname untangle-image --size 600M --class DEBIAN,STRETCH,BACKPORTS,GRUB_PC,CLOUD,EC2,UNTANGLE,UNTANGLE_EC2_$(LICENSE),LAST $(TMP_IMAGE)

ec2-push:
	dd if=$(TMP_IMAGE) of=$(EBS_DEVICE) bs=300M
	bash volume-to-ami.sh -r $(REPOSITORY)-$(VERSION) $(EBS_ID) | tee $(CLOUD_LOG)
	awk '/"ImageId":/ { gsub(/"/,"",$$2); print $$2 }' $(CLOUD_LOG) | ssh $(NETBOOT_HOST) "cat > $(IMAGES_DIR)/$(VERSION)/$(EC2_FULL_NAME)"

azure-image: $(TMP_DIR) conf
	export CLOUD_BUILD_BASENAME=$(TMP_IMAGE) ; fai-diskimage -v --cspace $(CWD) --hostname untangle-image --size 3G --class DEBIAN,STRETCH,BACKPORTS,GRUB_PC,CLOUD,AZURE,UNTANGLE,UNTANGLE_AZURE_$(LICENSE),LAST $(TMP_IMAGE)
	qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $(TMP_IMAGE) $(AZURE_IMAGE)

cloud-image: $(TMP_DIR)
	fai-diskimage --cspace $(CWD) --hostname untangle-image --size 3G --class DEBIAN,STRETCH,GRUB_PC,CLOUD $(TMP_IMAGE)

azure-push:
	echo $(AZURE_SHORT_NAME) | ssh $(NETBOOT_HOST) "cat > $(IMAGES_DIR)/$(VERSION)/$(AZURE_FULL_NAME)"
	az storage blob upload --account-name $(AZURE_ACCOUNT) --account-key $(AZURE_ACCOUNT_KEY) --container-name $(AZURE_CONTAINER) --type page --file $(AZURE_IMAGE) --name $(AZURE_BLOB_NAME)
	az disk create --resource-group $(AZURE_RESOURCE_GROUP) --name $(AZURE_SHORT_NAME)-30GB --source $(AZURE_BASE_URL)/$(AZURE_CONTAINER)/$(AZURE_BLOB_NAME) --size-gb 30

.PHONY: all clean conf ec2-image ec2-push azure-image azure-push
