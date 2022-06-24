# libdsm

LIBDSM_VERSION := 0.4.3
LIBDSM_URL := https://github.com/videolabs/libdsm/releases/download/v$(LIBDSM_VERSION)/libdsm-$(LIBDSM_VERSION).tar.xz

ifeq ($(call need_pkg,"libdsm >= 0.2.0"),)
PKGS_FOUND += libdsm
endif

$(TARBALLS)/libdsm-$(LIBDSM_VERSION).tar.xz:
	$(call download_pkg,$(LIBDSM_URL),libdsm)

LIBDSM_CONF = $(HOSTCONF)

ifndef WITH_OPTIMIZATION
LIBDSM_CONF += --enable-debug
endif
.sum-libdsm: libdsm-$(LIBDSM_VERSION).tar.xz

libdsm: libdsm-$(LIBDSM_VERSION).tar.xz .sum-libdsm
	$(UNPACK)
	$(MOVE)

DEPS_libdsm = libtasn1 iconv
ifdef HAVE_WIN32
DEPS_libdsm += pthreads $(DEPS_pthreads)
endif

.libdsm: libdsm crossfile.meson
	cd $< && rm -rf ./build
	cd $< && $(HOSTVARS_MESON) $(MESON) -Dauto_features=disabled -Dbinaries=false build
	cd $< && cd build && ninja install
	touch $@
