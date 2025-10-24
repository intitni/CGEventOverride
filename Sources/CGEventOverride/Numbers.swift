import Foundation

/// A 16.16 signed Int.
public struct Int16d16: Sendable {
    private static let one: Int32 = 0x10000
    private static let doubleOne: Double = 0x10000

    public var value: Int32

    init(_ value: Int32) {
        self.value = value
    }
    
    public init(from int: Int32) {
        value = int * Self.one
    }

    public init(from double: Double) {
        value = Int32(double * Self.doubleOne)
    }

    public var int32Value: Int32 {
        value / Self.one
    }

    public var intValue: Int {
        Int(value / Self.one)
    }

    public var doubleValue: Double {
        Double(value) / Self.doubleOne
    }
}
