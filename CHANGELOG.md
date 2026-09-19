# Changelog

## 3.0.0 — 2026-09-19
* Fix: `LXRCore.PlayerData` stays current — the core object comes back as a copy, so cash, job and metadata never changed after login in this resource. It now listens to `lxr:client:data` / `lxr:client:unloaded` and refreshes its copy.
* LXRCore v3 release line: every resource ships as 3.0.0 from here (the entries below are the road to it).

## 3.0.0 — 2026-09-18

Rebuilt on the LXRCore v3 native API (repository renamed from lxr-management). Nothing of the earlier build remains.

* One ledger for every registry job: staff on and off line, hire at the desk, promote, demote, let go — all gated by grade permissions
* The society book through lxr-bank, the wage bill from the registry
* Ledger page on the LXR UI Kit, locales EN / KA, offline tests
