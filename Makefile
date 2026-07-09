PREFIX ?= /Applications
BINARY = .build/release/dost
UNIVERSAL = .build/apple/Products/Release/dost
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
dist:
	swift build -c release --arch arm64 --arch x86_64
	rm -rf dost.app
	mkdir -p dost.app/Contents/MacOS
	cp Support/Info.plist dost.app/Contents/Info.plist
	cp $(UNIVERSAL) dost.app/Contents/MacOS/dost
	codesign --force --sign - dost.app
	mkdir -p dist
	ditto -c -k --keepParent dost.app dist/dost-$(VERSION).zip
	shasum -a 256 dist/dost-$(VERSION).zip

clean:
	rm -rf .build dist dost.app
