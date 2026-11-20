# LiquidityRange EA — Strategy Contract

Status: **draft 0.2** · working agreement for the implementation · not yet frozen
Companion document to `REFINEMENTS.md` (code-level backlog).

---

## 1. Scope

One EA (`Experts/Blood/LiquidityRangeEA.mq5`) that:

- reconstructs ranges from history at startup, and tracks them live afterwards;
- detects **entry POIs live only** — never from history;
- sizes, enters, and manages trades;
- keeps the indicator's drawing and alerting functionality, each independently toggleable.

The indicator (`Indicators/Blood/LiquidityRange.mq5`) stays as a standalone program for
discretionary use. Both are thin shells over `Include/Blood/LiquidityRange/`.

---

## 2. Definitions

| Term | Meaning |
| --- | --- |
| **Range POI** | the wick candle that starts a range; its extremes anchor the level system |
| **Entry POI** | a *new* wick+confirmation that forms after the range has grabbed liquidity; defines entry and SL |
| **Grab** | a candle trading beyond the range POI (below `poiLow` for a buy, above `poiHigh` for a sell). Arms the range. |
| **Violation** | a candle **closing** beyond the far border (above the top for a buy, below the bottom for a sell) on the range's own timeframe. Kills the range. |
| **Armed** | the range has grabbed liquidity and is eligible for entries |
| **Window** | `formBars` candles after the grab bar, during which entries are allowed |
| **formBars** | grab bar − range POI bar (the time the range took to grab) |

Wick vs close matters and is deliberately asymmetric:

- a **wick** beyond the POI arms the range (grab);
- a **close** beyond the far border kills it (violation).

---

## 3. Range lifecycle (buy; seller mirrored)

```
        created            armed                        dead
           |                 |                            |
POI -- confirm -- [pending] -- GRAB -- [armed: formBars window] -- end
                    |                                          |
                    +-- close > top --> dead, never armed       +-- close > top --> dead
```

Death conditions (whichever comes first):

1. a close beyond the far border (any time from the confirmation bar onward);
2. window expiry;
3. a winning trade (range retired);
4. 3 attempts used.

Note: a wick crossing the top border does **not** kill the range. Only a close does.
Note: during formation the rule is satisfied automatically — the top border *is* the highest
high between the POI and the confirmation candle.

### Open positions vs violation

A violation kills the **range**, never the **open position**.

- The position keeps its server-side SL/TP and runs to its target — this is what makes
  TP above 100% possible.
- Once that position closes, the range is retired: no further entries from it, even if the
  window is still open and TP was not reached.

---

## 4. Level system (properties of the range, computed once)

`H = top − bottom`

| Level | Buy | Sell | Use |
| --- | --- | --- | --- |
| −25% | `bottom − 0.25H` | `top + 0.25H` | entry-band floor |
| 0% | `bottom` | `top` | range POI extreme |
| 25% | `bottom + 0.25H` | `top − 0.25H` | protective stop after 100% |
| 50% | `bottom + 0.50H` | `top − 0.50H` | entry-band ceiling |
| 75% | `bottom + 0.75H` | `top − 0.75H` | break-even trigger |
| 100% | `top` | `bottom` | far border |
| 125% | `top + 0.25H` | `bottom − 0.25H` | beyond the range |

`0–100%` spans the whole range box. Stored on the range struct as
`neg25, lvl0, lvl25, lvl50, lvl75, lvl100, lvl125` plus `height` and `PriceAt(pct)`.

---

## 5. Entry pipeline (evaluated at bar close, in this order)

1. **Range is armed**, inside its window, not retired, attempts < 3.
2. **Entry POI confirmed** on the same symbol/TF, after the grab. Detection is the same as the
   range POI (wick + close beyond the wick extreme within `InpMaxGapCandles`), with no
   9–13-candle validation and no grab requirement. Entry right after the confirmation close.
3. **Direction lock free** — no live position in that direction on that symbol.
4. **Entry band** — buy: `level(−25) ≤ entry < level(50)`; sell: `level(50) < entry ≤ level(−25)`.
   This is the whole rule. The SL is **not** constrained by the band and may sit below −25%.
5. **SL** — just beyond the entry POI: `entryPOI.low − buffer` (buy) / `entryPOI.high + buffer`
   (sell), then widened to the broker's `SYMBOL_TRADE_STOPS_LEVEL` minimum. Widen only, never narrow.
6. **RR filter** — using the *final* SL, after widening:
   `(TP − entry)/(entry − SL) ≥ InpMinRR` (1.5). If it fails, **skip — no TP extension, no re-entry
   attempt consumed**.
7. **Sizing** — see §6.
8. **Send** — market order with server-side SL and TP; consume one attempt.

`TP = PriceAt(InpTPPercent)` (default 90).

---

## 6. Sizing and risk

- `basis` = balance by default, equity optional via input.
- `riskAmount = basis × InpRiskPercent/100` (default 2%).
- `valuePerLot = tickValue × (priceRisk / tickSize)`; `lots = riskAmount / valuePerLot`.
- Round **down** to the lot step; clamp to min/max lot.
- `realizedRisk = lots × valuePerLot` must be ≤ `InpMaxRealizedRiskPercent` (4%) of basis.
- If even the minimum lot exceeds 4%, **skip the trade**.

---

## 7. Management (per tick, open positions only)

**Break-even** — move SL to entry **only when both** hold:

- price is at or beyond the 75% level, and
- the trade has at least 1:1 RR.

If 1:1 is reached but 75% is not, do nothing.

**TP beyond 100%** — if `level(TP) > level(100)` and price reaches ≥ 100% of the range,
move SL to the 25% level.

- Clamp: never place the SL below entry (buy) / above entry (sell). If the 25% level would be
  worse than break-even, use break-even instead.

All SL/TP live **server-side** on the order. The EA modifies them; it never enforces stops by
watching price.

---

## 8. Arbitration

- **Timeframe priority:** ascending by period, regardless of input order (M2 before M3).
  Only timeframes in `InpTradeTimeframes` are analysed, entered and managed.
- **Direction lock:** while a position is open on symbol+direction, that symbol+direction is
  skipped entirely — no analysis, no entries — from every timeframe. The opposite direction
  remains free.
- **Netting accounts:** detected via `ACCOUNT_MARGIN_MODE`. On netting, the lock covers the whole
  symbol (an opposite order would close the position).
- **Overlap filter:** confirmed ranges filtered per symbol/TF group, strongest wins, as the
  indicator already does.
- **Attempts:** max 3 per range. An SL hit increments failures; 3 failures retire the range.
  A break-even exit consumes an attempt but is not a failure — later attempts remain.
- **Symbols:** only `InpSymbols`. The EA's own chart symbol is not traded unless listed.

---

## 9. Historical vs live

| Step | When | Historical? |
| --- | --- | --- |
| POI → confirmation → range creation | once at init, then bar by bar | **backfilled** |
| Grab / arming / violation | same | **backfilled** |
| Entry POI detection | bars closing **after** EA start | **live only** |
| Entry, sizing, management | live only | **live only** |

Consequences:

- On attach, ranges whose window is still open are tradeable immediately.
- A range whose window closed while the EA was down is simply expired.
- No retroactive entries on historical POIs.
- Strategy Tester behaves identically: "live" is the tester's forward bar processing.

Backfill depth: one-time sweep, `InpBackfillBars` (proposed 2000, as the indicator uses).
**Open item — see §12.**

---

## 10. Persistence and restart

- Persist per range: key (symbol, TF, POI time, POI prices), armed time, window end,
  attempts, failures, retired flag.
- Reconcile open positions by magic number on init (`PositionSelectByTicket` / comment tag).
- Re-derive range state from the backfill, then overlay the persisted counters.
- Entry POIs are only accepted from the current EA start time onward.

---

## 11. Draft inputs

```
InpSymbols                 "Volatility 10 Index,..."     // traded instruments
InpTradeTimeframes         "M2,M3,M5"                    // analysed, entered, managed
InpBackfillBars            2000

InpMinWickRatio            0.05
InpMinRange                0.0
InpMaxGapCandles           5
InpMinConfirmationCandles  9
InpMaxConfirmationCandles  13
InpFilterOverlaps          true
InpOverlapCandles          3

InpTPPercent               90.0
InpMinRR                   1.5
InpSLBufferPoints          0
InpMaxAttemptsPerRange     3

InpRiskPercent             2.0
InpMaxRealizedRiskPercent  4.0
InpRiskBasis               BALANCE | EQUITY
InpMagic                   20261116

InpTradeEnabled            true    // master switch (also a UI toggle)
InpDrawRanges              true
InpSendAlerts              true
```

---

## 12. Open items

1. **Backfill depth** — `InpBackfillBars` (2000) vs a calendar-day lookback per timeframe.
   Explanation sent; user to review and decide.
2. Rules review pass by the user before implementation begins.

---

## 13. Code changes required

- Extract the detector into `Include/Blood/LiquidityRange/LRAnalyzer.mqh` (A1).
- Separate **grab** from **violation** and scan violations from the confirmation bar (fixes B4).
- Arrow marks the **grab** bar, not the first generic break.
- New live state machine (`LRRangeTracker.mqh`), distinct from the indicator's history sweep.
- New trading module (`LRTrading.mqh`), EA-only.
- Per-instance object prefix so the indicator and EA can coexist on one chart (A3).
- Keep `#property indicator_*` strictly in the indicator shell.
