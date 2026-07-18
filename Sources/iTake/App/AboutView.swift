import SwiftUI

struct AboutView: View {
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

            Text(
                "© \(String(Calendar.current.component(.year, from: Date()))) \(AboutInfo.authorName). All rights reserved."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 320)
    }
}
