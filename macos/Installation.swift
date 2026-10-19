import AppKit
import Security
import Darwin

struct InstalledBundle {
    let identifier: String
    let certificate: Data
    let version: String

    static func inspect(_ url: URL) throws -> InstalledBundle {
        var code: SecStaticCode?
        try require(SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess,
                    "无法读取应用签名。")
        guard let code else { throw installationError("应用签名不存在。") }
        try require(SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate), nil) == errSecSuccess,
                    "应用签名校验失败，请重新下载安装包。")
        var info: CFDictionary?
        try require(SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
                    "无法读取签名身份。")
        let signing = info as? [String: Any] ?? [:]
        guard let certificates = signing[kSecCodeInfoCertificates as String] as? [SecCertificate],
              let certificate = certificates.first,
              let bundle = Bundle(url: url), let identifier = bundle.bundleIdentifier,
              let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            throw installationError("安装包信息不完整，或未使用指定开发证书签名。")
        }
        return InstalledBundle(identifier: identifier, certificate: SecCertificateCopyData(certificate) as Data, version: version)
    }
}

private func installationError(_ message: String) -> NSError {
    NSError(domain: "QuotaInstallation", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
}
private func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw installationError(message) }
}

// Stages and verifies before touching the installed bundle. Settings/auth are never accessed.
struct InstallationTransaction {
    let destination: URL
    let source: URL
    private(set) var staging: URL?
    private(set) var replaced = false

    mutating func install(quiesce: () throws -> Void = {}) throws {
        let files = FileManager.default
        try require(source.standardizedFileURL != destination.standardizedFileURL, "应用已经位于安装位置。")
        let candidate = try InstalledBundle.inspect(source)
        try require(candidate.identifier == "studio.nanzhufeng.codexquota.mac", "安装包不属于南枫 Codex 额度。")
        let parent = destination.deletingLastPathComponent()
        try files.createDirectory(at: parent, withIntermediateDirectories: true)
        try require(files.isWritableFile(atPath: parent.path), "无法写入安装位置，请检查“应用程序”文件夹的权限。")
        if files.fileExists(atPath: destination.path) {
            let values = try destination.resourceValues(forKeys: [.isSymbolicLinkKey])
            try require(values.isSymbolicLink != true, "安装位置是符号链接，请先检查实际应用位置。")
            let existing = try InstalledBundle.inspect(destination)
            try require(existing.identifier == candidate.identifier && existing.certificate == candidate.certificate,
                        "现有应用签名身份不同，已停止替换，原应用和数据均保留。")
        }
        let work = parent.appendingPathComponent(".nanfeng-install-" + UUID().uuidString, isDirectory: true)
        try files.createDirectory(at: work, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        staging = work
        let staged = work.appendingPathComponent(destination.lastPathComponent)
        do {
            try files.copyItem(at: source, to: staged)
            let copied = try InstalledBundle.inspect(staged)
            try require(copied.identifier == candidate.identifier && copied.certificate == candidate.certificate && copied.version == candidate.version,
                        "复制后的安装包校验失败。")
            try quiesce()
            // Recheck after any prompt/wait. A foreign app must never be overwritten.
            replaced = files.fileExists(atPath: destination.path)
            if replaced {
                let existing = try InstalledBundle.inspect(destination)
                let values = try destination.resourceValues(forKeys: [.isSymbolicLinkKey])
                try require(values.isSymbolicLink != true && existing.identifier == candidate.identifier && existing.certificate == candidate.certificate,
                            "安装位置已发生变化，已停止替换。")
            }
            let flags = replaced ? UInt32(RENAME_SWAP) : UInt32(RENAME_EXCL)
            let result = staged.path.withCString { from in
                destination.path.withCString { to in renameatx_np(AT_FDCWD, from, AT_FDCWD, to, flags) }
            }
            guard result == 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
        } catch {
            try? files.removeItem(at: work); staging = nil
            throw error
        }
    }

    mutating func finish() {
        if let staging { try? FileManager.default.removeItem(at: staging) }
        staging = nil
    }
}

final class InstallationFlow {
    static var active: InstallationFlow?
    private var transaction: InstallationTransaction
    private var progress: NSAlert?
    private init(source: URL, destination: URL) {
        transaction = InstallationTransaction(destination: destination, source: source)
    }

    static func shouldOffer(path: String, downloads: String) -> Bool {
        path.hasPrefix("/Volumes/") || path.hasPrefix(downloads + "/") || path.contains("/AppTranslocation/")
    }

    // Runs before the settings lock so a running older copy cannot swallow the install choice.
    static func offerIfNeeded(arguments: [String]) -> Bool {
        if arguments.contains("--qa-root") { return false }
        let source = Bundle.main.bundleURL
        let downloads = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").path
        guard shouldOffer(path: source.path, downloads: downloads) else { return false }
        let destination = URL(fileURLWithPath: "/Applications/南枫 Codex 额度.app")
        let updating = FileManager.default.fileExists(atPath: destination.path)
        NSApp.activate(ignoringOtherApps: true)
        let choice = NSAlert()
        choice.messageText = updating ? "更新南枫 Codex 额度？" : "安装南枫 Codex 额度？"
        choice.informativeText = updating
            ? "将更新“应用程序”中的版本并重新打开，保留现有设置和登录数据。"
            : "安装到“应用程序”，以后可从应用列表直接打开。"
        choice.addButton(withTitle: updating ? "更新并打开" : "安装并打开")
        choice.addButton(withTitle: "暂不安装")
        choice.addButton(withTitle: "取消")
        switch choice.runModal() {
        case .alertFirstButtonReturn:
            let flow = InstallationFlow(source: source, destination: destination)
            active = flow; flow.begin(); return true
        case .alertSecondButtonReturn: return false
        default: NSApp.terminate(nil); return true
        }
    }

    private func begin() {
        let alert = NSAlert()
        alert.messageText = "正在安装南枫 Codex 额度"
        alert.informativeText = "正在校验并复制应用，请稍候。"
        let spinner = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 240, height: 16))
        spinner.style = .bar; spinner.isIndeterminate = true; spinner.startAnimation(nil)
        alert.accessoryView = spinner
        alert.window.center(); alert.window.makeKeyAndOrderFront(nil); progress = alert
        // Stage off the main thread; only the exact installed app is asked to quit on the main queue.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.transaction.install {
                    let semaphore = DispatchSemaphore(value: 0)
                    var stopped = false
                    DispatchQueue.main.async {
                        let target = self.transaction.destination.standardizedFileURL
                        let apps = NSWorkspace.shared.runningApplications.filter { $0.bundleURL?.standardizedFileURL == target }
                        for app in apps { _ = app.terminate() }
                        let deadline = Date().addingTimeInterval(6)
                        func waitForExit() {
                            if apps.allSatisfy({ $0.isTerminated }) { stopped = true; semaphore.signal() }
                            else if Date() >= deadline { semaphore.signal() }
                            else { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: waitForExit) }
                        }
                        waitForExit()
                    }
                    semaphore.wait()
                    try require(stopped, "原应用尚未退出，请关闭后重试。未强制结束进程。")
                }
                DispatchQueue.main.async { self.progress?.window.close(); self.openInstalled() }
            } catch {
                DispatchQueue.main.async { self.progress?.window.close(); self.showFailure(error) }
            }
        }
    }

    private func openInstalled() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        configuration.arguments = ["--show-settings"]
        NSWorkspace.shared.openApplication(at: transaction.destination, configuration: configuration) { app, error in
            DispatchQueue.main.async {
                if let error { self.showLaunchHelp(error) }
                else if let app, app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
                        app.bundleURL?.standardizedFileURL == self.transaction.destination.standardizedFileURL {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if app.isTerminated { self.showLaunchHelp(installationError("应用启动后已退出，请检查系统提示。")) }
                        else { self.transaction.finish(); NSApp.terminate(nil) }
                    }
                }
                else { self.showLaunchHelp(installationError("系统尚未确认应用已打开。")) }
            }
        }
    }

    private func showFailure(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "安装未完成"
        alert.informativeText = error.localizedDescription + "\n现有设置和登录数据未修改。"
        alert.addButton(withTitle: "重试"); alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn { begin() }
        else { NSApp.terminate(nil) }
    }

    private func showLaunchHelp(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "已安装，尚未打开"
        alert.informativeText = "如果 macOS 提示已阻止此应用，请在“隐私与安全性”中找到“南枫 Codex 额度”，由你确认“仍要打开”，再确认“打开”。\n\n" + error.localizedDescription
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "重试打开")
        alert.addButton(withTitle: "稍后")
        while true {
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                let opened = NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?General")!)
                if !opened { NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app")) }
                alert.informativeText = "完成系统确认后，可选择“重试打开”。设置页面打开不代表已获准启动。"
            case .alertSecondButtonReturn: openInstalled(); return
            default: NSApp.terminate(nil); return
            }
        }
    }
}
