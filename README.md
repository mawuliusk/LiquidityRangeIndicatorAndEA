# MQL5

MQL5 Algo Forge / [besolid](https://www.mql5.com/en/users/besolid)

## LiquidityRange

A liquidity-sweep range detector for Deriv volatility indices, being evolved
into a dual-target application:

| Target | Location | Role |
| ------ | -------- | ---- |
| Indicator | `Indicators/Blood/LiquidityRange.mq5` | Draws ranges, sends alerts, manual operation |
| Expert Advisor | `Experts/Blood/LiquidityRangeEA.mq5` | Same signals, plus order execution |
| Shared modules | `Include/Blood/LiquidityRange/` | Detection engine, drawing, notifications, UI panel |

The indicator and the EA are thin shells over the same shared modules, so the
ranges that are drawn are exactly the ranges that are traded. The detection
logic has no indicator buffers and no `iCustom` dependency — it works directly
on `MqlRates[]`, which is what makes the shared-module layout possible.

### Repository scope

This repository intentionally tracks only the LiquidityRange application.
Everything else in the MQL5 data folder (other indicators and experts, terminal
profiles, logs, compiled `.ex5` files) is excluded via `.gitignore`.

```
MQL5/
  .gitignore
  README.md
  REFINEMENTS.md                     <- open work, one item at a time
  Include/
    Blood/
      LiquidityRange/
        UIPanelTypes.mqh
        UIToggleButton.mqh
        UIActionButton.mqh
        UIPersist.mqh
        UITogglePanel.mqh
  Experts/
    Blood/                           <- LiquidityRangeEA.mq5 (pending)
  Indicators/
    Blood/
      LiquidityRange.mq5
```

### Build

`#include <Blood/...>` directives resolve against `MQL5/Include`, so the
indicator and the EA compile from their canonical locations without relative
path gymnastics.
