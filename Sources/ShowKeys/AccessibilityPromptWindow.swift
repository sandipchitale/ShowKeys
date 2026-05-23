import Cocoa

final class AccessibilityPromptWindow: NSWindow {
    init() {
        let width: CGFloat = 420
        let height: CGFloat = 220
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        title = "Accessibility Access Required"
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        backgroundColor = .clear
        
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        container.wantsLayer = true
        container.layer?.cornerRadius = 16
        container.layer?.backgroundColor = NSColor(calibratedWhite: 0.14, alpha: 0.95).cgColor
        container.layer?.borderColor = NSColor(calibratedWhite: 0.25, alpha: 1.0).cgColor
        container.layer?.borderWidth = 1.0
        
        // Add subtle shadow
        hasShadow = true
        
        // Icon
        let iconView = NSImageView(frame: NSRect(x: 24, y: height - 84, width: 60, height: 60))
        iconView.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "Security")
        iconView.image?.isTemplate = true
        iconView.contentTintColor = NSColor.systemOrange
        container.addSubview(iconView)
        
        // Title
        let titleLabel = NSTextField(labelWithString: "ShowKeys Needs Accessibility Access")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.frame = NSRect(x: 100, y: height - 48, width: 300, height: 24)
        container.addSubview(titleLabel)
        
        // Description
        let descLabel = NSTextField(wrappingLabelWithString: "To display your keystrokes on screen as you type, ShowKeys requires Accessibility permission.\n\nPlease enable it in System Settings > Privacy & Security > Accessibility.")
        descLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        descLabel.textColor = NSColor(calibratedWhite: 0.8, alpha: 1.0)
        descLabel.frame = NSRect(x: 100, y: height - 128, width: 296, height: 70)
        container.addSubview(descLabel)
        
        // Open Settings Button
        let settingsBtn = NSButton(title: "Open System Settings", target: self, action: #selector(openSettings))
        settingsBtn.bezelStyle = .rounded
        settingsBtn.frame = NSRect(x: width - 180, y: 16, width: 164, height: 32)
        settingsBtn.keyEquivalent = "\r" // Enter key default action
        container.addSubview(settingsBtn)
        
        // Cancel/Quit Button
        let cancelBtn = NSButton(title: "Quit", target: self, action: #selector(quitApp))
        cancelBtn.bezelStyle = .rounded
        cancelBtn.frame = NSRect(x: width - 270, y: 16, width: 80, height: 32)
        container.addSubview(cancelBtn)
        
        contentView = container
        center()
    }
    
    @objc private func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
