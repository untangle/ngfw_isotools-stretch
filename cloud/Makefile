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
ARCH_CAPS := $(shell echo $(ARCH) | tr '[a-z]' '[A-Z]')
TMP_DIR := $(CWD)/tmp-$(REPOSITORY)-$(DISTRIBUTION)-$(ARCH)-$(LICENSE)
CLOUD_LOG := $(TMP_DIR)/cloud.log
TMP_IMAGE := $(TMP_DIR)/cloud.raw
AZURE_IMAGE := $(TMP_DIR)/cloud.vhd
NETBOOT_HOST := netboot-server.untangle.int
IMAGE_SIZE := 3G
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
UNTANGLE_FAI_CONF := $(CWD)/class/UNTANGLE.var
UNTANGLE_FAI_CONF_TPL := $(UNTANGLE_FAI_CONF).tpl
# FIXME: find device dynamically, and then derive its ID
EBS_DEVICE := /dev/xvdf
EBS_ID := vol-06da60b13f650af2a
# FIXME: not necessarily ec2, so handle name in %-push instead
EC2_FULL_NAME := untangle-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_$(TS)_$(HOST)_$(NAME)_ec2_$(LICENSE).txt
AZURE_FULL_NAME := untangle-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_$(TS)_$(HOST)_$(NAME)_azure_$(LICENSE).txt
AZURE_SHORT_NAME := untangle-$(VERSION)_$(REPOSITORY)_$(LICENSE)_$(TS)
AZURE_BLOB_NAME := $(AZURE_SHORT_NAME).vhd
AZURE_ACCOUNT := untangledeploy
AZURE_BASE_URL := https://$(AZURE_ACCOUNT).blob.core.windows.net
AZURE_CONTAINER := untangle-vhd
AZURE_RESOURCE_GROUP := UntangleAzureDeploy

all: aws-image

clean:
	rm -fr $(TMP_DIR) $(UNTANGLE_FAI_CONF)

$(TMP_DIR):
	mkdir -p $(TMP_DIR)

conf:
	perl -pe 's/\+UNTANGLE_REPOSITORY\+/'$(REPOSITORY)'/ ; s/\+UNTANGLE_RELEASE\+/'$(DISTRIBUTION)'/' $(UNTANGLE_FAI_CONF_TPL) > $(UNTANGLE_FAI_CONF)

ec2-image: $(TMP_DIR) conf
	if [ $(ARCH) = amd64 ] ; then \
	  export CLOUD_BUILD_BASENAME=$(TMP_IMAGE) ; \
	  fai-diskimage -v --cspace $(CWD) --hostname untangle-image --size $(IMAGE_SIZE) --class DEBIAN,$(ARCH_CAPS),STRETCH,BACKPORTS,GRUB_PC,CLOUD,EC2,UNTANGLE,UNTANGLE_$(ARCH_CAPS),UNTANGLE_EC2_$(shell echo $(LICENSE) | tr '[a-z]' '[A-Z]') $(TMP_IMAGE) ; \
	else \
	  export CLOUD_BUILD_BASENAME=$(TMP_IMAGE) ; \
	  fai-diskimage -v --cspace $(CWD) --hostname untangle-image --size $(IMAGE_SIZE) --class DEBIAN,$(ARCH_CAPS),STRETCH,BACKPORTS,GRUB_EFI_$(ARCH_CAPS),CLOUD,EC2,UNTANGLE,UNTANGLE_$(ARCH_CAPS),UNTANGLE_EC2_$(shell echo $(LICENSE) | tr '[a-z]' '[A-Z]') $(TMP_IMAGE) ; \
	fi
	dd if=$(TMP_IMAGE) of=$(EBS_DEVICE) bs=300M
	bash volume-to-ami.sh -a $(ARCH) -r $(REPOSITORY)-$(VERSION) $(EBS_ID) | tee $(CLOUD_LOG)

ec2-push:
	awk '/"ImageId":/ { gsub(/"/,"",$$2); print $$2 }' $(CLOUD_LOG) | ssh $(NETBOOT_HOST) "cat > $(IMAGES_DIR)/$(VERSION)/$(EC2_FULL_NAME)"

azure-image: $(TMP_DIR) conf
	export CLOUD_BUILD_BASENAME=$(TMP_IMAGE) ; fai-diskimage -v --cspace $(CWD) --hostname untangle-image --size $(IMAGE_SIZE) --class DEBIAN,STRETCH,BACKPORTS,GRUB_PC,AMD64,CLOUD,AZURE,UNTANGLE,UNTANGLE_AMD64,UNTANGLE_AZURE_$(shell echo $(LICENSE) | tr '[a-z]' '[A-Z]'),LAST $(TMP_IMAGE)
	qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $(TMP_IMAGE) $(AZURE_IMAGE)

cloud-image: $(TMP_DIR)
	if [ $(ARCH) = amd64 ] ; then \
	  fai-diskimage --cspace $(CWD) --hostname untangle-image --size $(IMAGE_SIZE) --class DEBIAN,STRETCH,GRUB_PC,CLOUD $(TMP_IMAGE) ; \
	fi

azure-push:
	if [ $(ARCH) = amd64 ] ; then \
	  echo $(AZURE_SHORT_NAME) | ssh $(NETBOOT_HOST) "cat > $(IMAGES_DIR)/$(VERSION)/$(AZURE_FULL_NAME)" ; \
	  az login --service-principal --username $(AZURE_PRINCIPAL_ID) --password $(AZURE_PRINCIPAL_PASSWORD) --tenant $(AZURE_TENANT_ID) ; \
	  az storage blob upload --account-name $(AZURE_ACCOUNT) --account-key $(AZURE_ACCOUNT_KEY) --container-name $(AZURE_CONTAINER) --type page --file $(AZURE_IMAGE) --name $(AZURE_BLOB_NAME) ; \
	# az disk create --resource-group $(AZURE_RESOURCE_GROUP) --size-gb 20 --source $(AZURE_BASE_URL)/$(AZURE_CONTAINER)/$(AZURE_BLOB_NAME) --name $(AZURE_SHORT_NAME)-20GB
	  az image create --resource-group $(AZURE_RESOURCE_GROUP) --os-type Linux --source $(AZURE_BASE_URL)/$(AZURE_CONTAINER)/$(AZURE_BLOB_NAME) --name $(AZURE_SHORT_NAME) ; \
	fi

.PHONY: all clean conf ec2-image ec2-push azure-image azure-push
