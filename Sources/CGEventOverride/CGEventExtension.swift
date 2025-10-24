import AppKit
import Foundation
import IOKit

extension CGEvent {
    public subscript(_ field: CGEventField) -> Int64 {
        get { getIntegerValueField(field) }
        set { setIntegerValueField(field, value: newValue) }
    }
    
    public subscript(double field: CGEventField) -> Double {
        get { getDoubleValueField(field) }
        set { setDoubleValueField(field, value: newValue) }
    }

    public subscript(_ field: UInt32) -> Int64 {
        get { getIntegerValueField(CGEventField(rawValue: field)!) }
        set { setIntegerValueField(CGEventField(rawValue: field)!, value: newValue) }
    }
    
    public subscript(double field: UInt32) -> Double {
        get { getDoubleValueField(CGEventField(rawValue: field)!) }
        set { setDoubleValueField(CGEventField(rawValue: field)!, value: newValue) }
    }
}

extension CGEventType {
    enum Extra: UInt32, Sendable {
        case gesture = 29
        case dockGesture = 30
        var cgEventType: CGEventType { CGEventType(rawValue: rawValue)! }
    }

    static func extra(_ type: Extra) -> CGEventType { type.cgEventType }
    public static var gesture: CGEventType { extra(.gesture) }
    public static var dockGesture: CGEventType { extra(.dockGesture) }
    public static var all: CGEventType { CGEventType(rawValue: .max)! }
}

extension CGEventField {
    enum Extra: UInt32, Sendable {
        case eventType = 50
        case windowNumber = 51
        case gestureType = 110
        case gestureValueX = 113
        case gestureZoomDirection = 115
        case gestureSwipeValueX = 116
        case gestureScrollValueY = 119
        case gestureSwipeDirection = 117
        case gestureSwipeMotion = 123
        case gestureSwipeProgress = 124
        case gestureSwipePositionX = 125
        case gestureSwipePositionY = 126
        case gesturePhase = 132
        case scrollIsPartOfPan = 137
        var cgEventField: CGEventField { CGEventField(rawValue: rawValue)! }
    }

    static func extra(_ field: Extra) -> CGEventField { field.cgEventField }
    public static var windowNumber: CGEventField { extra(.eventType) }
    public static var eventType: CGEventField { extra(.eventType) }
    public static var gestureType: CGEventField { extra(.gestureType) }
    public static var gestureValueX: CGEventField { extra(.gestureValueX) }
    public static var gestureSwipeValueX: CGEventField { extra(.gestureSwipeValueX) }
    public static var gestureScrollValueY: CGEventField { extra(.gestureScrollValueY) }
    public static var gestureSwipeDirection: CGEventField { extra(.gestureSwipeDirection) }
    public static var gestureZoomDirection: CGEventField { extra(.gestureZoomDirection) }
    public static var gestureSwipeMotion: CGEventField { extra(.gestureSwipeMotion) }
    public static var gestureSwipeProgress: CGEventField { extra(.gestureSwipeProgress) }
    public static var gestureSwipePositionX: CGEventField { extra(.gestureSwipePositionX) }
    public static var gestureSwipePositionY: CGEventField { extra(.gestureSwipePositionY) }
    public static var gesturePhase: CGEventField { extra(.gesturePhase) }
    public static var scrollIsPartOfPan: CGEventField { extra(.scrollIsPartOfPan) }
}

public enum GestureType: Int64, CaseIterable, Sendable {
    case null = 0
    case vendorDefined
    case button
    case keyboard
    case translation
    case rotation
    case scroll
    case scale
    case zoom
    case velocity
    case orientation
    case digitizer
    case ambientLightSensor
    case accelerometer
    case proximity
    case temperature
    case navigationSwipe
    case mouse
    case progress
    case count
    case gyro
    case compass
    case zoomToggle
    case dockSwipe
    case symbolicHotKey
    case power
    case brightness
    case fluidTouchGesture
    case boundaryScroll
    case reset
    
    case gestureStarted = 61
    case gestureEnded = 62

    static var swipe: Self { .navigationSwipe }
}

public enum SwipeDirection: UInt64, CaseIterable, Sendable {
    case none = 0x00000000
    case up = 0x00000001
    case down = 0x00000002
    case left = 0x00000004
    case right = 0x00000008
}

public enum ZoomDirection: Int64, CaseIterable, Sendable {
    case none = 0
    case expand
    case contract
}

public enum RotateDirection: Int64, CaseIterable, Sendable {
    case none = 0
    case clockwise = 2
    case counterClockwise = -2
}

public enum GestureMotion: UInt64, CaseIterable, Sendable {
    case none = 0
    case horizontal
    case vertical
    case pinch
    case rotate
    case tap
    case doubleTap
    case fromLeftEdge
    case offLeftEdge
    case fromRightEdge
    case offRightEdge
    case fromTopEdge
    case offTopEdge
    case fromBottomEdge
    case offBottomEdge
}


