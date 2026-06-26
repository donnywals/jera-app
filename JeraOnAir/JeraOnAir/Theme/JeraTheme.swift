import SwiftUI

enum JeraTheme {
    static let bodyColor1 = Color(red: 0.106, green: 0.129, blue: 0.161)   // #1b2129
    static let bodyColor2 = Color(red: 0.063, green: 0.082, blue: 0.106)   // #10151b
    static let accentGold = Color(red: 0.914, green: 0.706, blue: 0.267)  // #e9b444
    static let accentTeal = Color(red: 0.345, green: 0.714, blue: 0.616) // #58b69d
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.65)
    static let currentTimeLine = Color.red.opacity(0.55)

    static let stageHeight: CGFloat = 100
    static let timeHeaderHeight: CGFloat = 36
    static let slotWidth: CGFloat = 9
    static let cornerRadius: CGFloat = 10
}
