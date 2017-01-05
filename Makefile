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
ISO_DIR := /tmp/iso-images
VERSION = $(shell cat $(PKGTOOLS_DIR)/resources/VERSION)
ISO_IMAGE := $(ISO_DIR)/UNTANGLE-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_`date --iso-8601=seconds`_`hostname -s`.iso
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
MOUNT_SCRIPT := $(IMAGES_DIR)/mounts.py
NETBOOT_DIR_TXT := $(ISOTOOLS_DIR)/d-i/build/dest/netboot/debian-installer/$(ARCH)
NETBOOT_DIR_GTK := $(ISOTOOLS_DIR)/d-i/build/dest/netboot/gtk/debian-installer/$(ARCH)
NETBOOT_INITRD_TXT := $(NETBOOT_DIR_TXT)/initrd.gz
NETBOOT_INITRD_GTK := $(NETBOOT_DIR_GTK)/initrd.gz
NETBOOT_KERNEL := $(NETBOOT_DIR_TXT)/linux
BOOT_IMG := $(ISOTOOLS_DIR)/d-i/build/dest/hd-media/boot.img.gz
BOOT_IMG_UNTANGLE := $(ISOTOOLS_DIR)/boot.img
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

.PHONY: all patch unpatch installer image push 

all: installer iso-image

iso-clean: unpatch
	cd $(ISOTOOLS_DIR)/d-i ; fakeroot debian/rules clean
	rm -fr $(ISOTOOLS_DIR)/tmp $(ISO_DIR) $(ISOTOOLS_DIR)/debian-installer*
	rm -f $(ISOTOOLS_DIR)/d-i/build/sources.list.udeb.local
	rm -f $(ISOTOOLS_DIR)/debian-cd/CONF.sh.orig
	rm -f installer-stamp

patch: patch-stamp
patch-stamp:
	patch -p2 < $(DI_CORE_PATCH)
	perl -pe 's|\+DISTRIBUTION\+|'$(DISTRIBUTION)'| ; s|\+REPOSITORY\+|'$(REPOSITORY)'|' $(ISOTOOLS_DIR)/d-i.sources.template >| $(ISOTOOLS_DIR)/d-i/build/sources.list.udeb.local
	perl -pe 's|\+ISOTOOLS_DIR\+|'`pwd`/$(ISOTOOLS_DIR)'|g' $(CONF_FILE_TEMPLATE) >| $(CONF_FILE)

	cat $(COMMON_PRESEED) $(AUTOPARTITION_PRESEED) $(NETBOOT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+ARCH\+|'$(ARCH)'|g ; s|\+REPOSITORY\+|'$(REPOSITORY)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(NETBOOT_PRESEED_FINAL)
	cat $(COMMON_PRESEED) $(AUTOPARTITION_PRESEED) $(DEFAULT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+REPOSITORY\+|'$(REPOSITORY)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(DEFAULT_PRESEED_FINAL)
	cat $(COMMON_PRESEED) $(NETBOOT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+ARCH\+|'$(ARCH)'|g ; s|\+REPOSITORY\+|'$(REPOSITORY)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(NETBOOT_PRESEED_EXPERT)
	cat $(COMMON_PRESEED) $(DEFAULT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(DEFAULT_PRESEED_EXPERT)

	touch patch-stamp

unpatch: 
	if [ -f patch-stamp ] ; then \
	  patch -p2 -R < $(DI_CORE_PATCH) ; \
	  rm -f patch-stamp ; \
	fi
	rm -f $(NETBOOT_PRESEED_FINAL) $(DEFAULT_PRESEED_FINAL) $(CONF_FILE) $(DOWNLOAD_FILE)
	rm -fr $(NETBOOT_PRESEED_FINAL) $(DEFAULT_PRESEED_FINAL) $(NETBOOT_PRESEED_EXPERT) $(DEFAULT_PRESEED_EXPERT)

iso-installer: patch repoint-stable installer-stamp
installer-stamp:
	cd $(ISOTOOLS_DIR)/d-i ; sudo fakeroot debian/rules binary
	touch installer-stamp

repoint-stable: repoint-stable-stamp
repoint-stable-stamp:
	$(ISOTOOLS_DIR)/package-server-proxy.sh ./create-di-links.sh $(REPOSITORY) $(DISTRIBUTION)
	touch $@

iso-image:
	mkdir -p $(ISO_DIR)
	. $(ISOTOOLS_DIR)/debian-cd/CONF.sh ; \
	build-simple-cdd --keyring /usr/share/keyrings/untangle-keyring.gpg --force-root --profiles default,expert --debian-mirror http://package-server/public/$(REPOSITORY) --security-mirror http://package-server/public/$(REPOSITORY) --dist $(REPOSITORY) -g --require-optional-packages --mirror-tools reprepro
	mv $(ISO_DIR)/debian-$(cut -d. -f 1 /etc/debian_version).*-$(ARCH)-CD-1.iso $(ISO_IMAGE)

usb-image:
	$(ISOTOOLS_DIR)/make_usb.sh $(BOOT_IMG)

ova-image:
	make -C $(ISOTOOLS_DIR)/ova image
ova-push:
	make -C $(ISOTOOLS_DIR)/ova push
ova-clean:
	make -C $(ISOTOOLS_DIR)/ova clean

iso-push:
	ssh $(NETBOOT_HOST) "sudo python $(MOUNT_SCRIPT) new $(VERSION) $(shell ls --sort=time $(ISO_DIR)/*$(VERSION)*$(REPOSITORY)*$(ARCH)*$(DISTRIBUTION)*.iso | head -1 | perl -npe 'if (m/(i386|amd64).*iso/) { s/.*(\d{4}(-\d{2}){2}T(\d{2}:?){3}).*/$$1/ } else { s/.*\n// }' | tail -1) $(ARCH) $(REPOSITORY)"
	scp `ls --sort=time $(ISO_DIR)/*$(VERSION)*$(ARCH)*.iso | head -1` $(NETBOOT_PRESEED_FINAL) $(NETBOOT_PRESEED_EXPERT) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)
	scp $(BOOT_IMG_UNTANGLE) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/UNTANGLE-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_`date --iso-8601=seconds`_`hostname -s`.img
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
