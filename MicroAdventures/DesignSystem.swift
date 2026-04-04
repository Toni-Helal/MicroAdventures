import SwiftUI

// MARK: - Colors

enum AppColor {
    // Surfaces
    static let background       = Color("AppBackground")
    static let surface          = Color("AppSurface")
    static let surfaceElevated  = Color("AppSurfaceElevated")

    // Brand
    static let accent           = Color("AppAccent")
    static let accentSubtle     = Color("AppAccentSubtle")

    // Semantic
    static let success          = Color("AppSuccess")
    static let successSubtle    = Color("AppSuccessSubtle")
    static let warning          = Color("AppWarning")
    static let danger           = Color("AppDanger")

    // Text
    static let textPrimary      = Color.primary
    static let textSecondary    = Color.secondary
    static let textTertiary     = Color("AppTextTertiary")

    // Chips
    static let chipBackground   = Color("AppChipBackground")
    static let chipSelected     = Color("AppAccent")
}

// MARK: - Typography

enum AppFont {
    static let title       = Font.system(.title2,      design: .rounded, weight: .bold)
    static let headline    = Font.system(.headline,    design: .rounded, weight: .semibold)
    static let body        = Font.system(.body,        design: .default)
    static let subheadline = Font.system(.subheadline, design: .default)
    static let caption     = Font.system(.caption,     design: .default)
    static let caption2    = Font.system(.caption2,    design: .default)
}

// MARK: - Spacing

enum AppSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum AppRadius {
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 16
    static let xl:   CGFloat = 24
    static let pill: CGFloat = 999
}

// MARK: - Shadows

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum AppShadow {
    static let card     = AppShadowStyle(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    static let elevated = AppShadowStyle(color: .black.opacity(0.14), radius: 20, x: 0, y: 8)
    static let subtle   = AppShadowStyle(color: .black.opacity(0.05), radius: 6,  x: 0, y: 2)
}

extension View {
    func appShadow(_ style: AppShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Animations

enum AppAnimation {
    static let spring    = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let snappy    = Animation.spring(response: 0.25, dampingFraction: 0.9)
    static let celebrate = Animation.spring(response: 0.45, dampingFraction: 0.65)
    static let quick     = Animation.easeInOut(duration: 0.12)
}
