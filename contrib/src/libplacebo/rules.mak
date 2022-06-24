# libplacebo

PLACEBO_VERSION := 1.18.0
PLACEBO_ARCHIVE = libplacebo-v$(PLACEBO_VERSION).tar.gz
PLACEBO_URL := https://code.videolan.org/videolan/libplacebo/-/archive/v$(PLACEBO_VERSION)/$(PLACEBO_ARCHIVE)

DEPS_libplacebo = glslang

ifndef HAVE_WINSTORE
PKGS += libplacebo
endif
ifeq ($(call need_pkg,"libplacebo >= 1.18"),)
PKGS_FOUND += libplacebo
endif

ifdef HAVE_WIN32
DEPS_libplacebo += pthreads $(DEPS_pthreads)
endif

# We don't want vulkan on darwin for now
ifndef HAVE_DARWIN_OS
# This should be enabled on Linux too, but it currently fails picking xcb on
# cross-compilation setup. Test the raspbian build for instance of this issue.
ifndef HAVE_LINUX
DEPS_libplacebo += vulkan-loader $(DEPS_vulkan-loader) vulkan-headers $(DEPS_vulkan-headers)
endif
endif

PLACEBOCONF := -Dglslang=enabled \
	-Dshaderc=disabled

$(TARBALLS)/$(PLACEBO_ARCHIVE):
	$(call download_pkg,$(PLACEBO_URL),libplacebo)

.sum-libplacebo: $(PLACEBO_ARCHIVE)

libplacebo: $(PLACEBO_ARCHIVE) .sum-libplacebo
	$(UNPACK)
	$(APPLY) $(SRC)/libplacebo/0001-meson-fix-glslang-search-path.patch
	$(MOVE)

.libplacebo: libplacebo crossfile.meson
	cd $< && rm -rf ./build
	cd $< && $(HOSTVARS_MESON) $(MESON) $(PLACEBOCONF) build
	cd $< && cd build && ninja install
# Work-around messon issue https://github.com/mesonbuild/meson/issues/4091
	sed -i.orig -e 's/Libs: \(.*\) -L$${libdir} -lplacebo/Libs: -L$${libdir} -lplacebo \1/g' $(PREFIX)/lib/pkgconfig/libplacebo.pc
# Work-around for full paths to static libraries, which libtool does not like
# See https://github.com/mesonbuild/meson/issues/5479
	(cd $(UNPACK_DIR) && $(SRC_BUILT)/pkg-rewrite-absolute.py -i "$(PREFIX)/lib/pkgconfig/libplacebo.pc")
	touch $@
