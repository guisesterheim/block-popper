import UIKit

struct ColorPalette {
    // Background
    static let background = UIColor(hex: 0x3B2A1A)

    // Grid
    static let gridCellEmpty = UIColor(hex: 0x5A4A3A)
    static let gridCellBorder = UIColor(hex: 0x4A3A2A)

    // HUD
    static let hudText = UIColor(hex: 0xF5E6D0)
    static let hudTextSecondary = UIColor(hex: 0xD4BC8A)

    // Ghost preview
    static let ghostValid = UIColor.green.withAlphaComponent(0.3)
    static let ghostInvalid = UIColor.red.withAlphaComponent(0.3)

    // Rescue sweep
    static let rescueSweep = UIColor(hex: 0xF5E6D0).withAlphaComponent(0.8)

    // Line clear flash
    static let clearFlash = UIColor.white
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
