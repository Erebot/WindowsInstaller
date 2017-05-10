# vim:set noet filetype=makefile:

DEPS :=						\
	defaults.xml			\
	Erebot.ico				\
	Erebot.xml				\
	fetch_modules.php		\
	get_version.php			\
	launch.bat				\
	$(wildcard i18n/*.nsh)

all: build/Erebot-setup.exe

build/Erebot-setup.exe: Erebot.nsi $(DEPS)
	makensis $<

.PHONY: all
