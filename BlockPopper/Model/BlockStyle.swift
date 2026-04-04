import UIKit

enum BlockStyle: Int, CaseIterable {
    case stone = 0
    case wood
    case terracotta
    case moss
    case sand

    var fillColor: UIColor {
        switch self {
        case .stone:      return UIColor(hex: 0x8B7D6B)
        case .wood:       return UIColor(hex: 0xA07B5A)
        case .terracotta: return UIColor(hex: 0xC4613A)
        case .moss:       return UIColor(hex: 0x4A6B3A)
        case .sand:       return UIColor(hex: 0xD4BC8A)
        }
    }

    var borderColor: UIColor {
        switch self {
        case .stone:      return UIColor(hex: 0x6B5D4B)
        case .wood:       return UIColor(hex: 0x7A5B3A)
        case .terracotta: return UIColor(hex: 0xA4412A)
        case .moss:       return UIColor(hex: 0x2A4B1A)
        case .sand:       return UIColor(hex: 0xB49C6A)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .stone:      return 4
        case .wood:       return 3
        case .terracotta: return 2
        case .moss:       return 5
        case .sand:       return 3
        }
    }

    var textureName: String? {
        switch self {
        case .stone:      return nil
        case .wood:       return "woodGrain"
        case .terracotta: return "roughEdge"
        case .moss:       return "organicBorder"
        case .sand:       return "subtleGradient"
        }
    }

    func next() -> BlockStyle {
        let allCases = BlockStyle.allCases
        let nextIndex = (rawValue + 1) % allCases.count
        return allCases[nextIndex]
    }
}
