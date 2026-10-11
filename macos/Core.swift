import AppKit
import ServiceManagement
import Darwin

struct Settings: Codable, Equatable {
    var version = 1
    var interval_secs = 60
    var always_on_top = true
    var start_at_login = false
    var x = 160
    var y = 160
    var codex_path: String?
}
struct Snapshot: Decodable, Equatable {
    let config: Settings
    let remaining: Int?
    let percentLabel: String
    let refreshLabel: String
    let refreshing: Bool
    let status: String
    let statusKind: String
    let suggestion: String
    let resetLabel: String
    let sampledLabel: String
    let shortLabel: String
    let details: String
    let commit: String
    let dirty: Bool
    let version: String
}
final class Core {
    private var handle: UnsafeMutableRawPointer?
    init(path: String, cli: String?) throws {
        handle = path.withCString { p in
            if let cli { return cli.withCString { quota_open(p, $0) } }
            return quota_open(p, nil)
        }
        if handle == nil { throw NSError(domain: "Quota", code: 1, userInfo: [NSLocalizedDescriptionKey: Core.error()]) }
    }
    static func error() -> String {
        guard let p = quota_error() else { return "操作失败" }
        defer { quota_string_free(p) }
        return String(cString: p)
    }
    func snapshot() -> Snapshot? {
        guard let handle, let p = quota_snapshot(handle) else { return nil }
        defer { quota_string_free(p) }
        return try? JSONDecoder().decode(Snapshot.self, from: Data(String(cString: p).utf8))
    }
    func configure(_ settings: Settings) throws {
        guard let handle else { return }
        let data = try JSONEncoder().encode(settings)
        let ok = String(decoding: data, as: UTF8.self).withCString { quota_configure(handle, $0) }
        if !ok { throw NSError(domain: "Quota", code: 2, userInfo: [NSLocalizedDescriptionKey: Core.error()]) }
    }
    func refresh() { if let handle { quota_refresh(handle) } }
    func close() { if let handle { quota_close(handle); self.handle = nil } }
    deinit { close() }
}
