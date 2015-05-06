# Functions to convert isolinux config to allow selection of desktop
# environment for certain images.

# All config file names need to be in 8.3 format!
# For that reason files that get a "desktop"  postfix are renamed as
# follows: adtxt->at, adgtk->ag.
# With two characters (dt) for the postfix this will leave as maximum
# for example: amdtxtdt.cfg or amdatdt.cfg.

make_desktop_template() {
	# Split rescue labels out of advanced options files
	for file in boot$N/isolinux/*ad*.cfg; do
		rq_file="$(echo "$file" | sed -r "s:/(amd)?ad:/\1rq:")"
		sed -rn "s:desktop=[^ ]*::
			 /^label (amd64-)?rescue/,+3 p" $file >$rq_file
		sed -ri "/^label (amd64-)?rescue/ i\include $(basename $rq_file)
			 /^label (amd64-)?rescue/,+3 d" $file
	done

	mkdir -p boot$N/isolinux/desktop

	cp boot$N/isolinux/menu.cfg boot$N/isolinux/desktop/menu.cfg
	sed -i "/^menu hshift/,/^include stdmenu/ d
		s:include :include %desktop%/:
		/include .*stdmenu/ s:%desktop%/::
		s:config :config %desktop%/:" \
		boot$N/isolinux/desktop/menu.cfg
	cp boot$N/isolinux/desktop/menu.cfg boot$N/isolinux/desktop/prmenu.cfg
	sed -ri "s:(include.*(txt|gtk))(\.cfg):\1dt\3:
		 /include.*(txt|gtk)/ {s:adtxt:at:; s:adgtk:ag:}" \
		boot$N/isolinux/desktop/menu.cfg
	sed -i "/menu begin advanced/ s:ced:ced-%desktop%:
		/Advanced options/ i\    menu label Advanced options
		/label mainmenu/ s:mainmenu:dtmenu-%desktop%:
		/label help/ s:help:help-%desktop%:" \
		boot$N/isolinux/desktop/menu.cfg
	sed -i "/^[[:space:]]*menu/ d
		/label mainmenu/ d
		/include stdmenu/ d
		s:^[[:space:]]*::
		/label help/,+5 d" \
		boot$N/isolinux/desktop/prmenu.cfg

	cp boot$N/isolinux/prompt.cfg boot$N/isolinux/desktop/prompt.cfg
	sed -i "/include menu/ a\default install
		s:include menu:include %desktop%/prmenu:" \
		boot$N/isolinux/desktop/prompt.cfg

	for file in boot$N/isolinux/*txt.cfg boot$N/isolinux/*gtk.cfg; do
		[ -e "$file" ] || continue
		# Skip rescue include files
		if $(echo $file | grep -Eq "/(amd)?rq"); then
			continue
		fi

		# Create two types of desktop include files: for vesa menu and
		# for prompt; the latter keep the original name, the former
		# get a 'dt' postfix and the name is shortened if needed
		dt_prfile="$(dirname "$file")/desktop/$(basename "$file")"
		dt_file="${dt_prfile%.cfg}dt.cfg"
		dt_file="$(echo "$dt_file" | \
			sed -r "s:adtxt:at:
				s:adgtk:ag:")"
		cp $file $dt_file
		sed -ri "/^default/ s:^:#:
			 /include (amd)?rq/ d
			 s:desktop=[^ ]*:desktop=%desktop%:" \
			$dt_file
		cp $dt_file $dt_prfile
		sed -i "/^label/ s:[[:space:]]*$:-%desktop%:" \
			$dt_file
	done
}

modify_for_light_desktop() {
	make_desktop_template

	cp -r boot$N/isolinux/desktop boot$N/isolinux/xfce
	sed -i "s:%desktop%:xfce:g" boot$N/isolinux/xfce/*.cfg
	sed -i "/Advanced options/ s:title:title Xfce:" \
		boot$N/isolinux/xfce/menu.cfg

	cp -r boot$N/isolinux/desktop boot$N/isolinux/lxde
	sed -i "s:%desktop%:lxde:g" boot$N/isolinux/lxde/*.cfg
	sed -i "/Advanced options/ s:title:title LXDE:" \
		boot$N/isolinux/lxde/menu.cfg

	# Cleanup
	rm -r boot$N/isolinux/desktop
	for file in boot$N/isolinux/*txt.cfg boot$N/isolinux/*gtk.cfg \
		    boot$N/isolinux/prompt.cfg; do
		[ -e "$file" ] || continue
		# Skip rescue include files
		if $(echo $file | grep -q "/rq"); then
			continue
		fi

		rm $file
	done

	# Create new "top level" menu file
	cat >boot$N/isolinux/menu.cfg <<EOF
menu hshift 13
menu width 49

include stdmenu.cfg
menu title Desktop environment menu
menu begin lxde-desktop
    include stdmenu.cfg
    menu label ^LXDE
    menu title LXDE desktop boot menu
    text help
   Select the 'Lightweight X11 Desktop Environment' for the Desktop task
    endtext
    label mainmenu-lxde
        menu label ^Back..
        menu exit
    include lxde/menu.cfg
menu end
menu begin xfce-desktop
    include stdmenu.cfg
    menu label ^Xfce
    menu title Xfce desktop boot menu
    text help
   Select the 'Xfce lightweight desktop environment' for the Desktop task
    endtext
    label mainmenu-xfce
        menu label ^Back..
        menu exit
    include xfce/menu.cfg
menu end
menu begin rescue
    include stdmenu.cfg
    menu label ^System rescue
    menu title System rescue boot menu
    label mainmenu-rescue
        menu label ^Back..
        menu exit
    include rqtxt.cfg
    include amdrqtxt.cfg
    include rqgtk.cfg
    include amdrqgtk.cfg
menu end
EOF
}

modify_for_all_desktop() {
	make_desktop_template

	# Remove desktop option in root config files (for GNOME)
	sed -i "s:desktop=[^ ]*::" boot$N/isolinux/*.cfg

	cp -r boot$N/isolinux/desktop boot$N/isolinux/kde
	sed -i "s:%desktop%:kde:g" boot$N/isolinux/kde/*.cfg
	sed -i "/Advanced options/ s:title:title KDE:" \
		boot$N/isolinux/kde/menu.cfg

	cp -r boot$N/isolinux/desktop boot$N/isolinux/xfce
	sed -i "s:%desktop%:xfce:g" boot$N/isolinux/xfce/*.cfg
	sed -i "/Advanced options/ s:title:title Xfce:" \
		boot$N/isolinux/xfce/menu.cfg

	cp -r boot$N/isolinux/desktop boot$N/isolinux/lxde
	sed -i "s:%desktop%:lxde:g" boot$N/isolinux/lxde/*.cfg
	sed -i "/Advanced options/ s:title:title LXDE:" \
		boot$N/isolinux/lxde/menu.cfg

	# Cleanup
	rm -r boot$N/isolinux/desktop

	# Create desktop menu file
	cat >boot$N/isolinux/dtmenu.cfg <<EOF
menu begin desktop
    include stdmenu.cfg
    menu hshift 13
    menu width 49
    menu label Alternative desktop environments
    menu title Desktop environment menu
    label mainmenu-kde
        menu label ^Back..
        text help
        Higher level options install the GNOME desktop environment
        endtext
        menu exit
    menu begin kde-desktop
        include stdmenu.cfg
        menu label ^KDE
        menu title KDE desktop boot menu
        text help
   Select the 'K Desktop Environment' for the Desktop task
        endtext
        label mainmenu-kde
            menu label ^Back..
            menu exit
        include kde/menu.cfg
    menu end
    menu begin lxde-desktop
        include stdmenu.cfg
        menu label ^LXDE
        menu title LXDE desktop boot menu
        text help
       Select the 'Lightweight X11 Desktop Environment' for the Desktop task
        endtext
        label mainmenu-lxde
            menu label ^Back..
            menu exit
        include lxde/menu.cfg
    menu end
    menu begin xfce-desktop
        include stdmenu.cfg
        menu label ^Xfce
        menu title Xfce desktop boot menu
        text help
   Select the 'Xfce lightweight desktop environment' for the Desktop task
        endtext
        label mainmenu-xfce
            menu label ^Back..
            menu exit
        include xfce/menu.cfg
    menu end
menu end
EOF

	# Include desktop submenu in Advanced options submenu
	sed -i "/menu end/ i\\\tinclude dtmenu.cfg" \
		boot$N/isolinux/menu.cfg
}
