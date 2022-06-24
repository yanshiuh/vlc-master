# rav1e

RAV1E_VERSION := 0.5.1
RAV1E_URL := https://crates.io/api/v1/crates/rav1e/$(RAV1E_VERSION)/download

ifdef BUILD_RUST
ifdef BUILD_ENCODERS
# Rav1e is not linking correctly on iOS arm64
ifndef HAVE_IOS
PKGS += rav1e
endif
endif
endif

ifeq ($(call need_pkg,"rav1e"),)
PKGS_FOUND += rav1e
endif

$(TARBALLS)/rav1e-$(RAV1E_VERSION).tar.gz:
	$(call download_pkg,$(RAV1E_URL),rav1e)

.sum-rav1e: rav1e-$(RAV1E_VERSION).tar.gz

RAV1E_FEATURES=--features=asm

rav1e: rav1e-$(RAV1E_VERSION).tar.gz .sum-rav1e .rav1e-vendor
	$(UNPACK)
ifdef HAVE_WIN32
	$(APPLY) $(SRC)/rav1e/unwind-resume-stub.patch
endif
	$(CARGO_VENDOR_SETUP)
	$(MOVE)

.rav1e: rav1e .cargo
	+cd $< && $(CARGOC_INSTALL) --no-default-features $(RAV1E_FEATURES)
	touch $@
