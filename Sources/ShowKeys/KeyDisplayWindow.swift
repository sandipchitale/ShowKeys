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
        return KeyConfig(isModifier: true, displayName: "fn", symbol: "🌐", width: 72)
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
        let isMouse = label.hasPrefix("Mouse\u{00A0}")
        let isTrackpad = label.hasPrefix("Trackpad\u{00A0}")
        
        let width: CGFloat
        if isMouse || isTrackpad {
            width = 72
        } else {
            let fontSize: CGFloat = label.count > 1 ? 12 : 18
            let fontWeight: NSFont.Weight = label.count > 1 ? .medium : .bold
            let font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
            let size = (label as NSString).size(withAttributes: [.font: font])
            width = max(72, size.width + 24)
        }
        return KeyConfig(isModifier: false, displayName: label, symbol: nil, width: width)
    }
}

// MARK: - 3D Keycap View

// MARK: - Color Tinting Helpers

extension NSColor {
    var isDark: Bool {
        guard let rgbColor = self.usingColorSpace(.sRGB) else { return true }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.5
    }
    
    func darkened(by factor: CGFloat) -> NSColor {
        guard let rgbColor = self.usingColorSpace(.sRGB) else { return self }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return NSColor(red: max(r * factor, 0),
                       green: max(g * factor, 0),
                       blue: max(b * factor, 0),
                       alpha: a)
    }

    func toHex() -> String {
        guard let rgbColor = self.usingColorSpace(.sRGB) else { return "" }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    
    static func fromHex(_ hex: String) -> NSColor? {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.remove(at: cleanHex.startIndex)
        }
        guard cleanHex.count == 6 else { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

func colorKey(for displayName: String) -> String {
    switch displayName.lowercased() {
    case "control": return "color_control"
    case "fn": return "color_fn"
    case "option": return "color_option"
    case "shift": return "color_shift"
    case "command": return "color_command"
    default: return "color_other"
    }
}

// MARK: - Mouse Graphic View

private final class MouseGraphicView: NSView {
    private let clickedButton: String
    private let color: NSColor
    
    init(clickedButton: String, color: NSColor) {
        self.clickedButton = clickedButton
        self.color = color
        super.init(frame: NSRect(x: 0, y: 0, width: 32, height: 32))
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let strokeColor = color
        let fillColor = color.withAlphaComponent(0.85)
        
        // Mouse body bounds: 20x28, centered in 32x32 -> x: 6, y: 2
        let mouseRect = NSRect(x: 6, y: 2, width: 20, height: 28)
        let path = NSBezierPath(roundedRect: mouseRect, xRadius: 10, yRadius: 10)
        
        strokeColor.setStroke()
        path.lineWidth = 1.5
        path.stroke()
        
        // Draw division lines:
        // Horizontal line separating top buttons from body (y = 16)
        let hLine = NSBezierPath()
        hLine.move(to: NSPoint(x: 6, y: 16))
        hLine.line(to: NSPoint(x: 26, y: 16))
        hLine.lineWidth = 1.0
        hLine.stroke()
        
        // Vertical line separating left and right buttons (x = 16, y from 16 to 30)
        let vLine = NSBezierPath()
        vLine.move(to: NSPoint(x: 16, y: 16))
        vLine.line(to: NSPoint(x: 16, y: 30))
        vLine.lineWidth = 1.0
        vLine.stroke()
        
        // Scroll wheel (middle button) pill: centered at x = 16, y = 20-25
        let wheelRect = NSRect(x: 14.5, y: 20, width: 3, height: 6)
        let wheelPath = NSBezierPath(roundedRect: wheelRect, xRadius: 1.5, yRadius: 1.5)
        
        // Fill the clicked button:
        if clickedButton == "Left" {
            let leftButtonPath = NSBezierPath()
            leftButtonPath.move(to: NSPoint(x: 16, y: 16))
            leftButtonPath.line(to: NSPoint(x: 6, y: 16))
            leftButtonPath.appendArc(withCenter: NSPoint(x: 16, y: 20), radius: 10, startAngle: 180, endAngle: 90, clockwise: true)
            leftButtonPath.line(to: NSPoint(x: 16, y: 16))
            fillColor.setFill()
            leftButtonPath.fill()
        } else if clickedButton == "Right" {
            let rightButtonPath = NSBezierPath()
            rightButtonPath.move(to: NSPoint(x: 16, y: 16))
            rightButtonPath.line(to: NSPoint(x: 26, y: 16))
            rightButtonPath.appendArc(withCenter: NSPoint(x: 16, y: 20), radius: 10, startAngle: 0, endAngle: 90, clockwise: false)
            rightButtonPath.line(to: NSPoint(x: 16, y: 16))
            fillColor.setFill()
            rightButtonPath.fill()
        } else if clickedButton == "Middle" {
            fillColor.setFill()
            wheelPath.fill()
        }
        
        // Draw wheel border:
        strokeColor.setStroke()
        wheelPath.lineWidth = 1.0
        wheelPath.stroke()
    }
}

// MARK: - Trackpad Graphic View

private final class TrackpadGraphicView: NSView {
    private let clickedButton: String
    private let color: NSColor
    
    init(clickedButton: String, color: NSColor) {
        self.clickedButton = clickedButton
        self.color = color
        super.init(frame: NSRect(x: 0, y: 0, width: 44, height: 32))
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let strokeColor = color
        let fillColor = color.withAlphaComponent(0.85)
        
        // Trackpad outline: centered in 44x32 -> x: 4, y: 4, w: 36, h: 24
        let trackpadRect = NSRect(x: 4, y: 4, width: 36, height: 24)
        let path = NSBezierPath(roundedRect: trackpadRect, xRadius: 4, yRadius: 4)
        
        strokeColor.setStroke()
        path.lineWidth = 1.5
        path.stroke()
        
        // Touch point
        let touchCenter: NSPoint
        switch clickedButton {
        case "Left":
            touchCenter = NSPoint(x: 12, y: 10)
        case "Right":
            touchCenter = NSPoint(x: 32, y: 10)
        default:
            touchCenter = NSPoint(x: 22, y: 16)
        }
        
        let touchRadius: CGFloat = 4
        let touchPath = NSBezierPath(ovalIn: NSRect(x: touchCenter.x - touchRadius,
                                                    y: touchCenter.y - touchRadius,
                                                    width: touchRadius * 2,
                                                    height: touchRadius * 2))
        
        fillColor.setFill()
        touchPath.fill()
        
        strokeColor.setStroke()
        touchPath.lineWidth = 1.0
        touchPath.stroke()
    }
}

// MARK: - 3D Keycap View

private final class KeycapView: NSView {
    private var config: KeyConfig
    private var nameLabel: NSTextField?
    private var symbolLabel: NSTextField?
    private var graphicView: NSView?
    
    private let bottomLayer = CALayer()
    private let topLayer = CALayer()

    init(config: KeyConfig) {
        self.config = config
        super.init(frame: .zero)
        
        let keyH: CGFloat = 48
        let w = config.width
        self.frame = NSRect(x: 0, y: 0, width: w, height: keyH)
        
        wantsLayer = true
        
        bottomLayer.frame = CGRect(x: 0, y: 0, width: w, height: 45)
        bottomLayer.cornerRadius = 6
        
        topLayer.frame = CGRect(x: 0, y: 3, width: w, height: 45)
        topLayer.cornerRadius = 6
        
        layer?.addSublayer(bottomLayer)
        layer?.addSublayer(topLayer)
        
        let isMouse = config.displayName.hasPrefix("Mouse\u{00A0}")
        let isTrackpad = config.displayName.hasPrefix("Trackpad\u{00A0}")
        
        if isMouse || isTrackpad {
            // Graphic will be dynamically added/updated in updateColors()
        } else if config.isModifier {
            if let symbol = config.symbol {
                let symbolLabel = NSTextField(labelWithString: symbol)
                symbolLabel.font = NSFont.systemFont(ofSize: 15, weight: .regular)
                symbolLabel.drawsBackground = false
                symbolLabel.isBezeled = false
                symbolLabel.alignment = .right
                if symbol == "🌐" {
                    symbolLabel.frame = NSRect(x: w - 28, y: 26, width: 22, height: 18)
                } else {
                    symbolLabel.frame = NSRect(x: w - 24, y: 26, width: 18, height: 18)
                }
                addSubview(symbolLabel)
                self.symbolLabel = symbolLabel
            }
            
            let nameLabel = NSTextField(labelWithString: config.displayName)
            nameLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
            nameLabel.drawsBackground = false
            nameLabel.isBezeled = false
            nameLabel.alignment = .left
            nameLabel.frame = NSRect(x: 6, y: 7, width: w - 12, height: 14)
            addSubview(nameLabel)
            self.nameLabel = nameLabel
        } else {
            let nameLabel = NSTextField(labelWithString: config.displayName)
            let fontSize: CGFloat = config.displayName.count > 1 ? 12 : 18
            let fontWeight: NSFont.Weight = config.displayName.count > 1 ? .medium : .bold
            nameLabel.font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
            nameLabel.drawsBackground = false
            nameLabel.isBezeled = false
            nameLabel.alignment = .center
            
            let size = (config.displayName as NSString).size(withAttributes: [.font: nameLabel.font!])
            let labelY = (45 - size.height) / 2 + 3
            nameLabel.frame = NSRect(x: 0, y: labelY - 0.5, width: w, height: size.height)
            addSubview(nameLabel)
            self.nameLabel = nameLabel
        }
        
        updateColors()
        
        NotificationCenter.default.addObserver(self, selector: #selector(colorChanged), name: Notification.Name("KeycapColorChanged"), object: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func colorChanged() {
        updateColors()
    }
    
    private func updateColors() {
        var customColor: NSColor? = nil
        let defaultsKey = colorKey(for: config.displayName)
        if let hex = UserDefaults.standard.string(forKey: defaultsKey),
           let color = NSColor.fromHex(hex) {
            customColor = color
        }
        
        let faceColor: CGColor
        let edgeColor: CGColor
        let labelColor: NSColor
        
        if let color = customColor {
            let isDark = color.isDark
            faceColor = color.cgColor
            edgeColor = color.darkened(by: 0.65).cgColor
            labelColor = isDark ? NSColor(calibratedWhite: 0.9, alpha: 1.0) : NSColor(calibratedWhite: 0.15, alpha: 1.0)
            
            topLayer.borderWidth = 0.5
            topLayer.borderColor = isDark ? NSColor(calibratedWhite: 0.25, alpha: 1.0).cgColor : NSColor(calibratedWhite: 1.0, alpha: 0.5).cgColor
        } else {
            if config.isModifier {
                faceColor = NSColor(calibratedWhite: 0.18, alpha: 1.0).cgColor
                edgeColor = NSColor(calibratedWhite: 0.08, alpha: 1.0).cgColor
                labelColor = NSColor(calibratedWhite: 0.85, alpha: 1.0)
                
                topLayer.borderWidth = 0.5
                topLayer.borderColor = NSColor(calibratedWhite: 0.25, alpha: 1.0).cgColor
            } else {
                faceColor = NSColor(calibratedWhite: 0.94, alpha: 1.0).cgColor
                edgeColor = NSColor(calibratedWhite: 0.65, alpha: 1.0).cgColor
                labelColor = NSColor(calibratedWhite: 0.15, alpha: 1.0)
                
                topLayer.borderWidth = 0.5
                topLayer.borderColor = NSColor(calibratedWhite: 1.0, alpha: 1.0).cgColor
            }
        }
        
        bottomLayer.backgroundColor = edgeColor
        topLayer.backgroundColor = faceColor
        
        nameLabel?.textColor = labelColor
        symbolLabel?.textColor = labelColor
        
        // Render graphics if mouse or trackpad
        let isMouse = config.displayName.hasPrefix("Mouse\u{00A0}")
        let isTrackpad = config.displayName.hasPrefix("Trackpad\u{00A0}")
        
        if isMouse || isTrackpad {
            graphicView?.removeFromSuperview()
            
            let clickedButton = config.displayName.components(separatedBy: "\u{00A0}").last ?? "Left"
            let w = config.width
            
            if isMouse {
                let mouseView = MouseGraphicView(clickedButton: clickedButton, color: labelColor)
                mouseView.frame.origin = NSPoint(x: (w - 32) / 2, y: (45 - 32) / 2 + 3)
                addSubview(mouseView)
                graphicView = mouseView
            } else {
                let trackpadView = TrackpadGraphicView(clickedButton: clickedButton, color: labelColor)
                trackpadView.frame.origin = NSPoint(x: (w - 44) / 2, y: (45 - 32) / 2 + 3)
                addSubview(trackpadView)
                graphicView = trackpadView
            }
        } else {
            graphicView?.removeFromSuperview()
            graphicView = nil
        }
    }

    func updateText(_ text: String) {
        config = KeyConfig(isModifier: config.isModifier, displayName: text, symbol: config.symbol, width: config.width)
        
        let isMouse = text.hasPrefix("Mouse\u{00A0}")
        let isTrackpad = text.hasPrefix("Trackpad\u{00A0}")
        
        if isMouse || isTrackpad {
            nameLabel?.isHidden = true
        } else {
            if nameLabel == nil {
                let nameLabel = NSTextField(labelWithString: text)
                nameLabel.drawsBackground = false
                nameLabel.isBezeled = false
                nameLabel.alignment = .center
                addSubview(nameLabel)
                self.nameLabel = nameLabel
            }
            nameLabel?.isHidden = false
            
            if let nameLabel = nameLabel {
                nameLabel.stringValue = text
                let fontSize: CGFloat = text.count > 1 ? 12 : 18
                let fontWeight: NSFont.Weight = text.count > 1 ? .medium : .bold
                nameLabel.font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
                
                let size = (text as NSString).size(withAttributes: [.font: nameLabel.font!])
                let labelY = (45 - size.height) / 2 + 3
                nameLabel.frame = NSRect(x: 0, y: labelY - 0.5, width: bounds.width, height: size.height)
            }
        }
        
        updateColors()
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

        let totalW: CGFloat = 4 * 72 + 3 * keyGap + hPad * 2 // 332
        let totalH: CGFloat = 2 * keyH + keyGap + vPad * 2 // 120

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

        // Bottom row: control, globe, option, command
        controlKey.frame.origin = NSPoint(x: hPad, y: vPad)
        globeKey.frame.origin = NSPoint(x: hPad + 72 + keyGap, y: vPad)
        optionKey.frame.origin = NSPoint(x: hPad + 2 * (72 + keyGap), y: vPad)
        commandKey.frame.origin = NSPoint(x: hPad + 3 * (72 + keyGap), y: vPad)

        // Top row: shift, regular key slot
        shiftKey.frame.origin = NSPoint(x: hPad, y: vPad + keyH + keyGap)
        regularKeySlot.frame.origin = NSPoint(x: hPad + 3 * (72 + keyGap), y: vPad + keyH + keyGap)

        let keys = [controlKey, globeKey, optionKey, commandKey, shiftKey, regularKeySlot]
        for keycap in keys {
            keycap.alphaValue = 0.2
            addSubview(keycap)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateState(flags: CGEventFlags, regularKeyText: String?) {
        let isFunctionKey = regularKeyText?.hasPrefix("F") == true &&
                            regularKeyText?.count ?? 0 > 1 &&
                            regularKeyText?.dropFirst().allSatisfy({ $0.isNumber }) == true

        globeKey.alphaValue = (flags.contains(.maskSecondaryFn) && !isFunctionKey) ? 1.0 : 0.2
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
                    if !hasModifiers && !UserDefaults.standard.bool(forKey: "sticky") {
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

            if !hasModifiers && !UserDefaults.standard.bool(forKey: "sticky") {
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
