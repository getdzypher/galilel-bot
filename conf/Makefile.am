# The top-level input Makefile for galilel-bot

# minimum required automake 1.6
AUTOMAKE_OPTIONS = 1.6

# architecture-independent config files
galilel_botdir = $(sysconfdir)/galilel
galilel_bot_DATA = galilel-bot.conf.example

EXTRA_DIST = $(galilel_bot_DATA)

install-data-hook:
	$(chmodpath) 0644 $(DESTDIR)$(galilel_botdir)/galilel-bot.conf.example
