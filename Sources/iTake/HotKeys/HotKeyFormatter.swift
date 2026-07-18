import Carbon.HIToolbox
import SwiftUI

enum HotKeyFormatter {
    static func string(for binding: HotKeyBinding) -> String {
        var result = ""
        if binding.modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if binding.modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if binding.modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if binding.modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        result += keyLabel(for: binding.keyCode)
        return result
    }

    static func eventModifiers(for binding: HotKeyBinding) -> SwiftUI.EventModifiers {
        var result: SwiftUI.EventModifiers = []
        if binding.modifiers & UInt32(controlKey) != 0 { result.insert(.control) }
        if binding.modifiers & UInt32(optionKey) != 0 { result.insert(.option) }
        if binding.modifiers & UInt32(shiftKey) != 0 { result.insert(.shift) }
        if binding.modifiers & UInt32(cmdKey) != 0 { result.insert(.command) }
        return result
    }

    static func keyEquivalent(for binding: HotKeyBinding) -> KeyEquivalent? {
        switch Int(binding.keyCode) {
        case kVK_Space: return .space
        case kVK_Return: return .return
        case kVK_Tab: return .tab
        case kVK_Escape: return .escape
        case kVK_Delete: return .delete
        case kVK_LeftArrow: return .leftArrow
        case kVK_RightArrow: return .rightArrow
        case kVK_UpArrow: return .upArrow
        case kVK_DownArrow: return .downArrow
        default:
            guard let character = characterKeys[Int(binding.keyCode)] else { return nil }
            return KeyEquivalent(character)
        }
    }

    private static let characterKeys: [Int: Character] = [
        kVK_ANSI_A: "a", kVK_ANSI_B: "b", kVK_ANSI_C: "c", kVK_ANSI_D: "d", kVK_ANSI_E: "e",
        kVK_ANSI_F: "f", kVK_ANSI_G: "g", kVK_ANSI_H: "h", kVK_ANSI_I: "i", kVK_ANSI_J: "j",
        kVK_ANSI_K: "k", kVK_ANSI_L: "l", kVK_ANSI_M: "m", kVK_ANSI_N: "n", kVK_ANSI_O: "o",
        kVK_ANSI_P: "p", kVK_ANSI_Q: "q", kVK_ANSI_R: "r", kVK_ANSI_S: "s", kVK_ANSI_T: "t",
        kVK_ANSI_U: "u", kVK_ANSI_V: "v", kVK_ANSI_W: "w", kVK_ANSI_X: "x", kVK_ANSI_Y: "y",
        kVK_ANSI_Z: "z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3", kVK_ANSI_4: "4",
        kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8", kVK_ANSI_9: "9",
    ]

    private static let keyLabels: [Int: String] = [
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D", kVK_ANSI_E: "E",
        kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H", kVK_ANSI_I: "I", kVK_ANSI_J: "J",
        kVK_ANSI_K: "K", kVK_ANSI_L: "L", kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O",
        kVK_ANSI_P: "P", kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X", kVK_ANSI_Y: "Y",
        kVK_ANSI_Z: "Z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3", kVK_ANSI_4: "4",
        kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        kVK_Space: "Space", kVK_Return: "Return", kVK_Tab: "Tab", kVK_Escape: "Esc",
        kVK_Delete: "Delete",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
    ]

    private static func keyLabel(for keyCode: UInt32) -> String {
        keyLabels[Int(keyCode)] ?? "Key \(keyCode)"
    }
}
