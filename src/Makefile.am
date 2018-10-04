# The top-level input Makefile for galilel-bot

# minimum required automake 1.6
AUTOMAKE_OPTIONS = 1.6

# architecture-independent script files
galilel_botdir = $(libdir)/galilel-bot
galilel_bot_DATA = galilel-bot.bash

EXTRA_DIST = $(galilel_bot_DATA)

# symlink main script to binary search path (requires uninstall-hook).
install-data-hook:
	$(sedpath) 's,@BASENAME@,${basenamepath},g' -i $(DESTDIR)${galilel_botdir}/galilel-bot.bash
	$(sedpath) 's,@BASH@,${bashpath},g' -i $(DESTDIR)${galilel_botdir}/galilel-bot.bash
	$(sedpath) 's,@DATE@,${datepath},g' -i $(DESTDIR)${galilel_botdir}/galilel-bot.bash
	$(sedpath) 's,@GALILEL_BOT_AUTHOR@,$(PACKAGE_BUGREPORT),g' -i $(DESTDIR)${galilel_botdir}/galilel-bot.bash
	$(sedpath) 's,@GALILEL_BOT_VERSION@,$(PACKAGE_VERSION),g' -i $(DESTDIR)${galilel_botdir}/galilel-bot.bash
	$(sedpath) 's,@SYSCONFDIR@,$(DESTDIR)$(sysconfdir),g' -i $(DESTDIR)${galilel_botdir}/galilel-bot.bash
	$(chmodpath) 0755 $(DESTDIR)${galilel_botdir}/galilel-bot.bash
	$(mkdirpath) -p $(DESTDIR)$(bindir)
	$(lnpath) -s $(DESTDIR)${galilel_botdir}/galilel-bot.bash $(DESTDIR)$(bindir)/galilel-bot

# remove symlink from binary search path (created with install-data-hook).
uninstall-hook:
	$(rmpath) -f $(DESTDIR)$(bindir)/galilel-bot
