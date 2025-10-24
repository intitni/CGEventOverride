public enum MouseCode: RawRepresentable, Sendable {
    case mouseLeft
    case mouseRight
    case mouseMiddle
    case mouse(Int)

    public var rawValue: Int {
        switch self {
        case .mouseLeft: return 0
        case .mouseRight: return 1
        case .mouseMiddle: return 2
        case .mouse(let n): return n
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .mouseLeft
        case 1: self = .mouseRight
        case 2: self = .mouseMiddle
        default: self = .mouse(rawValue)
        }
    }
}
