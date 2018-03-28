PKGS := bf-utf-source debiandoc-sgml genext2fs glibc-pic grub-common grub-efi-amd64-bin isolinux libbogl-dev libnewt-pic librsvg2-bin libslang2-pic mklibs module-init-tools pxelinux syslinux-utils tofrodos win32-loader xorriso

ISOTOOLS_DIR := $(shell readlink -f $(shell dirname $(MAKEFILE_LIST)))

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
DEBVERSION := 9.0
KERNELS_i386 := "linux-image-4.9.0-6-untangle-686-pae"
KERNELS_amd64 := "linux-image-4.9.0-6-untangle-amd64"
VERSION = $(shell cat $(PKGTOOLS_DIR)/resources/VERSION)
ISO_IMAGE := +FLAVOR+-$(VERSION)_$(REPOSITORY)_$(ARCH)_$(DISTRIBUTION)_$(shell date --iso-8601=seconds)_$(shell hostname -s).iso
USB_IMAGE := $(subst .iso,.img,$(ISO_IMAGE))
IMAGES_DIR := /data/untangle-images-$(REPOSITORY)
MOUNT_SCRIPT := /data/image-manager/mounts.py
NETBOOT_DIR_TXT := $(ISOTOOLS_DIR)/d-i/build/dest/netboot/debian-installer/$(ARCH)
NETBOOT_DIR_GTK := $(ISOTOOLS_DIR)/d-i/build/dest/netboot/gtk/debian-installer/$(ARCH)
NETBOOT_INITRD_TXT := $(NETBOOT_DIR_TXT)/initrd.gz
NETBOOT_INITRD_GTK := $(NETBOOT_DIR_GTK)/initrd.gz
NETBOOT_KERNEL := $(NETBOOT_DIR_TXT)/linux
BOOT_IMG := $(ISOTOOLS_DIR)/d-i/build/dest/hd-media/boot.img.gz
PROFILES_DIR := $(ISOTOOLS_DIR)/profiles
COMMON_PRESEED :=  $(PROFILES_DIR)/common.preseed
AUTOPARTITION_PRESEED :=  $(PROFILES_DIR)/auto-partition.preseed
UNTANGLE_PRESEED := $(PROFILES_DIR)/untangle.preseed
NETBOOT_PRESEED := $(PROFILES_DIR)/netboot.preseed
NETBOOT_PRESEED_FINAL := $(NETBOOT_PRESEED).$(ARCH)
NETBOOT_PRESEED_EXPERT := $(PROFILES_DIR)/netboot.expert.preseed.$(ARCH)
NETBOOT_PRESEED_EXTRA := $(NETBOOT_PRESEED).extra
DEFAULT_PRESEED_FINAL := $(PROFILES_DIR)/default.preseed
DEFAULT_PRESEED_EXPERT := $(PROFILES_DIR)/expert.preseed
DEFAULT_PRESEED_EXTRA := $(DEFAULT_PRESEED_FINAL).extra
CONF_FILE := $(PROFILES_DIR)/default.conf
CONF_FILE_TEMPLATE := $(CONF_FILE).template
DEBIAN_INSTALLER_PATCH := $(ISOTOOLS_DIR)/d-i.patch
DEBIAN_CD_PATCH := $(ISOTOOLS_DIR)/debian-cd.patch
CUSTOMSIZE := $(shell echo $$(( 780 * 1000000 / 2048 )) ) # 780MB in 2kB blocks

all:

installer-clean:
	cd $(ISOTOOLS_DIR)/d-i ; sudo fakeroot debian/rules clean ; cd ..
	rm debian-installer-stamp debian-installer*.deb debian-installer*.tar.gz

patch-installer: patch-installer-stamp
patch-installer-stamp:
	patch -p0 < $(DEBIAN_INSTALLER_PATCH)
	patch -p0 < $(DEBIAN_CD_PATCH)
	touch $@

unpatch-installer:
	if [ -f patch-installer-stamp ] ; then \
	  patch -p0 -R < $(DEBIAN_INSTALLER_PATCH) ; \
	  patch -p0 -R < $(DEBIAN_CD_PATCH) ; \
	  rm -f patch-installer-stamp ; \
	fi

debian-installer: debian-installer-stamp
debian-installer-stamp: 
	perl -pe 's|\+DISTRIBUTION\+|'$(DISTRIBUTION)'| ; s|\+REPOSITORY\+|'$(REPOSITORY)'|' $(ISOTOOLS_DIR)/d-i.sources.template >| $(ISOTOOLS_DIR)/d-i/build/sources.list.udeb.local
	cd $(ISOTOOLS_DIR)/d-i ; sudo fakeroot debian/rules binary
	touch $@

repoint-stable:
	$(PKGTOOLS_DIR)/package-server-proxy.sh $(PKGTOOLS_DIR)/create-di-links.sh $(REPOSITORY) $(DISTRIBUTION)

iso-conf:
	perl -pe 's|\+DISTRIBUTION\+|'$(DISTRIBUTION)'| ; s|\+REPOSITORY\+|'$(REPOSITORY)'|' $(ISOTOOLS_DIR)/d-i.sources.template >| $(ISOTOOLS_DIR)/d-i/build/sources.list.udeb.local
	perl -pe 's|\+ISOTOOLS_DIR\+|'$(ISOTOOLS_DIR)'|g' $(CONF_FILE_TEMPLATE) >| $(CONF_FILE)

	cat $(COMMON_PRESEED) $(AUTOPARTITION_PRESEED) $(NETBOOT_PRESEED_EXTRA) $(UNTANGLE_PRESEED) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+ARCH\+|'$(ARCH)'|g ; s|\+REPOSITORY\+|'$(REPOSITORY)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g ; s/^(d-i preseed\/early_command string anna-install.*)/#$1/' >| $(NETBOOT_PRESEED_FINAL)
	cat $(COMMON_PRESEED) $(AUTOPARTITION_PRESEED) $(DEFAULT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+REPOSITORY\+|'$(REPOSITORY)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(DEFAULT_PRESEED_FINAL)
	cat $(COMMON_PRESEED) $(NETBOOT_PRESEED_EXTRA) $(UNTANGLE_PRESEED) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+ARCH\+|'$(ARCH)'|g ; s|\+REPOSITORY\+|'$(REPOSITORY)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g ; s/^(d-i preseed\/early_command string anna-install.*)/#$1/' >| $(NETBOOT_PRESEED_EXPERT)
	cat $(COMMON_PRESEED) $(DEFAULT_PRESEED_EXTRA) | perl -pe 's|\+VERSION\+|'$(VERSION)'|g ; s|\+KERNELS\+|'$(KERNELS_$(ARCH))'|g' >| $(DEFAULT_PRESEED_EXPERT)

iso/%-image: debian-installer iso-conf repoint-stable
	$(eval flavor := $*)
	$(eval iso_dir := /tmp/untangle-images-$(flavor))
	mkdir -p $(iso_dir)
	export TMP_DIR=$(shell mktemp -d /tmp/isotools-stretch-$(flavor)-XXXXXX) ; \
	cd $${TMP_DIR} ; \
	cp -rl $(ISOTOOLS_DIR)/* . 2> /dev/null ; \
	export CODENAME=$(REPOSITORY) DEBVERSION=$(DEBVERSION) OUT=$(iso_dir) ; \
	export CDNAME=$(flavor) DISKTYPE=CUSTOM CUSTOMSIZE=$(CUSTOMSIZE) ; \
	build-simple-cdd --keyring /usr/share/keyrings/untangle-archive-keyring.gpg --force-root --auto-profiles default,untangle,$(flavor) --profiles untangle,$(flavor),expert --debian-mirror http://package-server/public/$(REPOSITORY)/ --security-mirror http://package-server/public/$(REPOSITORY)/ --dist $(REPOSITORY) --require-optional-packages --mirror-tools reprepro --extra-udeb-dist $(DISTRIBUTION) --do-mirror --verbose --logfile $(ISOTOOLS_DIR)/simplecdd.log  #; \
#	rm -fr $${TMP_DIR}
	mv $(iso_dir)/$(flavor)-$(DEBVERSION)*-$(ARCH)-*1.iso $(iso_dir)/$(subst +FLAVOR+,$(flavor),$(ISO_IMAGE))

iso/%-clean:
	rm -fr $(ISOTOOLS_DIR)/tmp /tmp/untangle-images-$*

usb/%-image:
	$(eval flavor := $*)
	$(eval iso_dir := /tmp/untangle-images-$(flavor))
	$(eval iso_image := $(shell ls --sort=time $(iso_dir)/*$(VERSION)*$(REPOSITORY)*$(ARCH)*$(DISTRIBUTION)*.iso | head -1))
	$(ISOTOOLS_DIR)/make_usb.sh $(BOOT_IMG) $(iso_image) $(iso_dir)/$(subst +FLAVOR+,$(flavor),$(USB_IMAGE)) $(flavor)

ova/%-image:
	make -C $(ISOTOOLS_DIR)/ova FLAVOR=$* image
ova/%-push:
	make -C $(ISOTOOLS_DIR)/ova FLAVOR=$* push
ova/%-clean:
	make -C $(ISOTOOLS_DIR)/ova FLAVOR=$* clean

cloud/%-image:
	make -C $(ISOTOOLS_DIR)/cloud FLAVOR=$* image
cloud/%-push:
	make -C $(ISOTOOLS_DIR)/cloud FLAVOR=$* push
cloud/%-clean:
	make -C $(ISOTOOLS_DIR)/cloud FLAVOR=$* clean

iso/%-push: # pushes the most recent images
	$(eval iso_dir := /tmp/untangle-images-$*)
	$(eval iso_image := $(shell ls --sort=time $(iso_dir)/*$(VERSION)*$(REPOSITORY)*$(ARCH)*$(DISTRIBUTION)*.iso | head -1))
	$(eval usb_image := $(shell ls --sort=time $(iso_dir)/*$(VERSION)*$(REPOSITORY)*$(ARCH)*$(DISTRIBUTION)*.img | head -1))
	$(eval timestamp := $(shell echo $(iso_image) | perl -pe 's/.*(\d{4}(-\d{2}){2}T(\d{2}:?){3}).*/$$1/'))
	ssh $(NETBOOT_HOST) "sudo python $(MOUNT_SCRIPT) new $(VERSION) $(timestamp) $(ARCH) $(REPOSITORY)"
	scp $(iso_image) $(usb_image) $(NETBOOT_PRESEED_FINAL) $(NETBOOT_PRESEED_EXPERT) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)
	scp $(NETBOOT_INITRD_TXT) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/initrd-$(ARCH)-txt.gz
	scp $(NETBOOT_INITRD_GTK) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/initrd-$(ARCH)-gtk.gz
	scp $(NETBOOT_KERNEL) $(NETBOOT_HOST):$(IMAGES_DIR)/$(VERSION)/linux-$(ARCH)

	ssh $(NETBOOT_HOST) "sudo python $(MOUNT_SCRIPT) all $(VERSION) foo $(ARCH) $(REPOSITORY)"

# the next 4 rules are generic ones meant for firmware images; they
# take something like "buffalo/wzr1900dhp-image" and make it into
# "make -C firmware/buffalo-wzr1900dhp image"

%-image:
	make -C $(ISOTOOLS_DIR)/firmware/$(subst /,-,$*) image
%-rootfs:
	make -C $(ISOTOOLS_DIR)/firmware/$(subst /,-,$*) rootfs
%-push:
	make -C $(ISOTOOLS_DIR)/firmware/$(subst /,-,$*) push
%-clean:
	make -C $(ISOTOOLS_DIR)/firmware/$(subst /,-,$*) clean

.PHONY: all
