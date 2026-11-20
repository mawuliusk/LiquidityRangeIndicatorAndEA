# LiquidityRange — Refinement & Optimization Backlog

Living checklist. We tackle one item at a time, top to bottom unless re-prioritized.
Line numbers refer to `LiquidityRange.mq5` as of commit `1bf176d`.

The EA's trading rules are specified separately in `docs/EA_STRATEGY.md`
(draft 0.2, pending user review). This file covers the code-level work.

Legend: **P0** = correctness, **P1** = structure/performance, **P2** = polish.
Status: `[ ]` todo · `[~]` in progress · `[x]` done

---

## Done

- [x] **A0. Repository & layout.** Root moved to `MQL5/` with a whitelist `.gitignore` that tracks
      only this application. Shared UI modules live in `Include/Blood/LiquidityRange/`; the
      indicator uses `#include <Blood/LiquidityRange/UITogglePanel.mqh>`. Verified with a clean
      MetaEditor compile (0 errors, 0 warnings). A stale nested repo at `Include/Blood/.git`
      (1 commit, tracking `CustomFunctions.mqh` + `Enums.mqh`) was moved out to a backup, not deleted.

---

## Part A — Architecture: EA + indicator

- [ ] **A1.** Split into shared engine includes + thin indicator shell + thin EA shell.
      Targets: `Indicators/Blood/LiquidityRange.mq5` and `Experts/Blood/LiquidityRangeEA.mq5`,
      both including from `Include/Blood/LiquidityRange/`.
      The indicator logic has **no buffers, no plots, no iCustom** — it is plain functions over
      `MqlRates[]` plus chart objects. That makes extraction cheap and lets both shells run the
      exact same signal code path (no divergence between what is drawn and what is traded).
- [ ] **A2.** Move trade logic into a separate module consumed only by the EA
      (risk, sizing, entries, exits, position management). Indicator must never `#include` it.
- [ ] **A3.** Per-instance object-name prefix. Today `CleanupRanges()` (L1943) deletes every
      object matching `BuyRangeRect_` etc. globally — an indicator and an EA drawing on the same
      chart would wipe each other's rectangles.
- [ ] **A4.** One shared config/flag resolver so the EA's and indicator's toggles resolve
      identically (currently `ui*` mirrors vs `Inp*` inputs are resolved ad hoc).
- [ ] **A5.** Indicator-only / alert-only mode (no trading) must remain first-class, so the
      existing discretionary workflow is preserved after the EA exists.

## Part B — Correctness bugs found in review

- [ ] **B1.** M1 is hard-skipped at L1227 (`if(tf == PERIOD_M1 || tf == PERIOD_CURRENT) continue;`)
      even though `M1` is in the default `InpLTF` and the `(1s)` indices are an obvious target.
      That entire LTF leg is dead code today.
- [ ] **B2.** LTF overlay scan is gated on `uiSendLTFNotifications` (L1244), so the
      "Show LTF Overlays" toggle does nothing on its own. Visual and alert flags must be independent.
- [ ] **B3.** `htfBuyPendingRanges`, `htfSellPendingRanges`, `ltfOverlayPendingRanges` are declared,
      filtered and drawn, but nothing ever appends to them. `InpShowPendingRanges` therefore only
      affects the chart's own timeframe.
- [ ] **B4.** Confirmation and invalidation test the same price. For a buy, `bottomBorder == poiLow`,
      so `FindLiquidityGrab` (`low < poiLow`, from bar 9, L529) and `IsRangeActive`
      (`low < bottomBorder`, from bar 10, L569) are the same event. A "confirmed" range is almost
      always also "inactive" — the two concepts fight each other and `IsRangeActive` is effectively
      not used as a filter. Needs an explicit semantic decision.
      **Resolved (settled):** grab = a *trade* beyond the POI → arms the range; violation = a
      *close* beyond the far border → kills it. Violation scanning must start at the confirmation
      bar. See `docs/EA_STRATEGY.md` §3.
- [ ] **B5.** `InpMaxConfirmationCandles` does not bound the confirmation window (grab search runs to
      end of history, L529); `bestCandles` is always `InpMinConfirmationCandles`, so
      `actualConfCandles` is meaningless.
- [ ] **B6.** `CopyRates(...) < limit` early-returns (L1417, L879) — on a symbol/TF with less history
      than `InpMaxHistoryBars`, the indicator silently draws nothing instead of using what exists.
- [ ] **B7.** `ltfOverlayRanges` is filtered twice, once as buys and once as sells (L1620-1621),
      mixing directions in one "strongest wins" pass.
- [ ] **B8.** `InpMinWickRatio` default is `0.05` while its own comment says `0.1 = 10%` (L77).
      At 5% almost every bar qualifies as a POI, which is why the overlap filter does so much work.
- [ ] **B9.** `GetRangeKey` formats prices with `%.5f` (L238) — precision collisions possible on
      high-precision symbols. Persisted key list grows forever with no pruning/expiry.
- [ ] **B10.** Inconsistent `endTime`: `+PeriodSeconds(tf)` for HTF in the scanner (L939) vs plain
      bar time on the current chart (L1473).
- [ ] **B11.** `IsLowerTF()` (L329) is unused.

## Part C — Performance

- [ ] **C1.** Full rescan of up to 2000 bars × 6 timeframes × 9 symbols on every new bar
      (L2120-2125) — on M1 that is every minute, per chart. Make scanning incremental
      (remember last scanned bar per symbol/timeframe) or cache per-TF results.
- [ ] **C2.** `GetTimeframeCategory()` re-parses `InpHTF`/`InpLTF` on every call (L337) and is called
      per range in the draw path. Precompute the TF→category map once in `OnInit`.
- [ ] **C3.** Two ~700-line near-identical scan blocks (`FindPOIsAndDrawRanges` L1399 and
      `ScanForConfirmations` L869), plus duplicated buy/sell branches — collapse into one function
      taking `isBuy` / a `RangeKind`.
- [ ] **C4.** Replace the per-timeframe `candleSeconds` switch (L728-752) with `PeriodSeconds()`.
- [ ] **C5.** Dedupe/persisted-key lookups are linear scans over unpruned arrays
      (`IsAlreadyNotified`, `IsKeyPersisted`) → indexed/hashed lookup.
- [ ] **C6.** Object churn: delete-all + full redraw each bar → redraw only ranges whose state changed.
- [ ] **C7.** `SendCurrentOpportunitiesNow` clears and rebuilds all state to force a resend; better to
      reuse the normal scan result set with a `force` flag.

## Part D — Trading prerequisites (EA work)

- [ ] **D1.** Explicit signal contract: a `ValidRange`-like struct returned by the engine
      (symbol, TF, direction, borders, POI, confirm time, grab level, state, unique key).
- [ ] **D2.** Risk model: % of balance, lot sizing via tick value / tick size, min/max lot clamps,
      broker stop-level respect.
- [ ] **D3.** Entry rules: one position per `uniqueKey`, entry on confirmation (second sweep) or on
      retest of the zone — decide explicitly, since B4 affects this.
- [ ] **D4.** Exit rules: SL beyond POI (with buffer), TP options (opposite range / fixed RR),
      handling of ranges that become inactive.
- [ ] **D5.** Trade toggles mirroring the UI panel: Trading on/off, max concurrent positions,
      per-symbol whitelist — all switchable at runtime like the existing toggles.
- [ ] **D6.** Backtest harness: single-symbol and multi-symbol tester runs, plus visual-mode check
      that EA drawings match indicator drawings.
