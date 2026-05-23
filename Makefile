APP_NAME   = ShowKeys
BUILD_DIR  = .build/release
APP_BUNDLE = $(APP_NAME).app
BINARY     = $(BUILD_DIR)/$(APP_NAME)

.PHONY: all build bundle run clean

all: bundle

build:
	swift build -c release

bundle: build
	@echo "→ Creating $(APP_BUNDLE)..."
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(BINARY) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@codesign --force --deep --sign - $(APP_BUNDLE)
	@echo "✓ $(APP_BUNDLE) created and signed"
	@echo ""
	@echo "Run with:  open $(APP_BUNDLE)"
	@echo "Or drag it to /Applications."

run: bundle
	open $(APP_BUNDLE)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)
