import Foundation

/// Which kind of ad was stopped, so the settings page can break the total down the way the ads
/// arrive: inside the audio stream, as a banner or card in a feed, or as video.
enum EeveeAdsBlockedKind: String, CaseIterable {
    case audio
    case banner
    case video

    var title: String {
        switch self {
        case .audio: return "audio"
        case .banner: return "banner"
        case .video: return "video"
        }
    }
}

/// A running count of every ad request the tweak intercepted or dropped, so the settings page can
/// show what the ad blocking has actually been doing rather than only that it is on.
///
/// The total is persisted with `UserDefaults.standard` under `kEeveeAdsBlockedCount`; each kind
/// keeps its own key beside it. Only ads are counted — the session-protection endpoints that share
/// these drop sites are not. Nothing is counted unless the block actually happens, so with ad
/// blocking off the total simply stops moving.
///
/// These are all main-thread call sites today, but the lock keeps the count honest if one ever
/// moves off it, and the counter is written on every note so a crash cannot lose a batch.
enum EeveeAdsBlocked {
    static let defaultsKey = "kEeveeAdsBlockedCount"

    private static let lock = NSLock()

    /// `shouldBlock` is asked about the same request from more than one hook — the URLSession and
    /// DataLoader paths, each at the request and again at the response — so one note per call would
    /// count one ad several times. A URL counted inside this window is taken to be the same ad.
    private static let dedupeWindow: TimeInterval = 3
    private static var recentlyCounted: [String: Date] = [:]

    private static func kindKey(_ kind: EeveeAdsBlockedKind) -> String {
        "\(defaultsKey).\(kind.rawValue)"
    }

    /// Every ad stopped so far.
    static var count: Int {
        lock.lock(); defer { lock.unlock() }
        return UserDefaults.standard.integer(forKey: defaultsKey)
    }

    /// How many of those were of one kind.
    static func count(of kind: EeveeAdsBlockedKind) -> Int {
        lock.lock(); defer { lock.unlock() }
        return UserDefaults.standard.integer(forKey: kindKey(kind))
    }

    /// Notes one ad stopped; answers the new total.
    @discardableResult
    static func note(_ kind: EeveeAdsBlockedKind) -> Int {
        lock.lock(); defer { lock.unlock() }
        let defaults = UserDefaults.standard
        let total = defaults.integer(forKey: defaultsKey) + 1
        defaults.set(total, forKey: defaultsKey)
        defaults.set(defaults.integer(forKey: kindKey(kind)) + 1, forKey: kindKey(kind))
        return total
    }

    /// Notes an ad stopped by its URL, at most once per request however many hooks see it. A request
    /// that is not recognized as an ad by URL is not counted here; callers that drop a service or a
    /// feed component outright use `note(_:)` instead.
    static func noteOnce(_ url: URL, kind: EeveeAdsBlockedKind) {
        lock.lock()
        let now = Date()
        recentlyCounted = recentlyCounted.filter { now.timeIntervalSince($0.value) < dedupeWindow }
        let key = url.absoluteString
        if recentlyCounted[key] != nil {
            lock.unlock()
            return
        }
        recentlyCounted[key] = now
        lock.unlock()
        note(kind)
    }

    /// Back to zero, for the settings page's reset.
    static func reset() {
        lock.lock(); defer { lock.unlock() }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: defaultsKey)
        for kind in EeveeAdsBlockedKind.allCases {
            defaults.removeObject(forKey: kindKey(kind))
        }
    }
}
