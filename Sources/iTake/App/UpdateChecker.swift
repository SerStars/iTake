import Foundation

enum UpdateChecker {
    enum CheckResult {
        case upToDate
        case updateAvailable(version: String, url: URL)
        case noReleasesYet
        case failed
    }

    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlURL: URL

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }

    static func checkForUpdate() async -> CheckResult {
        guard let (owner, repo) = repoComponents() else { return .failed }
        guard
            let apiURL = URL(
                string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")
        else { return .failed }

        do {
            let (data, response) = try await URLSession.shared.data(from: apiURL)
            guard let httpResponse = response as? HTTPURLResponse else { return .failed }
            if httpResponse.statusCode == 404 { return .noReleasesYet }
            guard httpResponse.statusCode == 200 else { return .failed }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion =
                release.tagName.hasPrefix("v")
                ? String(release.tagName.dropFirst()) : release.tagName
            let currentVersion =
                Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            if isVersion(latestVersion, newerThan: currentVersion) {
                return .updateAvailable(version: latestVersion, url: release.htmlURL)
            }
            return .upToDate
        } catch {
            DebugLog.log("update check failed: \(error)")
            return .failed
        }
    }

    private static func repoComponents() -> (owner: String, repo: String)? {
        let parts = AboutInfo.githubURL.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2 else { return nil }
        return (parts[0], parts[1])
    }

    private static func isVersion(_ a: String, newerThan b: String) -> Bool {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(aParts.count, bParts.count) {
            let x = i < aParts.count ? aParts[i] : 0
            let y = i < bParts.count ? bParts[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
