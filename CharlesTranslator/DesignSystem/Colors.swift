import SwiftUI

extension Color {
    /// Charles University brand red, confirmed from the web client's theme (`#d22d40`).
    static let charlesRed = Color(red: 0xD2 / 255, green: 0x2D / 255, blue: 0x40 / 255)

    /// A standard system-blue, used for the on-device capability indicators (the
    /// mic corner dot and the Settings badges). Chosen to be visible but not
    /// intrusive — it reads as "available offline" rather than a status alert.
    static let charlesBlue = Color(red: 0x0A / 255, green: 0x5F / 255, blue: 0xD4 / 255)
}
