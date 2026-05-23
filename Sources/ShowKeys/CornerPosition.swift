import Foundation

enum CornerPosition: String, CaseIterable {
    case topLeft     = "Top Left"
    case topRight    = "Top Right"
    case bottomLeft  = "Bottom Left"
    case bottomRight = "Bottom Right"

    var symbol: String {
        switch self {
        case .topLeft:     return "↖"
        case .topRight:    return "↗"
        case .bottomLeft:  return "↙"
        case .bottomRight: return "↘"
        }
    }

    var isTop: Bool    { self == .topLeft    || self == .topRight }
    var isRight: Bool  { self == .topRight   || self == .bottomRight }
}
