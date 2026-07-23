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
        guard unitStyle == .decimal else {
            return binaryString(fromByteCount: byteCount)
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB]
        formatter.countStyle = .decimal
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: byteCount)
    }

    private func binaryString(fromByteCount byteCount: Int64) -> String {
        let bytes = Double(byteCount)
        let gibiBytes = 1_073_741_824.0
        let tebiBytes = 1_099_511_627_776.0
        let usesTebibytes = abs(bytes) >= tebiBytes
        let value = bytes / (usesTebibytes ? tebiBytes : gibiBytes)

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = value >= 10 ? 1 : 2

        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(formatted) \(usesTebibytes ? "TiB" : "GiB")"
    }
}
