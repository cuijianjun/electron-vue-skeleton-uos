# Tasks: UOS Vue3 + Vite
**Scope**: existing repository in place; sequential implementation and incremental tests authorized 2026-11-13.
**Count**: 26 tasks; US1=6, US2=4, US3=7; setup/foundation=6, closure=3. Status reconciled against quickstart.md evidence.

## Phase 1 — Setup

- [x] T001 Record Git baseline, existing seven-feature behavior and platform/runtime unknowns in specs/001-vue3-upgrade/research.md; inspect original build cleanup/assets/IPC mismatches.
- [x] T002 Pin executable Node/npm and compatible electron-vite/Vite/Vue3/Router4/Vuex4/CJS dependency versions in .nvmrc, package.json and package-lock.json; primary Electron must be supported; preserve gated UOS/ia32 decisions.
- [x] T003 Add test:unit/test:e2e runner commands in package.json and test/unit + test/e2e; encode failing bridge, get-version, cleanup and build-output expectations before migration.

## Phase 2 — Process foundations

- [x] T004 Separate main-only store/menu/window listeners from src/renderer/utils/ipc into src/main/services; main imports no renderer modules; preserve store values including false/0.
- [x] T005 Implement finite named bridge in src/preload/index.js plus src/shared contract and main sender/input guards; main and child windows use sandbox/contextIsolation, no Node integration; test unauthorized sender and payload rejection.
- [x] T006 Replace renderer Node/Electron/store/main-config imports using src/renderer/utils/ipc adapter and scoped metadata; preserve subscription cleanup and async/sync compatibility only for finite existing operations.

## Phase 3 — US1 Vue3/Vite startup

- [x] T007 [P] [US1] Add test/e2e Vue3 route/lifecycle smoke for home, iframe, updateTip, fallback, remount and no renderer Node globals.
- [x] T008 [US1] Create electron.vite.config.mjs and src/renderer/index.html; build CJS main/single-file preload/browser renderer, disjoint dist/electron outputs, alias/style/assets; migrate package.json dev/build commands and remove obsolete webpack dependencies.
- [x] T009 [US1] Migrate src/renderer/main.js, router/index.js and store/index.js to createApp, hash Router4 and Vuex4, preserving application-facing state and routes.
- [x] T010 [US1] Migrate all five src/renderer Vue SFCs, destroy hooks, event removal, directives and runtime metadata reads; tests assert no listener growth after repeated route visits.
- [x] T011 [US1] Migrate env/.env/test.env/production.env loading and renderer-safe keys in electron.vite.config.mjs; update src/main/config/StaticPath.js and window loading for static/splash/relative chunks and dev/test/prod.
- [x] T012 [US1] Run affected unit, build:app and real Electron test/e2e startup/navigation; test dev HMR separately and record observed results in _codex/sessions/vue3-upgrade.md.

## Phase 4 — US2 Desktop feature parity

- [x] T013 [US2] Add deterministic test/unit and test/e2e regressions for all seven mechanisms, get-version IPC mismatch, invalid frame origin/source, malformed payload and repeated update check.
- [x] T014 [US2] Complete src/main/services/ipcMain.js, main/index.js and renderer iframe/menu/store/download call wiring; validate deep links/child URLs and preserve data/false/0 values.
- [x] T015 [US2] Migrate .electron-vue/hot-updater.js to scripts/pack-resources.cjs and repair src/main/services/HotUpdater.js/StaticPath.js: explicit target, renderer-only compatibility/hash/path validation, staged activation and rollback with failure tests.
- [x] T016 [US2] Run combined affected seven-feature test/unit and test/e2e checks against real host Electron and controlled local update fixtures; no production provider calls.

## Phase 5 — US3 Platform packages

- [ ] T017 [US3] Resolve target runtime matrix in research.md and package.json: obtain UOS edition/version/CPU/glibc/session, select supported compatible Electron; unknown rows block target promise only.
- [x] T018 [P] [US3] Add test/unit packaging/full-update negative cases: wrong architecture, missing assets, invalid update metadata, cancellation/permission failure; maintain target results in quickstart.md.
- [x] T019 [US3] Update package.json platform builder profile/output/static/icons and build/shell/postinst.sh, build/shell/prerm.sh desktop/protocol/deb dependencies; protect source assets from clean and use explicit target architecture.
- [x] T020 [US3] Adapt src/main/services/checkupdate.js/download.js/downloadFile.js for pinned updater, reliable cancellation/error/version handling and DEB/package privilege flow; test locally with fixtures.
- [x] T021 [US3] Document matching target npm/Electron/builder caches and clean offline workflow in README.md; lockfile is reproducible, no host node_modules copied between OS/arch.
- [ ] T022 [US3] Build target package with package.json commands on suitable runner; inspect platform/arch/entry/preload/static/protocol metadata and verify package startup without Vite server.
- [ ] T023 [US3] Run real UOS machine installation, first start, window/tray/deep-link/store, resource restart, full A→B upgrade, cancel/failure and uninstall checks; record exact machine/evidence in quickstart.md. Unavailable machine stays blocked.

## Phase 6 — Integrated closure

- [x] T024 Rewrite README.md and quickstart.md for actual Vue3/Vite commands, process bridge, environment, platform/offline/updater behavior and known external gates.
- [x] T025 Run integrated unit/build/Electron regressions and independent full diff/acceptance review; repair blocking findings and rerun affected checks only.
- [x] T026 Reconcile specs/001-vue3-upgrade/tasks.md and _codex/sessions/vue3-upgrade.md: check only evidence-backed completed tasks; preserve external blockers and exact next actions without claiming target approval.

## Dependencies & execution
Default execute in ID order; T004–T006 must precede Vite renderer startup. T017 runtime investigation may advance independently once T001 exists; only dependent target rows wait on external information. [P] means disjoint test files can be prepared independently; this user's execution is sequential.
Each task retains requirements FR-001–FR-009 and contracts/desktop.md. Foundation tasks have security/negative tests; story phases end in executable verification. Shared-core edits require affected downstream checks.
## Requirement coverage
FR-001 → T007/T009/T010/T012; FR-002 → T002/T008/T012; FR-003 → T008/T011/T015/T019; FR-004 → T003–T006/T013/T014; FR-005 → T013/T014/T016; FR-006 → T015/T016/T018; FR-007 → T017–T023; FR-008 → T002/T003/T021/T025; FR-009 → T023/T025/T026.
## Completion rule
No fake completion for target builds or real OS acceptance. Record exact unavailable prerequisite, finish other authorized ready local work, and leave blocked boxes unchecked.

## Final execution evidence — 2026-11-13
23/26 tasks completed. Each local implementation/check phase passed: 22 unit +4 host Electron +1 HMR; test-mode build/startup; production build; ARM64 and amd64 deb builds/metadata/ELF/entry/preload/static/desktop/protocol checks. Final packaged/source compiled files match. Independent review found no remaining code blocker.
- T017 blocked: target UOS edition/version, CPU, glibc and display session not provided (user explicitly deferred confirmation).
- T022 partially executed: both deb candidates built/inspected; actual UOS package startup needs the target machine.
- T023 blocked: real UOS install, tray/window/protocol/store/resource restart, DEB A→B, privilege cancellation/failure and uninstall need that machine.
These three boxes remain unchecked; cross-build/host evidence is not UOS acceptance. See quickstart.md.
