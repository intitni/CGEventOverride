import Cocoa
import Combine
@preconcurrency import CoreGraphics
import Foundation

/// A hook of CGEvents.
public protocol CGEventHookType {
    /// Start the hook if possible.
    @discardableResult
    func activateIfPossible() -> Bool
    /// Deactivate the hook.
    func deactivate()
    /// Add a manipulation for events. Identified by a key.
    func add(_ manipulation: CGEventManipulation, forKey key: AnyHashable)
    /// Remove a manipulation from the hook.
    func removeManipulation(forKey key: AnyHashable)
}

/// Defines how a CGEvent will be translated into, and what side effects will happen.
public struct CGEventManipulation: Sendable {
    public enum Result: Sendable {
        case replaced(by: CGEvent)
        case discarded
        case unchanged

        public func combined(with result: Result) -> Result {
            switch (self, result) {
            case let (.unchanged, x): return x
            case (.discarded, _): return self
            case (.replaced, _): return self
            }
        }
    }

    /// Create a new manipulation.
    /// - Parameters:
    ///   - eventsOfInterest: Events it's listening.
    ///   - convert: The transformation of event, with side effects.
    ///     If the event is to be canceled, nil should be returned.
    public init(
        eventsOfInterest: Set<CGEventType>,
        convert: @escaping @Sendable (CGEventTapProxy, CGEventType, CGEvent) -> Result
    ) {
        self.eventsOfInterest = eventsOfInterest
        self.convert = convert
    }

    let eventsOfInterest: Set<CGEventType>
    let convert: @Sendable (CGEventTapProxy, CGEventType, CGEvent) -> Result
}

/// A hook receives disabling events.
let hookIsDisabledNotification = Notification.Name("HookIsDisabled")

func postIsDisabled() {
    NotificationCenter.default.post(
        name: hookIsDisabledNotification,
        object: nil
    )
}

/// A hook of CGEvents.
public final class CGEventHook: CGEventHookType, @unchecked Sendable {
    var port: CFMachPort?
    var allManipulations = [AnyHashable: CGEventManipulation]()
    var eventsOfInterest: Set<CGEventType>
    private var recoveryTimer: Timer?
    private var cancellable = [AnyCancellable]()
    public var isEnabled: Bool { port != nil }
    let logger: @Sendable (String) -> Void
    let tapLocation: CGEventTapLocation
    let tapPlacement: CGEventTapPlacement
    let tapOptions: CGEventTapOptions

    deinit {
        recoveryTimer?.invalidate()
    }

    /// Create a CGEventHook that listens into given event types.
    public init(
        eventsOfInterest: Set<CGEventType>,
        tapLocation: CGEventTapLocation = .cghidEventTap,
        tapPlacement: CGEventTapPlacement = .headInsertEventTap,
        tapOptions: CGEventTapOptions = .defaultTap,
        logger: @escaping @Sendable (String) -> Void = { _ in }
    ) {
        self.eventsOfInterest = eventsOfInterest
        self.logger = logger
        self.tapLocation = tapLocation
        self.tapPlacement = tapPlacement
        self.tapOptions = tapOptions

        NotificationCenter.default.publisher(for: hookIsDisabledNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.releasePort()
            }.store(in: &cancellable)
    }

    public func deactivate() {
        guard let port else { return }
        logger("Deactivate.")
        CFMachPortInvalidate(port)
        self.port = nil

        recoveryTimer?.invalidate()
        recoveryTimer = nil
    }

    func releasePort() {
        guard let port else { return }
        logger("Released.")
        CFMachPortInvalidate(port)
        self.port = nil

        setupTimerToRetry()
    }

    func setupTimerToRetry() {
        recoveryTimer?.invalidate()
        recoveryTimer = Timer(timeInterval: 5, repeats: true) { [logger] timer in
            logger("Trying to restart.")
            if self.activateIfPossible() {
                logger("Restarted.")
                timer.invalidate()
            }
        }

        RunLoop.current.add(recoveryTimer!, forMode: .common)
    }

    @discardableResult
    public func activateIfPossible() -> Bool {
        assert(Thread.isMainThread, "Activate CGEventHook only on main thread!")
        guard AXIsProcessTrusted() else {
            logger("Permission denied.")
            return false
        }
        guard port == nil else {
            logger("Already listening to events.")
            return true
        }

        let eoi: UInt64
        if eventsOfInterest.contains(.all) {
            eoi = .max
        } else {
            eoi = UInt64(eventsOfInterest.reduce(into: 0) { $0 |= 1 << $1.rawValue })
        }

        func callback(
            tapProxy: CGEventTapProxy,
            eventType: CGEventType,
            event: CGEvent,
            allManipulationsRawPointer: UnsafeMutableRawPointer?
        ) -> Unmanaged<CGEvent>? {
            guard AXIsProcessTrusted() else {
                postIsDisabled()
                return .passRetained(event)
            }

            if eventType == .tapDisabledByTimeout || eventType == .tapDisabledByUserInput {
                postIsDisabled()
                return .passRetained(event)
            }

            let allManipulations = allManipulationsRawPointer?
                .assumingMemoryBound(to: [AnyHashable: CGEventManipulation].self)
                .pointee ?? [:]

            guard !allManipulations.isEmpty else { return nil }

            var result = CGEventManipulation.Result.unchanged
            for (_, man) in allManipulations
                where man.eventsOfInterest.contains(eventType)
                || man.eventsOfInterest.contains(.all)
            {
                let next = man.convert(tapProxy, eventType, event)
                result = result.combined(with: next)
            }

            switch result {
            case .discarded: return nil
            case .unchanged: return .passUnretained(event)
            case let .replaced(newEvent): return .passUnretained(newEvent)
            }
        }

        let tapLocation = self.tapLocation
        let tapPlacement = self.tapPlacement
        let tapOptions = self.tapOptions

        guard let port = withUnsafeMutablePointer(to: &allManipulations, { pointer in
            CGEvent.tapCreate(
                tap: tapLocation,
                place: tapPlacement,
                options: tapOptions,
                eventsOfInterest: eoi,
                callback: callback,
                userInfo: pointer
            )
        }) else {
            setupTimerToRetry()
            return false
        }
        logger("Activated.")
        self.port = port
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        return true
    }

    public func add(_ manipulation: CGEventManipulation, forKey key: AnyHashable) {
        allManipulations[key] = manipulation
    }

    public func removeManipulation(forKey key: AnyHashable) {
        allManipulations[key] = nil
    }
}

