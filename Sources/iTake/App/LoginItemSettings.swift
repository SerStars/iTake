import ServiceManagement

enum LoginItemSettings {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            DebugLog.log("failed to \(enabled ? "register" : "unregister") login item: \(error)")
        }
    }
}
