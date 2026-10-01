import Foundation

struct GitHubHelper {
    private let apiUrl = "https://api.github.com"
    private let decoder = JSONDecoder()
    
    static let shared = GitHubHelper()
    
    init() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    private func perform(_ path: String) async throws -> Data {
        let url = URL(string: "\(apiUrl)\(path)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return data
    }
    
    func getLatestRelease() async throws -> GitHubRelease {
        let data = try await perform("/repos/jaydenjcpy/EeveeSpotifyReincarnated/releases/latest")
        return try decoder.decode(GitHubRelease.self, from: data)
    }
    
    func getUser(_ username: String) async throws -> GitHubUser {
        let data = try await perform("/users/\(username)")
        return try decoder.decode(GitHubUser.self, from: data)
    }
    
    func getContributors() async throws -> [GitHubUser] {
        let data = try await perform("/repos/\(EeveeSpotify.repoSlug)/contributors")
        return try decoder.decode([GitHubUser].self, from: data)
    }
    
    /// The contributors sheet's data. The list is a JSON file on a branch of the repo, so this asks
    /// the branch the build was made from first and then the default branch (a build made from a
    /// branch that was never pushed — the common case while developing — used to 404 there, and a
    /// 404 body is not JSON, which is what put "The data couldn't be read because it isn't in the
    /// correct format" on screen). If no fetch yields JSON, the copy shipped in the tweak's own
    /// bundle is drawn instead, so the sheet always has something to show.
    func getEeveeContributorSections() async throws -> [EeveeContributorSection] {
        for branch in [GeneratedConfig.branchName, "Master"] {
            if let sections = try? await fetchContributorSections(branch: branch) {
                return sections
            }
        }

        if let data = BundleHelper.shared.bundledContributorsJSON,
           let sections = try? decoder.decode([EeveeContributorSection].self, from: data) {
            return sections
        }

        // Nothing worked: ask once more so the sheet can show the real reason.
        return try await fetchContributorSections(branch: GeneratedConfig.branchName)
    }

    private func fetchContributorSections(branch: String) async throws -> [EeveeContributorSection] {
        guard let url = URL(
            string: "https://raw.githubusercontent.com/\(EeveeSpotify.repoSlug)/refs/heads/\(branch)/contributors.json"
        ) else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)
        // A missing branch answers 404 with a plain-text body, which decodes as a failure with a
        // confusing message; reject it here so the caller moves on to the next source.
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode([EeveeContributorSection].self, from: data)
    }
}
