import Cocoa

// MARK: - Key Configurations

private struct KeyConfig {
    let isModifier: Bool
    let displayName: String
    let symbol: String?
    let width: CGFloat
}

private func parseKey(_ rawKey: String) -> KeyConfig {
    switch rawKey {
    case "⌃":
        return KeyConfig(isModifier: true, displayName: "control", symbol: "⌃", width: 72)
    case "⌥":
        return KeyConfig(isModifier: true, displayName: "option", symbol: "⌥", width: 72)
    case "⇧":
        return KeyConfig(isModifier: true, displayName: "shift", symbol: "⇧", width: 72)
    case "⌘":
        return KeyConfig(isModifier: true, displayName: "command", symbol: "⌘", width: 72)
    case "🌐":
        return KeyConfig(isModifier: true, displayName: "globe", symbol: "🌐", width: 72)
    case "Space":
        return KeyConfig(isModifier: false, displayName: "␣", symbol: nil, width: 72)
    case "Escape", "⎋":
        return KeyConfig(isModifier: false, displayName: "⎋", symbol: nil, width: 72)
    case "↩":
        return KeyConfig(isModifier: false, displayName: "↩", symbol: nil, width: 72)
    case "⇥":
        return KeyConfig(isModifier: false, displayName: "⇥", symbol: nil, width: 72)
    case "⌫":
        return KeyConfig(isModifier: false, displayName: "⌫", symbol: nil, width: 72)
    case "⇪":
        return KeyConfig(isModifier: false, displayName: "⇪", symbol: nil, width: 72)
    default:
        let label = rawKey
        return KeyConfig(isModifier: false, displayName: label, symbol: nil, width: 72)
    }
}

// MARK: - 3D Keycap View

private final class KeycapView: NSView {
    private var nameLabel: NSTextField?

    init(config: KeyConfig) {
        let keyH: CGFloat = 48
        let w = config.width
        super.init(frame: NSRect(x: 0, y: 0, width: w, height: keyH))
        
        wantsLayer = true
        
        // 1. Bottom shadow/3D edge layer
        let bottomLayer = CALayer()
        bottomLayer.frame = CGRect(x: 0, y: 0, width: w, height: 45)
        bottomLayer.cornerRadius = 6
        
        // 2. Top face layer
        let topLayer = CALayer()
        topLayer.frame = CGRect(x: 0, y: 3, width: w, height: 45)
        topLayer.cornerRadius = 6
        
        if config.isModifier {
            // Dark keycap (modifier keys)
            bottomLayer.backgroundColor = NSColor(calibratedWhite: 0.08, alpha: 1.0).cgColor
            topLayer.backgroundColor = NSColor(calibratedWhite: 0.18, alpha: 1.0).cgColor
            
            topLayer.borderWidth = 0.5
            topLayer.borderColor = NSColor(calibratedWhite: 0.25, alpha: 1.0).cgColor
            
            layer?.addSublayer(bottomLayer)
            layer?.addSublayer(topLayer)
            
            // Symbol in top-right
            if let symbol = config.symbol {
                let symbolLabel = NSTextField(labelWithString: symbol)
                symbolLabel.font = NSFont.systemFont(ofSize: 15, weight: .regular)
                symbolLabel.textColor = NSColor(calibratedWhite: 0.9, alpha: 1.0)
                symbolLabel.drawsBackground = false
                symbolLabel.isBezeled = false
                symbolLabel.alignment = .right
                symbolLabel.frame = NSRect(x: w - 24, y: 26, width: 18, height: 18)
                addSubview(symbolLabel)
            }
            
            // Display name in bottom-left
            let nameLabel = NSTextField(labelWithString: config.displayName)
            nameLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
            nameLabel.textColor = NSColor(calibratedWhite: 0.8, alpha: 1.0)
            nameLabel.drawsBackground = false
            nameLabel.isBezeled = false
            nameLabel.alignment = .left
            nameLabel.frame = NSRect(x: 6, y: 7, width: w - 12, height: 14)
            addSubview(nameLabel)
            
        } else {
            // Light keycap (regular keys)
            bottomLayer.backgroundColor = NSColor(calibratedWhite: 0.65, alpha: 1.0).cgColor
            topLayer.backgroundColor = NSColor(calibratedWhite: 0.94, alpha: 1.0).cgColor
            
            topLayer.borderWidth = 0.5
            topLayer.borderColor = NSColor(calibratedWhite: 1.0, alpha: 1.0).cgColor
            
            layer?.addSublayer(bottomLayer)
            layer?.addSublayer(topLayer)
            
            // Centered label
            let nameLabel = NSTextField(labelWithString: config.displayName)
            let fontSize: CGFloat = config.displayName.count > 1 ? 12 : 18
            let fontWeight: NSFont.Weight = config.displayName.count > 1 ? .medium : .bold
            nameLabel.font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
            nameLabel.textColor = NSColor(calibratedWhite: 0.15, alpha: 1.0)
            nameLabel.drawsBackground = false
            nameLabel.isBezeled = false
            nameLabel.alignment = .center
            
            let size = (config.displayName as NSString).size(withAttributes: [.font: nameLabel.font!])
            let labelY = (45 - size.height) / 2 + 3
            nameLabel.frame = NSRect(x: 0, y: labelY - 0.5, width: w, height: size.height)
            addSubview(nameLabel)
            self.nameLabel = nameLabel
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }

    func updateText(_ text: String) {
        guard let nameLabel = nameLabel else { return }
        nameLabel.stringValue = text
        
        let fontSize: CGFloat = text.count > 1 ? 12 : 18
        let fontWeight: NSFont.Weight = text.count > 1 ? .medium : .bold
        nameLabel.font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
        
        let size = (text as NSString).size(withAttributes: [.font: nameLabel.font!])
        let labelY = (45 - size.height) / 2 + 3
        nameLabel.frame = NSRect(x: 0, y: labelY - 0.5, width: bounds.width, height: size.height)
    }
}

// MARK: - Pill View (Enclosing Container)

private final class KeystrokePill: NSView {
    init(text: String) {
        let keys = text.components(separatedBy: " ").filter { !$0.isEmpty }
        let configs = keys.map { parseKey($0) }
        
        let keyGap: CGFloat = 8
        let hPad: CGFloat = 10
        let vPad: CGFloat = 8
        let keyH: CGFloat = 48
        
        // Calculate total width
        let totalKeysWidth = configs.reduce(0) { $0 + $1.width }
        let totalGaps = CGFloat(max(0, configs.count - 1)) * keyGap
        let containerW = totalKeysWidth + totalGaps + hPad * 2
        let containerH = keyH + vPad * 2
        
        super.init(frame: NSRect(x: 0, y: 0, width: containerW, height: containerH))
        
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 0.45).cgColor
        layer?.borderColor = NSColor(calibratedWhite: 0.25, alpha: 0.35).cgColor
        layer?.borderWidth = 1.0
        
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.35
        layer?.shadowRadius = 8
        layer?.shadowOffset = CGSize(width: 0, height: -3)
        
        // Add visual effect view for glassmorphic backdrop
        let effectView = NSVisualEffectView(frame: bounds)
        effectView.material = .hudWindow
        effectView.blendingMode = .withinWindow
        effectView.state = .active
        effectView.autoresizingMask = [.width, .height]
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 14
        addSubview(effectView)
        
        // Add keys side-by-side
        var currentX = hPad
        for config in configs {
            let keycap = KeycapView(config: config)
            keycap.frame.origin = NSPoint(x: currentX, y: vPad)
            addSubview(keycap)
            currentX += config.width + keyGap
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Modifier HUD View

private final class ModifierHUDView: NSView {
    private let globeKey: KeycapView
    private let controlKey: KeycapView
    private let optionKey: KeycapView
    private let shiftKey: KeycapView
    private let commandKey: KeycapView
    private let regularKeySlot: KeycapView

    private let keyGap: CGFloat = 8
    private let hPad: CGFloat = 10
    private let vPad: CGFloat = 8
    private let keyH: CGFloat = 48
    private let effectView: NSVisualEffectView

    init() {
        globeKey = KeycapView(config: parseKey("🌐"))
        controlKey = KeycapView(config: parseKey("⌃"))
        optionKey = KeycapView(config: parseKey("⌥"))
        shiftKey = KeycapView(config: parseKey("⇧"))
        commandKey = KeycapView(config: parseKey("⌘"))
        
        let regularConfig = KeyConfig(isModifier: false, displayName: "", symbol: nil, width: 72)
        regularKeySlot = KeycapView(config: regularConfig)

        let totalW: CGFloat = 6 * 72 + 5 * keyGap + hPad * 2 // 492
        let totalH: CGFloat = keyH + vPad * 2 // 64

        effectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: totalW, height: totalH))

        super.init(frame: NSRect(x: 0, y: 0, width: totalW, height: totalH))

        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 0.45).cgColor
        layer?.borderColor = NSColor(calibratedWhite: 0.25, alpha: 0.35).cgColor
        layer?.borderWidth = 1.0

        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.35
        layer?.shadowRadius = 8
        layer?.shadowOffset = CGSize(width: 0, height: -3)

        effectView.material = .hudWindow
        effectView.blendingMode = .withinWindow
        effectView.state = .active
        effectView.autoresizingMask = [.width, .height]
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 14
        addSubview(effectView)

        let keys = [globeKey, controlKey, optionKey, shiftKey, commandKey, regularKeySlot]
        var currentX = hPad
        for keycap in keys {
            keycap.frame.origin = NSPoint(x: currentX, y: vPad)
            keycap.alphaValue = 0.2
            addSubview(keycap)
            currentX += 72 + keyGap
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateState(flags: CGEventFlags, regularKeyText: String?) {
        globeKey.alphaValue = flags.contains(.maskSecondaryFn) ? 1.0 : 0.2
        controlKey.alphaValue = flags.contains(.maskControl) ? 1.0 : 0.2
        optionKey.alphaValue = flags.contains(.maskAlternate) ? 1.0 : 0.2
        shiftKey.alphaValue = flags.contains(.maskShift) ? 1.0 : 0.2
        commandKey.alphaValue = flags.contains(.maskCommand) ? 1.0 : 0.2

        if let regularKeyText = regularKeyText, !regularKeyText.isEmpty {
            regularKeySlot.updateText(regularKeyText)
            regularKeySlot.alphaValue = 1.0
        } else {
            regularKeySlot.updateText("")
            regularKeySlot.alphaValue = 0.2
        }
    }
}

// MARK: - Display window

final class KeyDisplayWindow: NSWindow {
    private static let windowW: CGFloat = 550
    private static let windowH: CGFloat = 380
    private static let margin: CGFloat  = 20
    private static let pillGap: CGFloat =  8
    private static let maxPills         =  5
    private static let displayDuration  = 2.2

    private var pills: [NSView] = []
    private var activeHUDView: ModifierHUDView?
    private var activeModifierTimer: Timer?

    var cornerPosition: CornerPosition {
        get {
            let raw = UserDefaults.standard.string(forKey: "cornerPosition")
            return raw.flatMap(CornerPosition.init) ?? .bottomRight
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "cornerPosition")
            repositionWindow()
        }
    }

    // MARK: - Init

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0,
                                width: Self.windowW, height: Self.windowH),
            styleMask: [.borderless],
            backing:   .buffered,
            defer:     false
        )
        isOpaque            = false
        backgroundColor     = .clear
        level               = .screenSaver
        ignoresMouseEvents  = true
        isMovable           = false
        isReleasedWhenClosed = false
        collectionBehavior  = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        hasShadow           = false
        contentView?.wantsLayer = true
        repositionWindow()
        orderFrontRegardless()
    }

    // MARK: - Public

    func clearKeystrokes() {
        activeModifierTimer?.invalidate()
        activeModifierTimer = nil
        activeHUDView?.removeFromSuperview()
        activeHUDView = nil
        for pill in pills {
            pill.removeFromSuperview()
        }
        pills.removeAll()
    }

    func showKeystroke(_ text: String, flags: CGEventFlags = []) {
        let modifierKeysOnly = UserDefaults.standard.bool(forKey: "modifierKeysOnly")

        if modifierKeysOnly {
            // Cancel any pending fade-out timer for the active HUD
            activeModifierTimer?.invalidate()
            activeModifierTimer = nil

            // Extract regular key name from text (if any)
            let parts = text.components(separatedBy: " ").filter { !$0.isEmpty }
            let modifiersList = ["🌐", "⌃", "⌥", "⇧", "⌘"]
            let regularKeys = parts.filter { !modifiersList.contains($0) }
            let regularKeyText = regularKeys.first

            let hasModifiers = flags.contains(.maskControl) ||
                               flags.contains(.maskAlternate) ||
                               flags.contains(.maskShift) ||
                               flags.contains(.maskCommand) ||
                               flags.contains(.maskSecondaryFn)

            if text.isEmpty {
                if let hud = activeHUDView {
                    hud.updateState(flags: flags, regularKeyText: nil)
                    layoutPills(animated: true)
                    if !hasModifiers {
                        startFadeOutTimer(for: hud)
                    }
                }
                return
            }

            let isNew = (activeHUDView == nil)
            let hud: ModifierHUDView
            if let existingHUD = activeHUDView {
                hud = existingHUD
                if hud.alphaValue < 1.0 {
                    hud.alphaValue = 1.0
                }
            } else {
                clearKeystrokes()
                hud = ModifierHUDView()
                hud.alphaValue = 0
                contentView?.addSubview(hud)
                pills.append(hud)
                activeHUDView = hud
            }

            hud.updateState(flags: flags, regularKeyText: regularKeyText)
            layoutPills(animated: !isNew)

            if hud.alphaValue == 0 {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.12
                    hud.animator().alphaValue = 1.0
                }
            }

            if !hasModifiers {
                startFadeOutTimer(for: hud)
            }
        } else {
            // Default stacking/fading behavior
            guard !text.isEmpty else { return }

            // Evict oldest pill if at capacity
            if pills.count >= Self.maxPills {
                let evicted = pills.removeFirst()
                evicted.removeFromSuperview()
            }

            let pill = KeystrokePill(text: text)
            pill.alphaValue = 0
            contentView?.addSubview(pill)
            pills.append(pill)

            layoutPills(animated: false)

            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.12
                pill.animator().alphaValue = 1.0
            }

            let displayTime = Self.displayDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + displayTime) { [weak self, weak pill] in
                guard let self, let pill, self.pills.contains(where: { $0 === pill }) else { return }
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.45
                    pill.animator().alphaValue = 0
                }) { [weak self, weak pill] in
                    guard let self, let pill else { return }
                    self.pills.removeAll { $0 === pill }
                    pill.removeFromSuperview()
                    self.layoutPills(animated: true)
                }
            }
        }
    }

    private func startFadeOutTimer(for pill: NSView) {
        let displayTime = Self.displayDuration
        activeModifierTimer = Timer.scheduledTimer(withTimeInterval: displayTime, repeats: false) { [weak self, weak pill] _ in
            guard let self, let pill, self.pills.contains(where: { $0 === pill }) else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.45
                pill.animator().alphaValue = 0
            }) { [weak self, weak pill] in
                guard let self, let pill else { return }
                self.pills.removeAll { $0 === pill }
                pill.removeFromSuperview()
                self.layoutPills(animated: true)
                if self.activeHUDView === pill {
                    self.activeHUDView = nil
                }
            }
        }
    }

    func repositionWindow() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let sf = screen.visibleFrame
        let m  = Self.margin
        let w  = Self.windowW
        let h  = Self.windowH

        let origin: NSPoint
        switch cornerPosition {
        case .topLeft:     origin = NSPoint(x: sf.minX + m, y: sf.maxY - h - m)
        case .topRight:    origin = NSPoint(x: sf.maxX - w - m, y: sf.maxY - h - m)
        case .bottomLeft:  origin = NSPoint(x: sf.minX + m, y: sf.minY + m)
        case .bottomRight: origin = NSPoint(x: sf.maxX - w - m, y: sf.minY + m)
        }
        setFrameOrigin(origin)
    }

    // MARK: - Layout

    private func layoutPills(animated: Bool) {
        let gap = Self.pillGap
        let m: CGFloat = 6

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = animated ? 0.18 : 0
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)

            if cornerPosition.isTop {
                // Stack downward from top edge
                var y = Self.windowH - m
                for pill in pills {
                    y -= pill.frame.height
                    let x = xOrigin(for: pill)
                    pill.animator().setFrameOrigin(NSPoint(x: x, y: y))
                    y -= gap
                }
            } else {
                // Stack upward from bottom edge
                var y = m
                for pill in pills.reversed() {
                    let x = xOrigin(for: pill)
                    pill.animator().setFrameOrigin(NSPoint(x: x, y: y))
                    y += pill.frame.height + gap
                }
            }
        }
    }

    private func xOrigin(for pill: NSView) -> CGFloat {
        let m: CGFloat = 10
        if cornerPosition.isRight {
            return Self.windowW - pill.frame.width - m
        } else {
            return m
        }
    }
}
