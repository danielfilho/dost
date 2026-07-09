PREFIX ?= /Applications
BINARY = .build/release/dost

.PHONY: build run app install clean

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

clean:
	rm -rf .build dost.app
