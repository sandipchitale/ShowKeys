import Cocoa

final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private weak var displayWindow: KeyDisplayWindow?

    init(displayWindow: KeyDisplayWindow) {
        self.displayWindow = displayWindow
        super.init()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "ShowKeys")
            button.image?.isTemplate = true
        }

        buildMenu()
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        if !AXIsProcessTrusted() {
            let warningItem = NSMenuItem(title: "⚠️ Accessibility Required...", action: #selector(showAccessibilityPrompt(_:)), keyEquivalent: "")
            warningItem.target = self
            menu.addItem(warningItem)
            menu.addItem(.separator())
        }

        let titleItem = NSMenuItem(title: "ShowKeys", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        let toggleItem = NSMenuItem(
            title: "Enabled",
            action: #selector(toggleEnabled(_:)),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        // Corner sub-menu
        let cornerItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        let cornerMenu = NSMenu()
        for corner in CornerPosition.allCases {
            let item = NSMenuItem(
                title: "\(corner.symbol)  \(corner.rawValue)",
                action: #selector(selectCorner(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = corner
            cornerMenu.addItem(item)
        }
        cornerItem.submenu = cornerMenu
        menu.addItem(cornerItem)

        let filterItem = NSMenuItem(
            title: "With Modifier Keys",
            action: #selector(toggleModifierKeysOnly(_:)),
            keyEquivalent: ""
        )
        filterItem.target = self
        menu.addItem(filterItem)

        let stickyItem = NSMenuItem(
            title: "        Sticky",
            action: #selector(toggleSticky(_:)),
            keyEquivalent: ""
        )
        stickyItem.target = self
        menu.addItem(stickyItem)

        // let testItem = NSMenuItem(title: "Test Display", action: #selector(testDisplay(_:)), keyEquivalent: "")
        // testItem.target = self
        // menu.addItem(testItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit ShowKeys", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        menu.delegate = self
    }

    @objc private func selectCorner(_ sender: NSMenuItem) {
        guard let corner = sender.representedObject as? CornerPosition else { return }
        displayWindow?.cornerPosition = corner
    }

    /*
    @objc private func testDisplay(_ sender: NSMenuItem) {
        displayWindow?.showKeystroke("⌘ S")
        displayWindow?.showKeystroke("⌃ ⌥ ⇧ ⌘ A")
        displayWindow?.showKeystroke("Space")
    }
    */

    @objc private func toggleModifierKeysOnly(_ sender: NSMenuItem) {
        let new = !UserDefaults.standard.bool(forKey: "modifierKeysOnly")
        UserDefaults.standard.set(new, forKey: "modifierKeysOnly")
        displayWindow?.clearKeystrokes()
    }

    @objc private func toggleSticky(_ sender: NSMenuItem) {
        let new = !UserDefaults.standard.bool(forKey: "sticky")
        UserDefaults.standard.set(new, forKey: "sticky")
        displayWindow?.clearKeystrokes()
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        if let delegate = NSApplication.shared.delegate as? AppDelegate {
            delegate.isEnabled = !delegate.isEnabled
        }
    }

    @objc private func showAccessibilityPrompt(_ sender: Any) {
        if let delegate = NSApplication.shared.delegate as? AppDelegate {
            delegate.showAccessibilityPromptWindow()
        }
    }

    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleSticky(_:)) {
            return UserDefaults.standard.bool(forKey: "modifierKeysOnly")
        }
        return true
    }
}

// MARK: - NSMenuDelegate — refresh checkmarks when menu opens

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Update visibility of the warning item
        let hasWarning = menu.items.contains { $0.action == #selector(showAccessibilityPrompt(_:)) }
        let trusted = AXIsProcessTrusted()
        
        if !trusted && !hasWarning {
            // Insert warning item at the top
            let warningItem = NSMenuItem(title: "⚠️ Accessibility Required...", action: #selector(showAccessibilityPrompt(_:)), keyEquivalent: "")
            warningItem.target = self
            menu.insertItem(warningItem, at: 0)
            
            let separator = NSMenuItem.separator()
            menu.insertItem(separator, at: 1)
        } else if trusted && hasWarning {
            // Remove warning item and the separator below it
            if let index = menu.items.firstIndex(where: { $0.action == #selector(showAccessibilityPrompt(_:)) }) {
                menu.removeItem(at: index + 1) // separator
                menu.removeItem(at: index) // warning item
            }
        }

        // Refresh Enabled checkmark
        if let toggleItem = menu.item(withTitle: "Enabled") {
            let appDelegate = NSApplication.shared.delegate as? AppDelegate
            toggleItem.state = (appDelegate?.isEnabled ?? true) ? .on : .off
        }

        // Refresh corner checkmarks
        if let submenu = menu.item(withTitle: "Position")?.submenu {
            let current = displayWindow?.cornerPosition
            for item in submenu.items {
                item.state = (item.representedObject as? CornerPosition == current) ? .on : .off
            }
        }
        // Refresh filter checkmark
        if let filterItem = menu.item(withTitle: "With Modifier Keys") {
            filterItem.state = UserDefaults.standard.bool(forKey: "modifierKeysOnly") ? .on : .off
        }
        // Refresh sticky checkmark and enabled state
        if let stickyItem = menu.item(withTitle: "        Sticky") {
            let modifierKeysOnly = UserDefaults.standard.bool(forKey: "modifierKeysOnly")
            stickyItem.isEnabled = modifierKeysOnly
            stickyItem.state = UserDefaults.standard.bool(forKey: "sticky") ? .on : .off
        }
    }
}
