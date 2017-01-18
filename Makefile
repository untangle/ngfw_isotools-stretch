PKGS := debiandoc-sgml libbogl-dev glibc-pic libslang2-pic libnewt-pic genext2fs mklibs syslinux-utils isolinux pxelinux grub-efi-amd64-bin xorriso tofrodos module-init-tools bf-utf-source win32-loader librsvg2-bin

ISOTOOLS_DIR := $(shell dirname $(MAKEFILE_LIST))

PKGTOOLS_DIR := $(ISOTOOLS_DIR)/../ngfw_pkgtools

## overridables
# repository
REPOSITORY ?= jessie
# distribution to draw packages from
DISTRIBUTION ?= testing
# upstream d-i
UPSTREAM_DI ?= ~/svn/d-i_lenny

NETBOOT_HOST := netboot-server

# constants
ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)
KERNELS_i386 := "linux-image-3.16.0-4-untangle-686-pae"
KERNELS_amd64 := "linux-image-3.16.0-4-untangle-amd64"
ISO_DIR := /tmp/untangle-images
VERSION = $(shell cat $(PKGTOOLS_DIR)/resources/VERSION)
ISO_IMAGE := $(ISO_DIR)/+FLAVOR+-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_$(shell date --iso-8601=seconds)_$(shell hostname -s).iso
USB_IMAGE := $(subst .iso,.img,$(ISO_IMAGE))
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
MOUNT_SCRIPT := $(IMAGES_DIR)/mounts.py
NETBOOT_DIR_TXT := $(ISOTOOLS_DIR)/d-i/build/dest/netboot/debian-installer/$(ARCH)
NETBOOT_DIR_GTK := $(ISOTOOLS_DIR)/d-i/build/dest/netboot/gtk/debian-installer/$(ARCH)
NETBOOT_INITRD_TXT := $(NETBOOT_DIR_TXT)/initrd.gz
NETBOOT_INITRD_GTK := $(NETBOOT_DIR_GTK)/initrd.gz
NETBOOT_KERNEL := $(NETBOOT_DIR_TXT)/linux
BOOT_IMG := $(ISOTOOLS_DIR)/d-i/build/dest/hd-media/boot.img.gz
PROFILES_DIR := $(ISOTOOLS_DIR)/profiles
COMMON_PRESEED :=  $(PROFILES_DIR)/common.preseed
AUTOPARTITION_PRESEED :=  $(PROFILES_DIR)/auto-partition.preseed
NETBOOT_PRESEED := $(PROFILES_DIR)/netboot.preseed
NETBOOT_PRESEED_FINAL := $(NETBOOT_PRESEED).$(ARCH)
NETBOOT_PRESEED_EXPERT := $(PROFILES_DIR)/netboot.expert.preseed.$(ARCH)
NETBOOT_PRESEED_EXTRA := $(NETBOOT_PRESEED).extra
DEFAULT_PRESEED_FINAL := $(PROFILES_DIR)/default.preseed
DEFAULT_PRESEED_EXPERT := $(PROFILES_DIR)/expert.preseed
DEFAULT_PRESEED_EXTRA := $(DEFAULT_PRESEED_FINAL).extra
CONF_FILE := $(PROFILES_DIR)/default.conf
CONF_FILE_TEMPLATE := $(CONF_FILE).template
DOWNLOAD_FILE := $(PROFILES_DIR)/default.downloads
DOWNLOAD_FILE_TEMPLATE := $(DOWNLOAD_FILE).template
DI_CORE_PATCH := $(ISOTOOLS_DIR)/d-i_core.patch

all:

installer-clean:
	cd $(ISOTOOLS_DIR)/d-i ; fakeroot debian/rules clean
	rm -fr $(ISOTOOLS_DIR)/debian-installer* $(ISOTOOLS_DIR)/d-i/build/sources.list.udeb.local

iso-clean:
	rm -fr $(ISOTOOLS_DIR)/tmp $(ISO_DIR) $(ISOTOOLS_DIR)/debian-installer*

patch-installer: patch-installer-stamp
patch-installer-stamp:
	patch -p2 < $(DI_CORE_PATCH)
	touch $@

unpatch-installer:
	if [ -f patch-installer-stamp ] ; then \
	  patch -p2 -R < $(DI_CORE_PATCH) ; \
	  rm -f patch-installer-stamp ; \
	fi

debian-installer: repoint-stable installer-stamp
installer-stamp:
	perl -pe 's|\+DISTRIBUTION\+|'testing'| ; s|\+REPOSITORY\+|'jessie'|' ./d-i.sources.template >| ./d-i/build/sources.list.udeb.local
	cd $(ISOTOOLS_DIR)/d-i ; sudo fakeroot debian/rules binary
	touch installer-stamp

repoint-stable: repoint-stable-stamp
repoint-stable-stamp:
	$(ISOTOOLS_DIR)/package-server-proxy.sh ./create-di-links.sh $(REPOSITORY) $(DISTRIBUTION)
	touch $@

iso-conf:
	perl -pe 's|\+DISTRIBUTION\+|'$(DISTRIBUTION)'| ; s|\+REPOSITORY\+|'$(REPOSITORY)'|' $(ISOTOOLS_DIR)/d-i.sources.template >| $(ISOTOOLS_DIR)/d-i/build/sources.list.udeb.local
	perl -pe 's|\+ISOTOOLS_DIR\+|'`pwd`/$(ISOTOOLS_DIR)'|g' $(CONF_FILE_TEMPLATE) >| $(CONF_FILE)
	perl -pe 's|\+KERNELS\+|'$(KERNELS_$(ARCH))'|' $(DOWNLOAD_FILE_TEMPLATE) >| $(DOWNLOAD_FILE)

	cat $(COMMON_PRESEED) $(AUTOPARTITION_PRESEED) $(NETBOOT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+ARCH\+|'$(ARCH)'|g ; s|\+REPOSITORY\+|'$(REPOSITORY)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(NETBOOT_PRESEED_FINAL)
	cat $(COMMON_PRESEED) $(AUTOPARTITION_PRESEED) $(DEFAULT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+REPOSITORY\+|'$(REPOSITORY)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(DEFAULT_PRESEED_FINAL)
	cat $(COMMON_PRESEED) $(NETBOOT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+ARCH\+|'$(ARCH)'|g ; s|\+REPOSITORY\+|'$(REPOSITORY)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(NETBOOT_PRESEED_EXPERT)
	cat $(COMMON_PRESEED) $(DEFAULT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(DEFAULT_PRESEED_EXPERT)

iso/%-image: debian-installer iso-conf
	mkdir -p $(ISO_DIR)
	. $(ISOTOOLS_DIR)/debian-cd/CONF.sh ; \
	build-simple-cdd --keyring /usr/share/keyrings/untangle-keyring.gpg --force-root --profiles $(patsubst iso/%-image,%,$*),expert --debian-mirror http://package-server/public/$(REPOSITORY) --security-mirror http://package-server/public/$(REPOSITORY) --dist $(REPOSITORY) -g --require-optional-packages --mirror-tools reprepro
	mv $(ISO_DIR)/debian-$(shell cut -d. -f 1 /etc/debian_version).*-$(ARCH)-CD-1.iso $(subst +FLAVOR+,$(patsubst iso/%-image,%,$*),$(ISO_IMAGE))

usb/%-image:
	$(eval iso_image := $(shell ls --sort=time $(ISO_DIR)/*$(VERSION)*$(REPOSITORY)*$(ARCH)*$(DISTRIBUTION)*.iso | head -1))
	$(ISOTOOLS_DIR)/make_usb.sh $(BOOT_IMG) $(iso_image) $(subst +FLAVOR+,$(patsubst usb/%-image,%,$*),$(USB_IMAGE))

ova-image:
	make -C $(ISOTOOLS_DIR)/ova image
ova-push:
	make -C $(ISOTOOLS_DIR)/ova push
ova-clean:
	make -C $(ISOTOOLS_DIR)/ova clean

iso/%-push: # pushes the most recent images
	$(eval iso_image := $(shell ls --sort=time $(ISO_DIR)/*$(VERSION)*$(REPOSITORY)*$(ARCH)*$(DISTRIBUTION)*.iso | head -1))
	$(eval usb_image := $(shell ls --sort=time $(ISO_DIR)/*$(VERSION)*$(REPOSITORY)*$(ARCH)*$(DISTRIBUTION)*.img | head -1))
	$(eval timestamp := $(shell echo $iso_image | perl -pe 's/.*(\d{4}(-\d{2}){2}T(\d{2}:?){3}).*/$1/'))
	echo ssh $(NETBOOT_HOST) "sudo python $(MOUNT_SCRIPT) new $(VERSION) $(timestamp) $(ARCH) $(REPOSITORY)"
	scp $(iso_image) $(usb_image) $(NETBOOT_PRESEED_FINAL) $(NETBOOT_PRESEED_EXPERT) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)
	scp $(NETBOOT_INITRD_TXT) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/initrd-$(ARCH)-txt.gz
	scp $(NETBOOT_INITRD_GTK) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/initrd-$(ARCH)-gtk.gz
	scp $(NETBOOT_KERNEL) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/linux-$(ARCH)

	ssh $(NETBOOT_HOST) "sudo python $(MOUNT_SCRIPT) all foo foo foo $(REPOSITORY)"

# the next 4 rules are generic ones meant for firmware images; they
# take something like "buffalo/wzr1900dhp-image" and make it into
# "make -C buffalo-wzr1900dhp image"

%-image:
	make -C $(ISOTOOLS_DIR)/firmware/$(subst /,-,$*) image
%-rootfs:
	make -C $(ISOTOOLS_DIR)/firmware/$(subst /,-,$*) rootfs
%-push:
	make -C $(ISOTOOLS_DIR)/firmware/$(subst /,-,$*) push
%-clean:
	make -C $(ISOTOOLS_DIR)/firmware/$(subst /,-,$*) clean

.PHONY: all
