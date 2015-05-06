dir = usr/share/graphics

files = \
	logo_debian.png \
	logo_untangle.png \
	note_icon.png \
	warning_icon.png

build-local:: $(files)

clean-local::
	rm -f logo_debian.png

install-local:: $(outdir)
	ln -fs logo_debian.png $(outdir)/logo_installer.png

logo_debian.png: logo_debian_joy.svg
	rsvg-convert $< > $@

include ../../../../Makefile.inc
