import Foundation

enum Formatters {
    static let percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

extension Double {
    func asPercentString() -> String {
        Formatters.percent.string(from: NSNumber(value: self)) ?? "0%"
    }
}
