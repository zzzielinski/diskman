import Foundation

public struct DiskByteFormatter: Sendable {
    public enum UnitStyle: Sendable {
        case decimal
        case binary
    }

    public static let decimal = DiskByteFormatter(unitStyle: .decimal)
    public static let binary = DiskByteFormatter(unitStyle: .binary)

    public let unitStyle: UnitStyle
    public let locale: Locale

    public init(unitStyle: UnitStyle = .decimal, locale: Locale = .current) {
        self.unitStyle = unitStyle
        self.locale = locale
    }

    public func string(fromByteCount byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB]
        formatter.countStyle = unitStyle == .decimal ? .decimal : .binary
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: byteCount)
    }
}
