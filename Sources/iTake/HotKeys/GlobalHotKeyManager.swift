import AppKit
import Carbon.HIToolbox

@MainActor
final class GlobalHotKeyManager {
    static let shared = GlobalHotKeyManager()

    private static let signature: OSType = 0x6954_6B79  // 'iTky'

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private var eventHandlerRef: EventHandlerRef?

    private init() {
        installEventHandler()
    }

    @discardableResult
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) -> UInt32 {
        let hotKeyID = nextID
        nextID += 1

        let id = EventHotKeyID(signature: Self.signature, id: hotKeyID)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)

        if status == noErr, let hotKeyRef {
            hotKeyRefs[hotKeyID] = hotKeyRef
            handlers[hotKeyID] = handler
        } else {
            DebugLog.log("failed to register global hotkey (keyCode=\(keyCode)), status=\(status)")
        }
        return hotKeyID
    }

    func unregister(_ id: UInt32) {
        if let ref = hotKeyRefs[id] {
            UnregisterEventHotKey(ref)
            hotKeyRefs[id] = nil
        }
        handlers[id] = nil
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData -> OSStatus in
                guard let eventRef, let userData else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    eventRef, EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID
                )
                guard status == noErr else { return status }

                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData)
                    .takeUnretainedValue()
                let id = hotKeyID.id
                Task { @MainActor in
                    manager.handlers[id]?()
                }
                return noErr
            },
            1, &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }
}
