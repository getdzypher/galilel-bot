# The autoconf initilization.
AC_INIT(galilel-bot, 0.0.1, [mbroemme@libmpq.org], [galilel-bot])

# Detect the canonical host and target build environment
AC_CANONICAL_SYSTEM

AM_INIT_AUTOMAKE([no-dependencies])
AC_CONFIG_HEADERS([config.h:config.h.in])

# Notices
AC_PREREQ(2.53)
AC_REVISION($Revision: 1.6 $)

# Exporting some required variables.
AC_PATH_PROG([bashpath], [bash], [no])
if test "$bashpath" = "no"; then
	AC_MSG_ERROR([bash binary is required])
fi
AC_PATH_PROG([bcpath], [bc], [no])
if test "$bcpath" = "no"; then
	AC_MSG_ERROR([bc binary is required])
fi
AC_PATH_PROG([chmodpath], [chmod], [no])
if test "$chmodpath" = "no"; then
	AC_MSG_ERROR([chmod binary is required])
fi
AC_PATH_PROG([curlpath], [curl], [no])
if test "$curlpath" = "no"; then
	AC_MSG_ERROR([curl binary is required])
fi
AC_PATH_PROG([datepath], [date], [no])
if test "$datepath" = "no"; then
	AC_MSG_ERROR([date binary is required])
fi
AC_PATH_PROG([jshonpath], [jshon], [no])
if test "$jshonpath" = "no"; then
	AC_MSG_ERROR([jshon binary is required])
fi
AC_PATH_PROG([lnpath], [ln], [no])
if test "$lnpath" = "no"; then
	AC_MSG_ERROR([ln binary is required])
fi
AC_PATH_PROG([mkdirpath], [mkdir], [no])
if test "$mkdirpath" = "no"; then
	AC_MSG_ERROR([mkdir binary is required])
fi
AC_PATH_PROG([realpathpath], [realpath], [no])
if test "$realpathpath" = "no"; then
	AC_MSG_ERROR([realpath binary is required])
fi
AC_PATH_PROG([rmpath], [rm], [no])
if test "$rmpath" = "no"; then
	AC_MSG_ERROR([rm binary is required])
fi
AC_PATH_PROG([sedpath], [sed], [no])
if test "$sedpath" = "no"; then
	AC_MSG_ERROR([sed binary is required])
fi

# Creating files.
AC_OUTPUT([
Makefile
conf/Makefile
src/Makefile
])
