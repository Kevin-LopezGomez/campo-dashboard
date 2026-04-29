# Dashboard Migration Template (IndexedDB + localStorage Compatibility)

## 1) Change Summary
- Dashboard Name:
- File Path:
- Owner:
- Date:
- Scope: Migration to IndexedDB-compatible cache loading without breaking existing localStorage behavior.

## 2) Objective
- Ensure dashboard reads data reliably from IndexedDB-backed cache and legacy/localStorage paths.
- Maintain existing visuals, filters, and KPI logic.
- Prevent regressions during staged rollout.

## 3) Pre-Migration Checklist
- [ ] Confirm canonical storage keys for this dataset.
- [ ] Identify legacy keys still present in production.
- [ ] Confirm update event names used by dashboard listeners.
- [ ] Confirm parser expects canonical sheet names.
- [ ] Capture baseline screenshots (before).
- [ ] Capture baseline row/KPI counts (before).

## 4) Storage Contract
### Canonical Keys
- Data key:
- Ping key:
- Event(s):
- Canonical sheet name(s):

### Legacy Keys (if any)
- Legacy data key(s):
- Legacy ping key(s):
- Migration behavior: copy-if-missing then remove legacy.

## 5) Required Code Pattern
### A. Safe payload loader
- IndexedDB-first read (`idbGetJson`), with localStorage fallback.
- If localStorage contains pointer payload, resolve via IndexedDB.
- If neither exists, return `null` and show waiting state.

### B. IndexedDB self-heal
- `openLocalDbWithStore()` must:
  - open DB at current version,
  - verify required store exists,
  - if missing, reopen with incremented version and create store.

### C. Event wiring
- Listen to:
  - `storage` key updates,
  - postMessage custom events,
  - BroadcastChannel updates,
  - optional polling fallback.

### D. Non-breaking parse behavior
- Do not alter business rules unless explicitly requested.
- Keep column mapping aliases backward-compatible.

## 6) Implementation Steps (Per Dashboard)
1. Add/confirm constants for DB name, store, keys, ping keys, and event names.
2. Add/confirm `openLocalDbWithStore()` and idb read helper.
3. Refactor `load...Payload()` to IndexedDB-first + fallback.
4. Preserve current parse/normalize logic.
5. Verify filter initialization and default state still match current UX.
6. Verify status text and empty/error states.
7. Verify all listeners trigger a re-hydrate.

## 7) Smoke Test Script
### Data Load
- [ ] Dashboard loads rows from latest uploaded data.
- [ ] Status label shows correct source/row count.
- [ ] No console errors.

### Functional
- [ ] Filters return expected results.
- [ ] Table rows and key charts render.
- [ ] Export still works.
- [ ] KPI totals match expected baseline.

### Compatibility
- [ ] Works when only canonical key exists.
- [ ] Works when only legacy key exists.
- [ ] Works when localStorage contains pointer payload.
- [ ] Works after hard refresh.

### Regression
- [ ] No impact to 9 other dashboards.
- [ ] Event updates still propagate from Data Input and index.

## 8) Rollback Plan
- Revert only this dashboard file.
- Keep shared index/input compatibility layer intact.
- Re-run smoke tests and confirm baseline restored.

## 9) Migration Log (Fill per Dashboard)
- Dashboard:
- PR / Commit:
- Keys migrated:
- Listener updates:
- Parser updates:
- Test results:
- Known issues:
- Sign-off:

## 10) 10-Dashboard Tracking Table
| # | Dashboard | File | Status | Owner | Date | Smoke Test | Notes |
|---|-----------|------|--------|-------|------|------------|-------|
| 1 | Data Input Tool | 07.0 Data - Input Tool.html | In progress |  |  |  |  |
| 2 | Unified Index | index.html | In progress |  |  |  |  |
| 3 | Dashboard 3 |  | Pending |  |  |  |  |
| 4 | Dashboard 4 |  | Pending |  |  |  |  |
| 5 | Dashboard 5 |  | Pending |  |  |  |  |
| 6 | Dashboard 6 |  | Pending |  |  |  |  |
| 7 | Dashboard 7 |  | Pending |  |  |  |  |
| 8 | Dashboard 8 |  | Pending |  |  |  |  |
| 9 | Dashboard 9 |  | Pending |  |  |  |  |
|10 | Dashboard 10 |  | Pending |  |  |  |  |

---

## Appendix A: Reusable Loader Pseudocode
```js
async function loadPayload() {
  try {
    const idbPayload = await idbGetJson(DATA_KEY);
    if (idbPayload && idbPayload.sheets) return idbPayload;
  } catch {}

  const raw = (localStorage.getItem(DATA_KEY) || "").trim();
  if (!raw) return null;

  try {
    const parsed = JSON.parse(raw);
    if (parsed?._storage === "indexeddb" && parsed?._idbKey === DATA_KEY) {
      return await idbGetJson(DATA_KEY);
    }
    return parsed;
  } catch {
    return null;
  }
}
```

## Appendix B: Definition of Done
- [ ] Dashboard passes smoke test matrix.
- [ ] No new console errors.
- [ ] Works with canonical + legacy data paths.
- [ ] Event-driven refresh validated.
- [ ] Peer sign-off complete.
