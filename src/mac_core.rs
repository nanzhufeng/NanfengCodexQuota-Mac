//! Native Mac host boundary. All calls are confined to the AppKit main thread.
//! The original worker owns queries; the host only reads a shared presentation snapshot.
use crate::{
    config::Config,
    monitor::{Failure, Monitor},
    worker::{Command, Event, Worker},
};
use anyhow::{Context, Result};
use chrono::{Local, Utc};
use serde_json::{Value, json};
use std::{
    ffi::{CStr, CString, c_char},
    path::PathBuf,
    sync::mpsc::Receiver,
};

pub struct MacCore {
    pub config: Config,
    path: PathBuf,
    monitor: Monitor,
    worker: Worker,
    events: Receiver<Event>,
}
impl MacCore {
    pub fn open(path: PathBuf, cli: Option<PathBuf>) -> Result<Self> {
        let mut config = Config::load(&path)?;
        if let Some(cli) = cli {
            config.codex_path = Some(cli);
        }
        let (worker, events) = Worker::start(config.clone(), || {});
        Ok(Self {
            config,
            path,
            monitor: Monitor::default(),
            worker,
            events,
        })
    }
    pub fn refresh(&mut self) {
        if !self.monitor.refreshing {
            self.monitor.started();
            let _ = self.worker.commands.send(Command::Refresh);
        }
    }
    pub fn configure(&mut self, config: Config) -> Result<()> {
        config.save(&self.path)?;
        let query_changed = config.interval_secs != self.config.interval_secs
            || config.codex_path != self.config.codex_path;
        self.config = config;
        if query_changed {
            self.monitor.started();
            self.worker
                .commands
                .send(Command::Configure(self.config.clone()))
                .context("刷新服务已退出")?;
        }
        Ok(())
    }
    pub fn snapshot(&mut self) -> Value {
        while let Ok(event) = self.events.try_recv() {
            match event {
                Event::Started => self.monitor.started(),
                Event::Success(limits, source) => self.monitor.succeeded(limits, source),
                Event::Failed(failure) => self.monitor.failed(failure),
            }
        }
        let now = Utc::now();
        let model = self.monitor.render_model(now, self.config.interval_secs);
        let (status, kind, suggestion) = match self.monitor.failure {
            Some(Failure::NotInstalled) => (
                Failure::NotInstalled.label(),
                "warning",
                "Install Codex or Codex CLI, then refresh.",
            ),
            Some(Failure::NotAuthenticated) => (
                Failure::NotAuthenticated.label(),
                "warning",
                "Sign in to Codex, then refresh.",
            ),
            Some(Failure::Network) => (
                Failure::Network.label(),
                "warning",
                "Retrying automatically. Last successful values are retained.",
            ),
            Some(Failure::Protocol) => (
                Failure::Protocol.label(),
                "warning",
                "Update Codex, then refresh.",
            ),
            Some(Failure::Timeout) => (
                Failure::Timeout.label(),
                "warning",
                "Retrying automatically. Last successful values are retained.",
            ),
            None if self.monitor.stale(now, self.config.interval_secs) => {
                ("数据过期", "warning", "最近成功值已过期，请刷新。")
            }
            None if self.monitor.limits.is_some() => ("已连接", "success", ""),
            None => ("等待查询", "muted", ""),
        };
        let date = |d: chrono::DateTime<Utc>| {
            d.with_timezone(&Local)
                .format("%m月%d日  %H:%M")
                .to_string()
        };
        let limits = self.monitor.limits.as_ref();
        json!({
            "config": self.config,
            "remaining": model.remaining_percent,
            "percentLabel": model.percent_label,
            "refreshLabel": model.refresh_label,
            "refreshing": self.monitor.refreshing,
            "status": status, "statusKind": kind, "suggestion": suggestion,
            "resetLabel": limits.and_then(|l| l.secondary.resets_at).map(date).unwrap_or_else(|| "接口未提供".into()),
            "sampledLabel": limits.map(|l| date(l.sampled_at)).unwrap_or_else(|| "尚无成功记录".into()),
            "shortLabel": limits.and_then(|l| l.primary.remaining_percent()).map(|p| format!("剩余 {p}%")).unwrap_or_else(|| "接口未提供".into()),
            "details": self.monitor.details(now, self.config.interval_secs),
            "commit": env!("BUILD_COMMIT"), "dirty": env!("BUILD_DIRTY") == "true",
            "version": env!("CARGO_PKG_VERSION"),
        })
    }
}

thread_local! { static ERROR: std::cell::RefCell<String> = const { std::cell::RefCell::new(String::new()) }; }
fn remember(error: impl std::fmt::Display) {
    ERROR.with(|e| *e.borrow_mut() = error.to_string());
}
fn owned_string(value: String) -> *mut c_char {
    CString::new(value).expect("JSON has no NUL").into_raw()
}

/// # Safety
/// `path` must be a valid NUL-terminated UTF-8 path; `cli` must be null or the same.
/// The native host owns the returned handle, serializes calls and releases it once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn quota_open(path: *const c_char, cli: *const c_char) -> *mut MacCore {
    let path = unsafe { CStr::from_ptr(path) }
        .to_string_lossy()
        .into_owned();
    let cli = if cli.is_null() {
        None
    } else {
        Some(PathBuf::from(
            unsafe { CStr::from_ptr(cli) }
                .to_string_lossy()
                .into_owned(),
        ))
    };
    match MacCore::open(path.into(), cli) {
        Ok(core) => Box::into_raw(Box::new(core)),
        Err(error) => {
            remember(error);
            std::ptr::null_mut()
        }
    }
}
#[unsafe(no_mangle)]
pub extern "C" fn quota_error() -> *mut c_char {
    ERROR.with(|e| owned_string(e.borrow().clone()))
}
#[unsafe(no_mangle)]
/// # Safety
/// `value` must be null or a string returned by this module, and must be freed once.
pub unsafe extern "C" fn quota_string_free(value: *mut c_char) {
    if !value.is_null() {
        drop(unsafe { CString::from_raw(value) });
    }
}
#[unsafe(no_mangle)]
/// # Safety
/// `core` must be a live handle returned by `quota_open`, accessed exclusively.
pub unsafe extern "C" fn quota_snapshot(core: *mut MacCore) -> *mut c_char {
    owned_string(unsafe { &mut *core }.snapshot().to_string())
}
#[unsafe(no_mangle)]
/// # Safety
/// `core` must be a live handle returned by `quota_open`, accessed exclusively.
pub unsafe extern "C" fn quota_refresh(core: *mut MacCore) {
    unsafe { &mut *core }.refresh();
}
#[unsafe(no_mangle)]
/// # Safety
/// `core` must be a live exclusive handle; `json` must be a NUL-terminated JSON string.
pub unsafe extern "C" fn quota_configure(core: *mut MacCore, json: *const c_char) -> bool {
    let config = unsafe { CStr::from_ptr(json) }.to_string_lossy();
    match serde_json::from_str::<Config>(&config)
        .map_err(anyhow::Error::from)
        .and_then(|c| unsafe { &mut *core }.configure(c))
    {
        Ok(()) => true,
        Err(error) => {
            remember(error);
            false
        }
    }
}
#[unsafe(no_mangle)]
/// # Safety
/// `core` must be null or a live exclusive handle; release exactly once.
pub unsafe extern "C" fn quota_close(core: *mut MacCore) {
    if !core.is_null() {
        drop(unsafe { Box::from_raw(core) });
    }
}
#[unsafe(no_mangle)]
/// # Safety
/// `output` must be null or point to writable memory of at least `capacity` bytes.
pub unsafe extern "C" fn quota_render(
    remaining: i32,
    scale: u32,
    output: *mut u8,
    capacity: usize,
) -> usize {
    use crate::weekly_quota_render::*;
    let mut model = WeeklyQuotaRenderModel::empty();
    model.remaining_percent = if remaining < 0 {
        None
    } else {
        Some(remaining.min(100) as u8)
    };
    let pixels = render_weekly_quota_base_at_scale(&model, scale as usize);
    if !output.is_null() && capacity >= pixels.len() {
        unsafe {
            std::ptr::copy_nonoverlapping(pixels.as_ptr(), output, pixels.len());
        }
    }
    pixels.len()
}
