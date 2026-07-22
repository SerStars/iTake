import SwiftUI

struct AboutView: View {
    @State private var isCheckingForUpdate = false
    @State private var updateCheckResult: UpdateChecker.CheckResult?

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 14) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 96, height: 96)
            } else {
                Image(systemName: "camera.viewfinder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.tint)
            }

            VStack(spacing: 4) {
                Text("iTake")
                    .font(.title2.bold())
                Text("Version \(version) (\(build))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Text("Made by \(AboutInfo.authorName)")
                    .font(.callout)

                HStack(spacing: 12) {
                    Link(destination: AboutInfo.githubURL) {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Link(destination: AboutInfo.githubIssuesURL) {
                        Label("Report an Issue", systemImage: "ladybug")
                    }
                }
                .font(.callout)
                .buttonStyle(.link)
            }

            VStack(spacing: 4) {
                Button {
                    checkForUpdate()
                } label: {
                    if isCheckingForUpdate {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Check for Updates")
                    }
                }
                .disabled(isCheckingForUpdate)

                if let updateCheckResult {
                    updateResultView(updateCheckResult)
                }

                #if DEBUG
                    Button("Preview Update Notice (Debug)") {
                        StatusOverlayController.shared.show(
                            title: "Update Available",
                            subtitle: "v9.9.9 — click to view on GitHub",
                            systemImage: "arrow.down.circle.fill",
                            autoDismissDelay: nil,
                            onTap: { NSWorkspace.shared.open(AboutInfo.githubURL) }
                        )
                    }
                    .font(.caption)
                #endif
            }

            Text(
                "© \(String(Calendar.current.component(.year, from: Date()))) \(AboutInfo.authorName). All rights reserved."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 320)
    }

    @ViewBuilder
    private func updateResultView(_ result: UpdateChecker.CheckResult) -> some View {
        switch result {
        case .upToDate:
            Text("You're up to date.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .updateAvailable(let version, let url):
            Button {
                NSWorkspace.shared.open(url)
            } label: {
                Label("Update Available: v\(version)", systemImage: "arrow.down.circle.fill")
                    .font(.caption.bold())
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.accentColor)
        case .noReleasesYet:
            Text("No releases published yet.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .failed:
            Text("Couldn't check for updates.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func checkForUpdate() {
        isCheckingForUpdate = true
        updateCheckResult = nil
        Task {
            let result = await UpdateChecker.checkForUpdate()
            isCheckingForUpdate = false
            updateCheckResult = result
        }
    }
}
