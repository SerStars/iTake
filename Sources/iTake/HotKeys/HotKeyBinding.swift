import Foundation

struct HotKeyBinding: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
}
