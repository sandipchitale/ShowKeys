import Cocoa

private func tapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passRetained(event) }
    let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
    monitor.handleCGEvent(type: type, event: event)
    return Unmanaged.passRetained(event)
}

class KeyboardMonitor {
    var onKeyEvent: ((String, CGEventFlags) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var previousFlags: CGEventFlags = []
    private var watchdog: Timer?

    // MARK: - Lifecycle

    func start() {
        guard AXIsProcessTrusted() else { return }
        
        stop()

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: tapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("ShowKeys: failed to create event tap")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        watchdog = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let tap = self?.eventTap, !CGEvent.tapIsEnabled(tap: tap) else { return }
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    func stop() {
        watchdog?.invalidate()
        watchdog = nil
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Event handling

    fileprivate func handleCGEvent(type: CGEventType, event: CGEvent) {
        let text: String
        let flags = event.flags
        switch type {
        case .keyDown:
            text = buildKeyDownText(event: event)
            guard !text.isEmpty else { return }
        case .flagsChanged:
            text = buildFlagsChangedText(event: event)
        default:
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.onKeyEvent?(text, flags)
        }
    }

    // MARK: - Key text builders

    private static let modifierKeysOnlyKey = "modifierKeysOnly"

    private func buildKeyDownText(event: CGEvent) -> String {
        let flags = event.flags
        let hasModifier = flags.contains(.maskControl)  ||
                          flags.contains(.maskAlternate) ||
                          flags.contains(.maskShift)    ||
                          flags.contains(.maskCommand)  ||
                          flags.contains(.maskSecondaryFn)

        if UserDefaults.standard.bool(forKey: Self.modifierKeysOnlyKey) && !hasModifier {
            return ""
        }

        var parts: [String] = []
        if flags.contains(.maskSecondaryFn){ parts.append("🌐") }
        if flags.contains(.maskControl)  { parts.append("⌃") }
        if flags.contains(.maskAlternate){ parts.append("⌥") }
        if flags.contains(.maskShift)    { parts.append("⇧") }
        if flags.contains(.maskCommand)  { parts.append("⌘") }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let keyName = keyCodeToName(keyCode)
        if !keyName.isEmpty { parts.append(keyName) }

        return parts.joined(separator: " ")
    }

    // Show active modifier keys when "modifierKeysOnly" is enabled,
    // or show newly-pressed modifier keys (ignoring releases) in default mode.
    private func buildFlagsChangedText(event: CGEvent) -> String {
        let current = event.flags
        let pressed = CGEventFlags(rawValue: current.rawValue & ~previousFlags.rawValue)
        previousFlags = current

        let modifierKeysOnly = UserDefaults.standard.bool(forKey: Self.modifierKeysOnlyKey)
        let flagsToUse = modifierKeysOnly ? current : pressed

        var parts: [String] = []
        if flagsToUse.contains(.maskSecondaryFn){ parts.append("🌐") }
        if flagsToUse.contains(.maskControl)  { parts.append("⌃") }
        if flagsToUse.contains(.maskAlternate){ parts.append("⌥") }
        if flagsToUse.contains(.maskShift)    { parts.append("⇧") }
        if flagsToUse.contains(.maskCommand)  { parts.append("⌘") }

        return parts.joined(separator: " ")
    }

    // MARK: - Key code table

    private func keyCodeToName(_ code: Int64) -> String {
        switch code {
        // Letters
        case 0:  return "A"
        case 1:  return "S"
        case 2:  return "D"
        case 3:  return "F"
        case 4:  return "H"
        case 5:  return "G"
        case 6:  return "Z"
        case 7:  return "X"
        case 8:  return "C"
        case 9:  return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        // Top-row numbers
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        // Punctuation
        case 33: return "["
        case 30: return "]"
        case 39: return "'"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 47: return "."
        case 50: return "`"
        // Special
        case 36: return "↩"      // Return
        case 48: return "⇥"      // Tab
        case 49: return "Space"
        case 51: return "⌫"      // Delete (backspace)
        case 52: return "↩"      // Numpad Enter
        case 53: return "⎋"      // Escape
        case 57: return "⇪"      // Caps Lock
        case 71: return "⌧"      // Clear
        case 114: return "⌦"     // Forward Delete
        case 115: return "↖"     // Home
        case 116: return "⇞"     // Page Up
        case 119: return "↘"     // End
        case 121: return "⇟"     // Page Down
        // Arrow keys
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        // Function keys
        case 122: return "F1"
        case 120: return "F2"
        case 99:  return "F3"
        case 118: return "F4"
        case 96:  return "F5"
        case 97:  return "F6"
        case 98:  return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 105: return "F13"
        case 107: return "F14"
        case 113: return "F15"
        case 106: return "F16"
        // Numpad
        case 65: return "Num."
        case 67: return "Num*"
        case 69: return "Num+"
        case 75: return "Num/"
        case 78: return "Num-"
        case 81: return "Num="
        case 82: return "Num0"
        case 83: return "Num1"
        case 84: return "Num2"
        case 85: return "Num3"
        case 86: return "Num4"
        case 87: return "Num5"
        case 88: return "Num6"
        case 89: return "Num7"
        case 91: return "Num8"
        case 92: return "Num9"
        default: return ""
        }
    }
}
