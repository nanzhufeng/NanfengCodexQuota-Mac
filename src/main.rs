#![cfg_attr(windows, windows_subsystem = "windows")]
fn main() {
    #[cfg(target_os = "macos")]
    {
        let path = nanfeng_codex_quota::codex::first_available(None);
        match path.and_then(|p| nanfeng_codex_quota::codex::CodexClient::new(p).read_rate_limits())
        {
            Ok(limits) => println!("{}", serde_json::to_string(&limits).unwrap()),
            Err(_) => {
                eprintln!("无法读取额度；请打开 Mac 应用查看状态");
                std::process::exit(1);
            }
        }
    }
    #[cfg(windows)]
    if let Err(error) = nanfeng_codex_quota::desktop::run() {
        nanfeng_codex_quota::desktop::show_error(&format!("{error:#}"));
    }
}
