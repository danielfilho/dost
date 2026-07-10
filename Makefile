PREFIX ?= /Applications
BINARY = .build/release/dost
UNIVERSAL = .build/apple/Products/Release/dost
IDENTITY ?= Developer ID Application
NOTARY_PROFILE ?= notary
VERSION = $(shell sed -n 's/.*static let version = "\(.*\)".*/\1/p' Sources/dost/Config.swift)

.PHONY: build run app install dist clean

build:
	swift build -c release

run: build
	$(BINARY)

app: build
	rm -rf dost.app
	mkdir -p dost.app/Contents/MacOS
	cp Support/Info.plist dost.app/Contents/Info.plist
	cp $(BINARY) dost.app/Contents/MacOS/dost

install: app
	rm -rf "$(PREFIX)/dost.app"
	cp -R dost.app "$(PREFIX)/"

# Universal (arm64 + x86_64) zip for GitHub releases / the homebrew cask.
# Needs a "Developer ID Application" certificate in the keychain and notary
# credentials stored once via:
#   xcrun notarytool store-credentials notary --apple-id <id> --team-id <team>
dist:
	swift build -c release --arch arm64 --arch x86_64
	rm -rf dost.app
	mkdir -p dost.app/Contents/MacOS
	cp Support/Info.plist dost.app/Contents/Info.plist
	cp $(UNIVERSAL) dost.app/Contents/MacOS/dost
	codesign --force --options runtime --timestamp --sign "$(IDENTITY)" dost.app
	mkdir -p dist
	ditto -c -k --keepParent dost.app dist/dost-$(VERSION).zip
	xcrun notarytool submit dist/dost-$(VERSION).zip --keychain-profile $(NOTARY_PROFILE) --wait
	xcrun stapler staple dost.app
	ditto -c -k --keepParent dost.app dist/dost-$(VERSION).zip
	shasum -a 256 dist/dost-$(VERSION).zip

clean:
	rm -rf .build dist dost.app
