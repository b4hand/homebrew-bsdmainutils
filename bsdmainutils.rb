class Bsdmainutils < Formula
  desc "collection of more utilities from FreeBSD."
  homepage "https://packages.debian.org/buster/bsdmainutils"
  url "https://deb.debian.org/debian/pool/main/b/bsdmainutils/bsdmainutils_11.1.2.tar.gz"
  sha256 "101c0dede5f599921533da08a46b53a60936445e54aa5df1b31608f1407fee60"

  patch :DATA

  def install
    system "make", "DESTDIR=#{prefix}", "install"
  end

  test do
    system "cal", "-3"
  end
end

__END__
diff -ruN bsdmainutils-11.1.2/Makefile bsdmainutils-11.1.2/Makefile
--- bsdmainutils-11.1.2/Makefile       2017-12-29 01:02:08.000000000 -0800
+++ bsdmainutils-11.1.2/Makefile       2024-11-26 22:04:26.329981388 -0800
@@ -14,8 +14,9 @@
 	$(call rmake,clean)
 
 install: all
-	mkdir -p $(DESTDIR)/usr/bin
-	mkdir -p $(DESTDIR)/usr/share/man/man1
+	mkdir -p $(DESTDIR)/bin
+	mkdir -p $(DESTDIR)/share/man/man1
+	mkdir -p $(DESTDIR)/share/man/man6
 
 	$(call rmake,install)
 
diff -ruN bsdmainutils-11.1.2/config.mk bsdmainutils-11.1.2/config.mk
--- bsdmainutils-11.1.2/config.mk	2017-12-29 01:02:08.000000000 -0800
+++ bsdmainutils-11.1.2/config.mk	2024-11-26 19:51:50.811971981 -0800
@@ -23,8 +23,8 @@
 MAN ?= $(PROG).1
 
 sysconfdir=$(DESTDIR)/etc
-datadir=$(DESTDIR)/usr/share
-bindir=$(DESTDIR)/usr/bin
+datadir=$(DESTDIR)/share
+bindir=$(DESTDIR)/bin
 mandir=$(datadir)/man/man1
 
 # rule for building the program
@@ -43,8 +43,8 @@
 
 # normal installation rule
 install-1: $(PROG)
-	install -o root -g root -m 755 $(PROG) $(bindir)
-	install -o root -g root -m 644 $(MAN) $(mandir)
+	install -m 755 $(PROG) $(bindir)
+	install -m 644 $(MAN) $(mandir)
 
 install: install-1 install-2
 
diff -ruN bsdmainutils-11.1.2/usr.bin/banner/Makefile bsdmainutils-11.1.2/usr.bin/banner/Makefile
--- bsdmainutils-11.1.2/usr.bin/banner/Makefile	2017-12-29 01:02:08.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/banner/Makefile	2024-11-26 19:25:29.417968011 -0800
@@ -1,12 +1,6 @@
 PROG = banner
 SRC = banner.c
 MAN = banner.6
-LIBS += -lbsd
-FLAGS = -include bsd/string.h
 
 topdir=../..
 include $(topdir)/config.mk
-
-install-2:
-	mv $(mandir)/banner.6 $(mandir)/printerbanner.1
-	mv $(bindir)/banner $(bindir)/printerbanner
diff -ruN bsdmainutils-11.1.2/usr.bin/banner/banner.c bsdmainutils-11.1.2/usr.bin/banner/banner.c
--- bsdmainutils-11.1.2/usr.bin/banner/banner.c	2017-12-29 01:02:08.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/banner/banner.c	2024-11-26 19:24:58.465819791 -0800
@@ -42,6 +42,7 @@
 #endif
 
 #include <sys/cdefs.h>
+#include <sys/types.h>
 __FBSDID("$FreeBSD: head/usr.bin/banner/banner.c 326025 2017-11-20 19:49:47Z pfg $");
 
 /*
diff -ruN bsdmainutils-11.1.2/usr.bin/calendar/Makefile bsdmainutils-11.1.2/usr.bin/calendar/Makefile
--- bsdmainutils-11.1.2/usr.bin/calendar/Makefile	2017-12-29 01:02:08.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/calendar/Makefile	2024-11-26 19:26:20.280439434 -0800
@@ -1,7 +1,6 @@
 PROG = calendar
 SRC  = calendar.c io.c day.c ostern.c paskha.c pesach.c
-LIBS = -lbsd
-FLAGS = -include sys/uio.h -include bsd/stdlib.h
+FLAGS = -include sys/uio.h
 
 topdir=../..
 include $(topdir)/config.mk
diff -ruN bsdmainutils-11.1.2/usr.bin/calendar/calendar.c bsdmainutils-11.1.2/usr.bin/calendar/calendar.c
--- bsdmainutils-11.1.2/usr.bin/calendar/calendar.c	2017-12-29 01:02:08.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/calendar/calendar.c	2024-11-26 19:48:29.468110925 -0800
@@ -35,7 +35,6 @@
 #include <err.h>
 #include <errno.h>
 #include <locale.h>
-#include <login_cap.h>
 #include <pwd.h>
 #include <signal.h>
 #include <stdio.h>
@@ -123,15 +122,6 @@
 	if (argc)
 		usage();
 
-	if (doall) {
-		if (pledge("stdio rpath tmppath fattr getpw id proc exec", NULL)
-		    == -1)
-			err(1, "pledge");
-	} else {
-		if (pledge("stdio rpath proc exec", NULL) == -1)
-			err(1, "pledge");
-	}
-
 	/* use current time */
 	if (f_time <= 0)
 	    (void)time(&f_time);
@@ -190,10 +180,9 @@
 			case 0:	/* child */
 				(void)setpgid(getpid(), getpid());
 				(void)setlocale(LC_ALL, "");
-				if (setusercontext(NULL, pw, pw->pw_uid,
-				    LOGIN_SETALL ^ LOGIN_SETLOGIN))
-					err(1, "unable to set user context (uid %u)",
-					    pw->pw_uid);
+				(void)setegid(pw->pw_gid);
+				(void)initgroups(pw->pw_name, pw->pw_gid);
+				(void)seteuid(pw->pw_uid);
 				if (acstat) {
 					if (chdir(pw->pw_dir) ||
 					    stat(calendarFile, &sbuf) != 0 ||
diff -ruN bsdmainutils-11.1.2/usr.bin/calendar/calendar.h bsdmainutils-11.1.2/usr.bin/calendar/calendar.h
--- bsdmainutils-11.1.2/usr.bin/calendar/calendar.h	2017-12-29 01:02:08.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/calendar/calendar.h	2024-11-26 19:49:46.379347040 -0800
@@ -29,6 +29,7 @@
  * SUCH DAMAGE.
  */
 
+#include <sys/types.h>
 
 extern struct passwd *pw;
 extern int doall;
diff -ruN bsdmainutils-11.1.2/usr.bin/col/Makefile bsdmainutils-11.1.2/usr.bin/col/Makefile
--- bsdmainutils-11.1.2/usr.bin/col/Makefile	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/col/Makefile	2024-11-26 20:54:01.887754376 -0800
@@ -1,6 +1,5 @@
 PROG = col
-LIBS += -lbsd
-FLAGS = -D_GNU_SOURCE -include limits.h -include bsd/stdlib.h
+FLAGS = -D_GNU_SOURCE -include limits.h
 
 topdir=../..
 include $(topdir)/config.mk
diff -ruN bsdmainutils-11.1.2/usr.bin/col/col.c bsdmainutils-11.1.2/usr.bin/col/col.c
--- bsdmainutils-11.1.2/usr.bin/col/col.c	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/col/col.c	2024-11-26 20:54:38.711234185 -0800
@@ -47,9 +47,6 @@
 #include <sys/cdefs.h>
 __FBSDID("$FreeBSD: head/usr.bin/col/col.c 326025 2017-11-20 19:49:47Z pfg $");
 
-#include <sys/capsicum.h>
-
-#include <capsicum_helpers.h>
 #include <err.h>
 #include <errno.h>
 #include <locale.h>
@@ -141,12 +138,6 @@
 
 	(void)setlocale(LC_CTYPE, "");
 
-	if (caph_limit_stdio() == -1)
-		err(1, "unable to limit stdio");
-
-	if (cap_enter() < 0 && errno != ENOSYS)
-		err(1, "unable to enter capability mode");
-
 	max_bufd_lines = 256;
 	compress_spaces = 1;		/* compress spaces into tabs */
 	while ((opt = getopt(argc, argv, "bfhl:px")) != -1)
diff -ruN bsdmainutils-11.1.2/usr.bin/from/Makefile bsdmainutils-11.1.2/usr.bin/from/Makefile
--- bsdmainutils-11.1.2/usr.bin/from/Makefile	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/from/Makefile	2024-11-26 19:53:14.473698217 -0800
@@ -1,14 +1,11 @@
-PROG = bsd-from
+PROG = from
 MAN = from.1
 
 topdir=../..
 include $(topdir)/config.mk
 
-bsd-from.o: from.c
+from.o: from.c
 	$(CC) -include $(topdir)/freebsd.h $(FLAGS) $(CFLAGS) -c -o $@ $<
-
-install-2:
-	mv $(mandir)/from.1 $(mandir)/bsd-from.1
 
 topdir=../..
 include $(topdir)/config.mk
diff -ruN bsdmainutils-11.1.2/usr.bin/hexdump/Makefile bsdmainutils-11.1.2/usr.bin/hexdump/Makefile
--- bsdmainutils-11.1.2/usr.bin/hexdump/Makefile	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/hexdump/Makefile	2024-11-26 20:55:48.057995281 -0800
@@ -1,5 +1,4 @@
-FLAGS = -D_GNU_SOURCE -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -include bsd/string.h 
-LIBS += -lbsd
+FLAGS = -D_GNU_SOURCE -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64
 
 PROG = hexdump
 SRC  = conv.c display.c hexdump.c hexsyntax.c odsyntax.c parse.c
diff -ruN bsdmainutils-11.1.2/usr.bin/hexdump/display.c bsdmainutils-11.1.2/usr.bin/hexdump/display.c
--- bsdmainutils-11.1.2/usr.bin/hexdump/display.c	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/hexdump/display.c	2024-11-26 20:57:02.529571039 -0800
@@ -38,10 +38,8 @@
 __FBSDID("$FreeBSD: head/usr.bin/hexdump/display.c 326025 2017-11-20 19:49:47Z pfg $");
 
 #include <sys/param.h>
-#include <sys/capsicum.h>
 #include <sys/stat.h>
 
-#include <capsicum_helpers.h>
 #include <ctype.h>
 #include <err.h>
 #include <errno.h>
@@ -361,17 +359,6 @@
 			statok = 0;
 		}
 
-		if (caph_limit_stream(fileno(stdin), CAPH_READ) < 0)
-			err(1, "unable to restrict %s",
-			    statok ? *_argv : "stdin");
-
-		/*
-		 * We've opened our last input file; enter capsicum sandbox.
-		 */
-		if (statok == 0 || *(_argv + 1) == NULL) {
-			if (cap_enter() < 0 && errno != ENOSYS)
-				err(1, "unable to enter capability mode");
-		}
 
 		if (skip)
 			doskip(statok ? *_argv : "stdin", statok);
diff -ruN bsdmainutils-11.1.2/usr.bin/hexdump/hexdump.c bsdmainutils-11.1.2/usr.bin/hexdump/hexdump.c
--- bsdmainutils-11.1.2/usr.bin/hexdump/hexdump.c	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/hexdump/hexdump.c	2024-11-26 20:57:25.676608947 -0800
@@ -44,8 +44,6 @@
 __FBSDID("$FreeBSD: head/usr.bin/hexdump/hexdump.c 326025 2017-11-20 19:49:47Z pfg $");
 
 #include <sys/types.h>
-#include <sys/capsicum.h>
-#include <capsicum_helpers.h>
 #include <err.h>
 #include <locale.h>
 #include <stdlib.h>
@@ -81,14 +79,6 @@
 	for (tfs = fshead; tfs; tfs = tfs->nextfs)
 		rewrite(tfs);
 
-	/*
-	 * Cache NLS data, for strerror, for err(3), before entering capability
-	 * mode.
-	 */
-	caph_cache_catpages();
-	if (caph_limit_stdio() < 0)
-		err(1, "capsicum");
-
 	(void)next(argv);
 	display();
 	exit(exitval);
diff -ruN bsdmainutils-11.1.2/usr.bin/look/Makefile bsdmainutils-11.1.2/usr.bin/look/Makefile
--- bsdmainutils-11.1.2/usr.bin/look/Makefile	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/look/Makefile	2024-11-26 20:58:14.128123754 -0800
@@ -1,6 +1,5 @@
 PROG = look
-LIBS += -lbsd
-FLAGS = -include bsd/err.h -DSIZE_T_MAX=INT_MAX
+FLAGS = -DSIZE_T_MAX=INT_MAX
 
 topdir=../..
 include $(topdir)/config.mk
diff -ruN bsdmainutils-11.1.2/usr.bin/ncal/Makefile bsdmainutils-11.1.2/usr.bin/ncal/Makefile
--- bsdmainutils-11.1.2/usr.bin/ncal/Makefile	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/ncal/Makefile	2024-11-26 21:00:52.993971799 -0800
@@ -1,8 +1,8 @@
 PROG   = ncal
 SRC    = ncal.c calendar.c easter.c
-FLAGS  = -D_GNU_SOURCE -include bsd/string.h
+LIBS += -lcurses
+FLAGS  = -D_GNU_SOURCE
 
-LIBS  += -ltinfo -lbsd
 
 topdir=../..
 include $(topdir)/config.mk
diff -ruN bsdmainutils-11.1.2/usr.bin/ncal/ncal.c bsdmainutils-11.1.2/usr.bin/ncal/ncal.c
--- bsdmainutils-11.1.2/usr.bin/ncal/ncal.c	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/ncal/ncal.c	2024-11-26 19:54:41.997858648 -0800
@@ -29,7 +29,7 @@
 #include <sys/cdefs.h>
 __FBSDID("$FreeBSD: head/usr.bin/ncal/ncal.c 326276 2017-11-27 15:37:16Z pfg $");
 
-#include <calendar.h>
+#include "calendar.h"
 #include <ctype.h>
 #include <err.h>
 #include <langinfo.h>
diff -ruN bsdmainutils-11.1.2/usr.bin/ul/Makefile bsdmainutils-11.1.2/usr.bin/ul/Makefile
--- bsdmainutils-11.1.2/usr.bin/ul/Makefile	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/ul/Makefile	2024-11-26 21:01:59.686876302 -0800
@@ -1,6 +1,6 @@
 PROG     = ul
-LIBS	+= -ltinfo
-FLAGS	= -D_GNU_SOURCE -include strings.h
+LIBS	+= -lcurses
+FLAGS	= -D_GNU_SOURCE
 
 topdir=../..
 include $(topdir)/config.mk
diff -ruN bsdmainutils-11.1.2/usr.bin/write/Makefile bsdmainutils-11.1.2/usr.bin/write/Makefile
--- bsdmainutils-11.1.2/usr.bin/write/Makefile	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/write/Makefile	2024-11-26 20:53:16.403230864 -0800
@@ -1,15 +1,9 @@
-PROG = bsd-write
+PROG = write
 MAN = write.1
-LIBS += -lbsd
-FLAGS = -include fcntl.h -include time.h -include bsd/string.h 
+FLAGS = -include fcntl.h -include time.h
 
 topdir=../..
 include $(topdir)/config.mk
 
-bsd-write.o: write.c
+write.o: write.c
 	$(CC) -include $(topdir)/freebsd.h $(FLAGS) $(CFLAGS) -c -o $@ $<
-
-install-2:
-	chown root:tty $(bindir)/$(PROG)
-	chmod 2755 $(bindir)/$(PROG)
-	mv $(mandir)/write.1 $(mandir)/bsd-write.1
diff -ruN bsdmainutils-11.1.2/usr.bin/write/write.c bsdmainutils-11.1.2/usr.bin/write/write.c
--- bsdmainutils-11.1.2/usr.bin/write/write.c	2017-12-29 01:02:09.000000000 -0800
+++ bsdmainutils-11.1.2/usr.bin/write/write.c	2024-11-26 20:52:27.598684893 -0800
@@ -48,13 +48,11 @@
 __FBSDID("$FreeBSD: head/usr.bin/write/write.c 326025 2017-11-20 19:49:47Z pfg $");
 
 #include <sys/param.h>
-#include <sys/capsicum.h>
 #include <sys/filio.h>
 #include <sys/signal.h>
 #include <sys/stat.h>
 #include <sys/time.h>
 
-#include <capsicum_helpers.h>
 #include <ctype.h>
 #include <err.h>
 #include <errno.h>
@@ -80,8 +78,6 @@
 int
 main(int argc, char **argv)
 {
-	unsigned long cmds[] = { TIOCGETA, TIOCGWINSZ, FIODGNAME };
-	cap_rights_t rights;
 	struct passwd *pwd;
 	time_t atime;
 	uid_t myuid;
@@ -95,30 +91,6 @@
 	devfd = open(_PATH_DEV, O_RDONLY);
 	if (devfd < 0)
 		err(1, "open(/dev)");
-	cap_rights_init(&rights, CAP_FCNTL, CAP_FSTAT, CAP_IOCTL, CAP_LOOKUP,
-	    CAP_PWRITE);
-	if (cap_rights_limit(devfd, &rights) < 0 && errno != ENOSYS)
-		err(1, "can't limit devfd rights");
-
-	/*
-	 * Can't use capsicum helpers here because we need the additional
-	 * FIODGNAME ioctl.
-	 */
-	cap_rights_init(&rights, CAP_FCNTL, CAP_FSTAT, CAP_IOCTL, CAP_READ,
-	    CAP_WRITE);
-	if ((cap_rights_limit(STDIN_FILENO, &rights) < 0 && errno != ENOSYS) ||
-	    (cap_rights_limit(STDOUT_FILENO, &rights) < 0 && errno != ENOSYS) ||
-	    (cap_rights_limit(STDERR_FILENO, &rights) < 0 && errno != ENOSYS) ||
-	    (cap_ioctls_limit(STDIN_FILENO, cmds, nitems(cmds)) < 0 && errno != ENOSYS) ||
-	    (cap_ioctls_limit(STDOUT_FILENO, cmds, nitems(cmds)) < 0 && errno != ENOSYS) ||
-	    (cap_ioctls_limit(STDERR_FILENO, cmds, nitems(cmds)) < 0 && errno != ENOSYS) ||
-	    (cap_fcntls_limit(STDIN_FILENO, CAP_FCNTL_GETFL) < 0 && errno != ENOSYS) ||
-	    (cap_fcntls_limit(STDOUT_FILENO, CAP_FCNTL_GETFL) < 0 && errno != ENOSYS) ||
-	    (cap_fcntls_limit(STDERR_FILENO, CAP_FCNTL_GETFL) < 0 && errno != ENOSYS))
-		err(1, "can't limit stdio rights");
-
-	caph_cache_catpages();
-	caph_cache_tzdata();
 
 	/*
 	 * Cache UTX database fds.
@@ -137,9 +109,6 @@
 			login = "???";
 	}
 
-	if (cap_enter() < 0 && errno != ENOSYS)
-		err(1, "cap_enter");
-
 	while (getopt(argc, argv, "") != -1)
 		usage();
 	argc -= optind;
