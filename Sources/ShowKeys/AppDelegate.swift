import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var keyDisplayWindow: KeyDisplayWindow!
    private var keyboardMonitor: KeyboardMonitor!
    private var permissionTimer: Timer?
    private var promptWindow: AccessibilityPromptWindow?

    var isEnabled: Bool {
        get {
            let key = "enabled"
            if UserDefaults.standard.object(forKey: key) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "enabled")
            updateMonitorState()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        keyDisplayWindow  = KeyDisplayWindow()
        statusBarController = StatusBarController(displayWindow: keyDisplayWindow)

        keyboardMonitor = KeyboardMonitor()
        keyboardMonitor.onKeyEvent = { [weak self] text, flags in
            self?.keyDisplayWindow.showKeystroke(text, flags: flags)
        }

        if isEnabled {
            requestAccessibilityIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        keyboardMonitor.stop()
    }

    // MARK: - Accessibility

    private func requestAccessibilityIfNeeded() {
        guard isEnabled else { return }

        NSLog("ShowKeys: checking accessibility trust status...")
        if AXIsProcessTrusted() {
            NSLog("ShowKeys: accessibility is trusted. Starting keyboard monitor.")
            keyboardMonitor.start()
            return
        }

        NSLog("ShowKeys: accessibility is NOT trusted. Prompting user and starting poll timer...")
        
        // Show our warning window
        showAccessibilityPromptWindow()
        
        // Prompt the system dialog
        let opts: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(opts)

        // Poll until granted, then start monitoring
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            NSLog("ShowKeys: polling accessibility trust...")
            guard AXIsProcessTrusted() else { return }
            NSLog("ShowKeys: accessibility trust granted! Starting keyboard monitor.")
            timer.invalidate()
            self?.promptWindow?.close()
            self?.promptWindow = nil
            self?.keyboardMonitor.start()
        }
    }

    func updateMonitorState() {
        if isEnabled {
            requestAccessibilityIfNeeded()
        } else {
            permissionTimer?.invalidate()
            permissionTimer = nil
            promptWindow?.close()
            promptWindow = nil
            keyboardMonitor.stop()
            keyDisplayWindow.clearKeystrokes()
        }
    }

    func showAccessibilityPromptWindow() {
        if promptWindow == nil {
            promptWindow = AccessibilityPromptWindow()
        }
        promptWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
