class Bsdmainutils < Formula
  desc "Lots of small programs found in a BSD-style Unix system."
  homepage "https://packages.debian.org/jessie/bsdmainutils"
  url "http://http.debian.net/debian/pool/main/b/bsdmainutils/bsdmainutils_9.0.6.tar.gz"
  sha256 "48868ac99c8dd92a69bb430e6bdf865602522ad3a2f5a0dd9cae77b46fc93b57"

  patch :DATA

  def install
    system "make", "DESTDIR=#{prefix}", "install"
  end

  test do
    system "cal", "-3"
  end
end

__END__
diff -ur bsdmainutils-9.0.6/Makefile bsdmainutils-9.0.6/Makefile
--- bsdmainutils-9.0.6/Makefile	2014-04-27 02:35:21.000000000 -0700
+++ bsdmainutils-9.0.6/Makefile	2015-06-10 16:31:56.000000000 -0700
@@ -14,8 +14,9 @@
 	$(call rmake,clean)
 
 install: all
-	mkdir -p $(DESTDIR)/usr/bin
-	mkdir -p $(DESTDIR)/usr/share/man/man1
+	mkdir -p $(DESTDIR)/bin
+	mkdir -p $(DESTDIR)/share/man/man1
+	mkdir -p $(DESTDIR)/share/man/man6
 
 	$(call rmake,install)
 
diff -ur bsdmainutils-9.0.6/config.mk bsdmainutils-9.0.6/config.mk
--- bsdmainutils-9.0.6/config.mk	2014-10-17 03:54:06.000000000 -0700
+++ bsdmainutils-9.0.6/config.mk	2015-06-10 16:34:55.000000000 -0700
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
 
diff -ur bsdmainutils-9.0.6/usr.bin/banner/Makefile bsdmainutils-9.0.6/usr.bin/banner/Makefile
--- bsdmainutils-9.0.6/usr.bin/banner/Makefile	2014-04-27 02:35:22.000000000 -0700
+++ bsdmainutils-9.0.6/usr.bin/banner/Makefile	2015-06-10 16:31:26.000000000 -0700
@@ -1,11 +1,10 @@
-PROG = printerbanner
+PROG = banner
 MAN = banner.6
 
 topdir=../..
 include $(topdir)/config.mk
 
-printerbanner.o: banner.c
-	$(CC) -include $(topdir)/freebsd.h $(FLAGS) $(CFLAGS) -c -o $@ $<
+mandir=$(datadir)/man/man6
 
-install-2:
-	mv $(mandir)/banner.6 $(mandir)/printerbanner.1
+banner.o: banner.c
+	$(CC) -include $(topdir)/freebsd.h $(FLAGS) $(CFLAGS) -c -o $@ $<
diff -ur bsdmainutils-9.0.6/usr.bin/banner/banner.c bsdmainutils-9.0.6/usr.bin/banner/banner.c
--- bsdmainutils-9.0.6/usr.bin/banner/banner.c	2014-10-17 06:48:26.000000000 -0700
+++ bsdmainutils-9.0.6/usr.bin/banner/banner.c	2015-06-10 15:54:40.000000000 -0700
@@ -44,6 +44,7 @@
 #endif
 
 #include <sys/cdefs.h>
+#include <sys/types.h>
 __FBSDID("$FreeBSD$");
 
 /*
diff -ur bsdmainutils-9.0.6/usr.bin/calendar/calendar.c bsdmainutils-9.0.6/usr.bin/calendar/calendar.c
--- bsdmainutils-9.0.6/usr.bin/calendar/calendar.c	2014-10-17 06:48:27.000000000 -0700
+++ bsdmainutils-9.0.6/usr.bin/calendar/calendar.c	2015-06-10 16:03:27.000000000 -0700
@@ -35,7 +35,6 @@
 #include <err.h>
 #include <errno.h>
 #include <locale.h>
-#include <login_cap.h>
 #include <pwd.h>
 #include <signal.h>
 #include <stdio.h>
@@ -170,10 +169,9 @@
 				continue;
 			case 0:	/* child */
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
diff -ur bsdmainutils-9.0.6/usr.bin/calendar/calendar.h bsdmainutils-9.0.6/usr.bin/calendar/calendar.h
--- bsdmainutils-9.0.6/usr.bin/calendar/calendar.h	2014-10-17 06:48:27.000000000 -0700
+++ bsdmainutils-9.0.6/usr.bin/calendar/calendar.h	2015-06-10 15:59:23.000000000 -0700
@@ -29,6 +29,7 @@
  * SUCH DAMAGE.
  */
 
+#include <sys/types.h>
 
 extern struct passwd *pw;
 extern int doall;
diff -ur bsdmainutils-9.0.6/usr.bin/from/Makefile bsdmainutils-9.0.6/usr.bin/from/Makefile
--- bsdmainutils-9.0.6/usr.bin/from/Makefile	2014-04-27 02:35:22.000000000 -0700
+++ bsdmainutils-9.0.6/usr.bin/from/Makefile	2015-06-10 16:36:22.000000000 -0700
@@ -1,14 +1,11 @@
-PROG = bsd-from
+PROG = from
 MAN = from.1
 
 topdir=../..
 include $(topdir)/config.mk
 
-bsd-from.o: from.c
+from.o: from.c
 	$(CC) -include $(topdir)/freebsd.h $(FLAGS) $(CFLAGS) -c -o $@ $<
 
-install-2:
-	mv $(mandir)/from.1 $(mandir)/bsd-from.1
-
 topdir=../..
 include $(topdir)/config.mk
diff -ur bsdmainutils-9.0.6/usr.bin/ncal/ncal.c bsdmainutils-9.0.6/usr.bin/ncal/ncal.c
--- bsdmainutils-9.0.6/usr.bin/ncal/ncal.c	2014-10-17 06:48:27.000000000 -0700
+++ bsdmainutils-9.0.6/usr.bin/ncal/ncal.c	2015-06-10 16:00:46.000000000 -0700
@@ -29,7 +29,7 @@
   "$FreeBSD$";
 #endif /* not lint */
 
-#include <calendar.h>
+#include "calendar.h"
 #include <ctype.h>
 #include <err.h>
 #include <langinfo.h>
diff -ur bsdmainutils-9.0.6/usr.bin/write/Makefile bsdmainutils-9.0.6/usr.bin/write/Makefile
--- bsdmainutils-9.0.6/usr.bin/write/Makefile	2014-04-27 02:35:22.000000000 -0700
+++ bsdmainutils-9.0.6/usr.bin/write/Makefile	2015-06-10 16:46:58.000000000 -0700
@@ -1,13 +1,8 @@
-PROG = bsd-write
+PROG = write
 MAN = write.1
 
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
