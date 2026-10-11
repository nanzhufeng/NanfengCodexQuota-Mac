#![cfg(target_os = "macos")]
use nanfeng_codex_quota::{
    config::Config,
    mac_core::MacCore,
    weekly_quota_render::{WeeklyQuotaRenderModel, render_weekly_quota_base_at_scale},
    worker::{Event, Worker},
};
use serde_json::Value;
use std::{
    fs,
    os::unix::fs::PermissionsExt,
    path::{Path, PathBuf},
    process::{Command, Stdio},
    time::{Duration, Instant},
};

fn fixture(directory: &Path, source: &str) -> PathBuf {
    let path = directory.join("codex-fixture");
    fs::write(&path, format!("#!/usr/bin/python3\n{source}")).unwrap();
    fs::set_permissions(&path, fs::Permissions::from_mode(0o700)).unwrap();
    path
}
fn await_snapshot(core: &mut MacCore, expected: &str) -> Value {
    let deadline = Instant::now() + Duration::from_secs(4);
    loop {
        let value = core.snapshot();
        if value["status"] == expected && value["refreshing"] == false {
            return value;
        }
        assert!(Instant::now() < deadline, "state was {}", value["status"]);
        std::thread::sleep(Duration::from_millis(20));
    }
}
#[test]
fn native_host_preserves_quota_on_failure_and_recovers_without_inventing_missing_windows() {
    let dir = tempfile::tempdir().unwrap();
    let state = dir.path().join("state");
    fs::write(&state, "success").unwrap();
    let cli = fixture(
        dir.path(),
        &format!(
            r#"import json,sys
from pathlib import Path
for line in sys.stdin:
    r=json.loads(line)
    if r['method']=='initialize': result={{'result':{{}}}}
    elif r['method']=='account/rateLimits/read':
        state=Path({:?}).read_text()
        if state=='failure': result={{'error':{{'message':'network connection failure'}}}}
        else:
            limits={{}} if state=='missing' else {{'secondary':{{'usedPercent':65.4,'windowDurationMins':10080}},'primary':{{'usedPercent':23,'windowDurationMins':300}}}}
            result={{'result':{{'rateLimits':limits}}}}
    else: raise SystemExit('unexpected non-read-only RPC')
    print(json.dumps({{'id':r['id'],**result}}),flush=True)
"#,
            state.to_string_lossy()
        ),
    );
    let mut core = MacCore::open(dir.path().join("settings.toml"), Some(cli)).unwrap();
    let value = await_snapshot(&mut core, "已连接");
    assert_eq!(value["percentLabel"], "34%");
    assert_eq!(value["shortLabel"], "剩余 77%");
    fs::write(&state, "failure").unwrap();
    core.refresh();
    let failed = await_snapshot(&mut core, "连接失败");
    assert_eq!(failed["percentLabel"], "34%");
    assert_eq!(failed["statusKind"], "warning");
    fs::write(&state, "missing").unwrap();
    core.refresh();
    let missing = await_snapshot(&mut core, "已连接");
    assert_eq!(missing["percentLabel"], "--%");
    assert_eq!(missing["shortLabel"], "接口未提供");
    fs::write(&state, "success").unwrap();
    core.refresh();
    assert_eq!(await_snapshot(&mut core, "已连接")["percentLabel"], "34%");
}
#[test]
fn mac_exit_cancels_and_reaps_the_exact_in_flight_child() {
    let dir = tempfile::tempdir().unwrap();
    let marker = dir.path().join("pid");
    let cli = fixture(
        dir.path(),
        &format!(
            "import os,time\nfrom pathlib import Path\nPath({:?}).write_text(str(os.getpid()))\ntime.sleep(60)\n",
            marker.to_string_lossy()
        ),
    );
    let (mut worker, events) = Worker::start(
        Config {
            codex_path: Some(cli),
            ..Default::default()
        },
        || {},
    );
    assert!(matches!(
        events.recv_timeout(Duration::from_secs(2)).unwrap(),
        Event::Started
    ));
    let deadline = Instant::now() + Duration::from_secs(3);
    while !marker.exists() && Instant::now() < deadline {
        std::thread::sleep(Duration::from_millis(20));
    }
    let pid = fs::read_to_string(marker).unwrap();
    let began = Instant::now();
    worker.stop();
    assert!(began.elapsed() < Duration::from_secs(2));
    let exists = Command::new("/bin/kill")
        .args(["-0", &pid])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .unwrap()
        .success();
    assert!(!exists, "owned CLI child survived shutdown");
}
#[test]
fn damaged_or_future_config_is_preserved_before_any_query_is_started() {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("settings.toml");
    for content in ["broken [", "version = 2\n"] {
        fs::write(&path, content).unwrap();
        assert!(MacCore::open(path.clone(), None).is_err());
        assert_eq!(fs::read_to_string(&path).unwrap(), content);
    }
}
#[test]
fn retina_export_has_transparent_corners_and_valid_premultiplied_alpha() {
    let pixels = render_weekly_quota_base_at_scale(&WeeklyQuotaRenderModel::preview(34), 2);
    assert_eq!(pixels.len(), 264 * 264 * 4);
    assert_eq!(&pixels[..4], &[0, 0, 0, 0]);
    assert!(
        pixels
            .chunks_exact(4)
            .all(|p| p[0] <= p[3] && p[1] <= p[3] && p[2] <= p[3])
    );
}
