import UIKit

enum BlockStyle: Int, CaseIterable {
    case stone = 0
    case wood
    case terracotta
    case moss
    case sand

    var fillColor: UIColor {
        switch self {
        case .stone:      return UIColor(hex: 0xC8B487) // natural bamboo
        case .wood:       return UIColor(hex: 0xD4C49A) // pale bamboo
        case .terracotta: return UIColor(hex: 0xBDA87A) // toasted bamboo
        case .moss:       return UIColor(hex: 0xC2B88E) // green-tint bamboo
        case .sand:       return UIColor(hex: 0xDACFA5) // light bamboo
        }
    }

    var borderColor: UIColor {
        switch self {
        case .stone:      return UIColor(hex: 0xAA9469) // natural bamboo border
        case .wood:       return UIColor(hex: 0xB8A67A) // pale bamboo border
        case .terracotta: return UIColor(hex: 0x9E8A60) // toasted bamboo border
        case .moss:       return UIColor(hex: 0xA49A70) // green-tint border
        case .sand:       return UIColor(hex: 0xBCB185) // light bamboo border
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
