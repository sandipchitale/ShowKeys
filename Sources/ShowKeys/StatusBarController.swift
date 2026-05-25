import Cocoa

class ColorMenuInfo: NSObject {
    let keyDisplayName: String
    let hexValue: String?
    let isCustom: Bool
    
    init(keyDisplayName: String, hexValue: String?, isCustom: Bool = false) {
        self.keyDisplayName = keyDisplayName
        self.hexValue = hexValue
        self.isCustom = isCustom
    }
}

final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private weak var displayWindow: KeyDisplayWindow?
    private var activeCustomColorKey: String? = nil

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

        // Colors sub-menu
        let colorsItem = NSMenuItem(title: "Colors", action: nil, keyEquivalent: "")
        let colorsMenu = NSMenu()
        
        let keysToConfigure = [
            ("Shift Key", "shift"),
            ("Control Key", "control"),
            ("Fn (Globe) Key", "fn"),
            ("Option Key", "option"),
            ("Command Key", "command"),
            ("Other Keys", "other")
        ]
        
        for (label, keyName) in keysToConfigure {
            let keyItem = NSMenuItem(title: label, action: nil, keyEquivalent: "")
            let keySubmenu = NSMenu()
            
            let colorChoices = [
                ("Default", nil),
                ("Red", "#FF3B30"),
                ("Green", "#34C759"),
                ("Blue", "#007AFF"),
                ("Yellow", "#FFCC00"),
                ("Orange", "#FF9500"),
                ("Purple", "#AF52DE")
            ]
            
            for (colorLabel, hex) in colorChoices {
                let item = NSMenuItem(
                    title: colorLabel,
                    action: #selector(selectColor(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = ColorMenuInfo(keyDisplayName: keyName, hexValue: hex)
                keySubmenu.addItem(item)
            }
            
            keySubmenu.addItem(.separator())
            
            let customItem = NSMenuItem(
                title: "Custom...",
                action: #selector(selectCustomColor(_:)),
                keyEquivalent: ""
            )
            customItem.target = self
            customItem.representedObject = ColorMenuInfo(keyDisplayName: keyName, hexValue: nil, isCustom: true)
            keySubmenu.addItem(customItem)
            
            keyItem.submenu = keySubmenu
            colorsMenu.addItem(keyItem)
        }
        
        colorsMenu.addItem(.separator())
        
        let resetAllItem = NSMenuItem(
            title: "Default All",
            action: #selector(resetAllColors(_:)),
            keyEquivalent: ""
        )
        resetAllItem.target = self
        colorsMenu.addItem(resetAllItem)
        
        colorsItem.submenu = colorsMenu
        menu.addItem(colorsItem)

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

        let mouseClicksItem = NSMenuItem(
            title: "Show Mouse Clicks",
            action: #selector(toggleShowMouseClicks(_:)),
            keyEquivalent: ""
        )
        mouseClicksItem.target = self
        menu.addItem(mouseClicksItem)

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

    @objc private func toggleShowMouseClicks(_ sender: NSMenuItem) {
        let new = !UserDefaults.standard.bool(forKey: "showMouseClicks")
        UserDefaults.standard.set(new, forKey: "showMouseClicks")
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

    @objc private func selectColor(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? ColorMenuInfo else { return }
        let defaultsKey = colorKey(for: info.keyDisplayName)
        if let hex = info.hexValue {
            UserDefaults.standard.set(hex, forKey: defaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        }
        NotificationCenter.default.post(name: Notification.Name("KeycapColorChanged"), object: nil)
    }

    @objc private func selectCustomColor(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? ColorMenuInfo else { return }
        activeCustomColorKey = colorKey(for: info.keyDisplayName)
        
        let colorPanel = NSColorPanel.shared
        colorPanel.setTarget(self)
        colorPanel.setAction(#selector(colorPanelChanged(_:)))
        
        let currentHex = UserDefaults.standard.string(forKey: activeCustomColorKey!)
        if let hex = currentHex, let currentColor = NSColor.fromHex(hex) {
            colorPanel.color = currentColor
        } else {
            colorPanel.color = .white
        }
        
        colorPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func colorPanelChanged(_ sender: NSColorPanel) {
        guard let defaultsKey = activeCustomColorKey else { return }
        let selectedColor = sender.color
        let hex = selectedColor.toHex()
        UserDefaults.standard.set(hex, forKey: defaultsKey)
        NotificationCenter.default.post(name: Notification.Name("KeycapColorChanged"), object: nil)
    }

    @objc private func resetAllColors(_ sender: NSMenuItem) {
        let keys = ["color_control", "color_fn", "color_option", "color_shift", "color_command", "color_other"]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        NotificationCenter.default.post(name: Notification.Name("KeycapColorChanged"), object: nil)
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

        // Refresh show mouse clicks checkmark
        if let mouseClicksItem = menu.item(withTitle: "Show Mouse Clicks") {
            mouseClicksItem.state = UserDefaults.standard.bool(forKey: "showMouseClicks") ? .on : .off
        }

        // Refresh colors checkmarks
        if let colorsMenu = menu.item(withTitle: "Colors")?.submenu {
            for keyItem in colorsMenu.items {
                guard let keySubmenu = keyItem.submenu,
                      let firstItem = keySubmenu.items.first,
                      let info = firstItem.representedObject as? ColorMenuInfo else { continue }
                
                let defaultsKey = colorKey(for: info.keyDisplayName)
                let currentHex = UserDefaults.standard.string(forKey: defaultsKey)
                
                for item in keySubmenu.items {
                    if item.isSeparatorItem { continue }
                    guard let itemInfo = item.representedObject as? ColorMenuInfo else { continue }
                    
                    if itemInfo.isCustom {
                        let hasCustom = currentHex != nil && !["#FF3B30", "#34C759", "#007AFF", "#FFCC00", "#FF9500", "#AF52DE"].contains(currentHex!)
                        item.state = hasCustom ? .on : .off
                    } else {
                        let selected = (currentHex == itemInfo.hexValue)
                        item.state = selected ? .on : .off
                    }
                }
            }
        }
    }
}
