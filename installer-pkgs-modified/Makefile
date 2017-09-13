DI_PKGS_DIR := $(shell dirname $(MAKEFILE_LIST))
DI_PKGS_PATCH := $(DI_PKGS_DIR)/installer-pkgs.patch

patch: patch-stamp
patch-stamp:
	patch -p2 < $(DI_PKGS_PATCH)
	find . -name "*.orig" -exec /bin/rm {} \;
	touch patch-stamp

unpatch: 
	if [ -f patch-stamp ] ; then \
	  patch -p2 -R < $(DI_PKGS_PATCH) ; \
	  find . -name "*.orig" -exec /bin/rm {} \; ; \
	  rm -f patch-stamp ; \
	fi
