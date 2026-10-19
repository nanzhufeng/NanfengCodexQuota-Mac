import Foundation

@main struct InstallationTests {
    static func main() throws {
        let args = CommandLine.arguments
        guard args.count == 3 else { fatalError("usage: installation-tests new.app old.app") }
        let source = URL(fileURLWithPath: args[1]), previous = URL(fileURLWithPath: args[2])
        let files = FileManager.default
        let root = files.temporaryDirectory.appendingPathComponent("nfq-install-tests-" + UUID().uuidString)
        try files.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? files.removeItem(at: root) }
        var count = 0
        func check(_ name: String, _ ok: Bool) {
            guard ok else { fatalError("FAIL: " + name) }
            count += 1; print("PASS: " + name)
        }
        func executable(_ url: URL) throws -> Data {
            try Data(contentsOf: url.appendingPathComponent("Contents/MacOS/NanfengCodexQuota"))
        }
        func rejects(_ operation: () throws -> Void) -> Bool {
            do { try operation(); return false } catch { return true }
        }
        check("DMG entry offers installation", InstallationFlow.shouldOffer(path: "/Volumes/额度/Quota.app", downloads: "/Users/test/Downloads"))
        check("download entry offers installation", InstallationFlow.shouldOffer(path: "/Users/test/Downloads/Quota.app", downloads: "/Users/test/Downloads"))
        check("translocated entry offers installation", InstallationFlow.shouldOffer(path: "/private/var/folders/test/AppTranslocation/uuid/d/Quota.app", downloads: "/Users/test/Downloads"))
        check("installed app does not prompt", !InstallationFlow.shouldOffer(path: "/Applications/南枫 Codex 额度.app", downloads: "/Users/test/Downloads"))
        let data = root.appendingPathComponent("settings.toml")
        try Data("settings sentinel\n".utf8).write(to: data)
        let destination = root.appendingPathComponent("Applications/南枫 Codex 额度.app")
        var install = InstallationTransaction(destination: destination, source: source)
        try install.install()
        check("fresh installation is signed and readable", try InstalledBundle.inspect(destination).version == "0.1.8")
        check("installed executable matches source", try executable(destination) == executable(source))
        install.finish()
        check("transaction cleanup", install.staging == nil)
        try files.removeItem(at: destination)
        try files.copyItem(at: previous, to: destination)
        var cancelled = InstallationTransaction(destination: destination, source: source)
        check("cancelled update returns failure", rejects { try cancelled.install { throw NSError(domain: "test-cancel", code: 1) } })
        check("cancel leaves old version intact", try executable(destination) == executable(previous))
        var update = InstallationTransaction(destination: destination, source: source)
        try update.install()
        check("same certificate update succeeds", try executable(destination) == executable(source))
        let backup = update.staging!.appendingPathComponent(destination.lastPathComponent)
        check("old version remains recoverable until launch", try executable(backup) == executable(previous))
        update.finish()
        let downloaded = root.appendingPathComponent("downloaded.app")
        try files.copyItem(at: source, to: downloaded)
        let quarantine = "0081;00000000;NanfengInstallationTests;"
        let mark = Process(); mark.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        mark.arguments = ["-w", "com.apple.quarantine", quarantine, downloaded.path]
        try mark.run(); mark.waitUntilExit()
        check("isolated quarantine fixture prepared", mark.terminationStatus == 0)
        let quarantinedTarget = root.appendingPathComponent("Quarantined/南枫 Codex 额度.app")
        var quarantineInstall = InstallationTransaction(destination: quarantinedTarget, source: downloaded)
        try quarantineInstall.install()
        let read = Process(), output = Pipe(); read.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        read.arguments = ["-p", "com.apple.quarantine", quarantinedTarget.path]; read.standardOutput = output
        try read.run()
        let actual = output.fileHandleForReading.readDataToEndOfFile(); read.waitUntilExit()
        let quarantineFields = String(data: actual, encoding: .utf8)?.trimmingCharacters(in: .newlines).split(separator: ";", omittingEmptySubsequences: false)
        let quarantineFlags = quarantineFields?.first.flatMap { UInt32($0, radix: 16) } ?? 0
        // macOS copy normalizes provenance and may add flags (0081 -> 0281).
        // Verify the actual security contract: no incoming protection bits were removed.
        check("installation retains quarantine protection", read.terminationStatus == 0 && quarantineFlags & 0x0081 == 0x0081)
        let originalRead = Process(), originalOutput = Pipe()
        originalRead.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        originalRead.arguments = ["-p", "com.apple.quarantine", downloaded.path]; originalRead.standardOutput = originalOutput
        try originalRead.run()
        let originalValue = originalOutput.fileHandleForReading.readDataToEndOfFile(); originalRead.waitUntilExit()
        check("source quarantine remains unchanged", String(data: originalValue, encoding: .utf8)?.trimmingCharacters(in: .newlines) == quarantine)
        quarantineInstall.finish()
        let damaged = root.appendingPathComponent("damaged.app")
        try files.copyItem(at: source, to: damaged)
        let exe = damaged.appendingPathComponent("Contents/MacOS/NanfengCodexQuota")
        let handle = try FileHandle(forWritingTo: exe); try handle.seekToEnd(); try handle.write(contentsOf: Data([1])); try handle.close()
        var bad = InstallationTransaction(destination: destination, source: damaged)
        check("tampered package rejected", rejects { try bad.install() })
        check("failed update retains installed executable", try executable(destination) == executable(source))
        let link = root.appendingPathComponent("linked.app")
        try files.createSymbolicLink(at: link, withDestinationURL: destination)
        var linked = InstallationTransaction(destination: link, source: source)
        check("symlink destination refused", rejects { try linked.install() })
        let foreign = root.appendingPathComponent("foreign.app")
        try files.copyItem(at: previous, to: foreign)
        let signing = Process(); signing.executableURL = URL(fileURLWithPath: "/usr/bin/codesign"); signing.arguments = ["--force", "--sign", "-", foreign.path]
        try signing.run(); signing.waitUntilExit()
        check("foreign fixture signed", signing.terminationStatus == 0)
        var other = InstallationTransaction(destination: foreign, source: source)
        check("different signing identity refused", rejects { try other.install() })
        check("settings preserved throughout", try Data(contentsOf: data) == Data("settings sentinel\n".utf8))
        check("source remains valid", try InstalledBundle.inspect(source).version == "0.1.8")
        let leftovers = try files.contentsOfDirectory(atPath: destination.deletingLastPathComponent().path).filter { $0.hasPrefix(".nanfeng-install-") }
        check("no abandoned staging directories", leftovers.isEmpty)
        print("INSTALLATION TESTS: \(count) PASS")
    }
}
