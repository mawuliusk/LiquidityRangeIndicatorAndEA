//+------------------------------------------------------------------+
//|                                              LiquidityRange.mq5  |
//|                           Copyright 2026, Mawuli Kwame Mensah    |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

// Include UI module (shared, canonical location: MQL5/Include/Blood/LiquidityRange)
#include <Blood/LiquidityRange/UITogglePanel.mqh>

//+------------------------------------------------------------------+
//| Helper Functions for Timeframe Conversion                        |
//+------------------------------------------------------------------+
string GetPeriodCode(int period)
{
   switch(period)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";
      case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";
      case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";
      case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";
      case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";
      case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";
      case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";
      case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
      default:         return "M1";
   }
}

ENUM_TIMEFRAMES GetPeriodValue(string code)
{
   if(code == "M1")  return PERIOD_M1;
   if(code == "M2")  return PERIOD_M2;
   if(code == "M3")  return PERIOD_M3;
   if(code == "M4")  return PERIOD_M4;
   if(code == "M5")  return PERIOD_M5;
   if(code == "M6")  return PERIOD_M6;
   if(code == "M10") return PERIOD_M10;
   if(code == "M12") return PERIOD_M12;
   if(code == "M15") return PERIOD_M15;
   if(code == "M20") return PERIOD_M20;
   if(code == "M30") return PERIOD_M30;
   if(code == "H1")  return PERIOD_H1;
   if(code == "H2")  return PERIOD_H2;
   if(code == "H3")  return PERIOD_H3;
   if(code == "H4")  return PERIOD_H4;
   if(code == "H6")  return PERIOD_H6;
   if(code == "H8")  return PERIOD_H8;
   if(code == "H12") return PERIOD_H12;
   if(code == "D1")  return PERIOD_D1;
   if(code == "W1")  return PERIOD_W1;
   if(code == "MN1") return PERIOD_MN1;
   return PERIOD_M1;
}

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input double   InpMinWickRatio = 0.05;           // Minimum wick ratio (0.1 = 10%)
input double   InpMinRange = 0.0;               // Minimum candle range in points
input int      InpMaxGapCandles = 5;            // Max candles between wick and confirmation (default 5)
input int      InpMinConfirmationCandles = 9;   // Minimum candles after POI to validate range
input int      InpMaxConfirmationCandles = 13;  // Maximum candles after POI to define range borders
input bool     InpFilterOverlaps = true;        // Filter overlapping ranges (true = keep strongest)
input int      InpOverlapCandles = 3;           // Max candle overlap allowed when filtering (0 = strict)
input bool     InpShowPendingRanges = true;     // Show pending ranges (unconfirmed) - default true
input bool     InpShowLTFOverlays = true;       // Show LTF overlay ranges (grey color)
input int      InpMaxHistoryBars = 2000;        // Maximum bars to scan (performance)
input int      InpLookbackCandles = 5;          // Number of candles to look back for confirmations
input color    InpBuyRangeColor = clrDodgerBlue; // Buy range color
input color    InpSellRangeColor = clrCrimson;   // Sell range color
input color    InpPaleBuyColor = clrSkyBlue;     // Pale Buy color (HTF overlay)
input color    InpPaleSellColor = clrLightPink;  // Pale Sell color (HTF overlay)
input color    InpLTFOverlayColor = clrGray;     // LTF overlay color (neutral grey)
input bool     InpShowBuyRanges = true;          // Show buy ranges
input bool     InpShowSellRanges = true;         // Show sell ranges

//+------------------------------------------------------------------+
//| Configuration for symbols and timeframes                         |
//+------------------------------------------------------------------+
input string  InpSymbols = "Volatility 10 Index,Volatility 10 (1s) Index,Volatility 25 (1s) Index,Volatility 25 Index,Volatility 30 Index,Volatility 30 (1s) Index,Volatility 50 Index,Volatility 50 (1s) Index"; // Symbols to scan (comma separated)

//+------------------------------------------------------------------+
//| Higher Timeframes (HTF) and Lower Timeframes (LTF)              |
//+------------------------------------------------------------------+
input string  InpHTF = "H4,H2,H1,M30,M15,M10";      // Higher Timeframes (comma separated)
input bool    InpSendHTFNotifications = true;    // Send notifications for HTF ranges

input string  InpLTF = "M5,M3,M2,M1";            // Lower Timeframes (comma separated)
input bool    InpSendLTFNotifications = false;   // Send notifications for LTF ranges


//+------------------------------------------------------------------+
//| Runtime mirror variables (changeable via UI buttons)             |
//+------------------------------------------------------------------+
bool   uiFilterOverlaps       = InpFilterOverlaps;
bool   uiShowPendingRanges    = InpShowPendingRanges;
bool   uiShowLTFOverlays      = InpShowLTFOverlays;
bool   uiSendHTFNotifications = InpSendHTFNotifications;
bool   uiSendLTFNotifications = InpSendLTFNotifications;
bool   uiShowBuyRanges        = InpShowBuyRanges;
bool   uiShowSellRanges       = InpShowSellRanges;

//+------------------------------------------------------------------+
//| UI Panel                                                         |
//+------------------------------------------------------------------+
CTogglePanel g_uiPanel;
int g_btnIdxShowPending  = -1;
int g_btnIdxShowLTF      = -1;
int g_btnIdxSendHTF      = -1;
int g_btnIdxSendLTF      = -1;
int g_btnIdxFilterOver   = -1;
int g_btnIdxShowBuy      = -1;
int g_btnIdxShowSell     = -1;

//+------------------------------------------------------------------+
//| Initialize the LiquidityRange UI toggle panel                    |
//+------------------------------------------------------------------+
void InitUIPanel()
{
   if(!g_uiPanel.Create("LR_CTRL", 10, 20, UI_PANEL_WIDTH, "LIQUIDITY RANGE", false))
   {
      Print("Failed to create LiquidityRange UI panel");
      return;
   }

   // Action button (grey) — sits above all toggles
   g_uiPanel.AddActionButton("send_now", "SEND NOW");

   g_btnIdxShowPending = g_uiPanel.AddToggle("show_pending",  "Show Pending",       InpShowPendingRanges);
   g_btnIdxShowLTF     = g_uiPanel.AddToggle("show_ltf",      "Show LTF Overlays", InpShowLTFOverlays);
   g_btnIdxSendHTF     = g_uiPanel.AddToggle("send_htf",      "Send HTF Alerts",   InpSendHTFNotifications);
   g_btnIdxSendLTF     = g_uiPanel.AddToggle("send_ltf",      "Send LTF Alerts",   InpSendLTFNotifications);
   g_btnIdxShowBuy     = g_uiPanel.AddToggle("show_buy",      "Show Buy Ranges",   InpShowBuyRanges);
   g_btnIdxShowSell    = g_uiPanel.AddToggle("show_sell",     "Show Sell Ranges",  InpShowSellRanges);
   g_btnIdxFilterOver  = g_uiPanel.AddToggle("filter_over",   "Filter Overlaps",   InpFilterOverlaps);

   // Global (symbol-agnostic) persistence — same state everywhere
   g_uiPanel.EnablePersistence("LiquidityRange");
   g_uiPanel.LoadStates();
   SyncUIFlagsFromPanel();

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Sync runtime mirrors from UI button states                       |
//+------------------------------------------------------------------+
void SyncUIFlagsFromPanel()
{
   uiShowPendingRanges    = g_uiPanel.GetState(g_btnIdxShowPending);
   uiShowLTFOverlays      = g_uiPanel.GetState(g_btnIdxShowLTF);
   uiSendHTFNotifications = g_uiPanel.GetState(g_btnIdxSendHTF);
   uiSendLTFNotifications = g_uiPanel.GetState(g_btnIdxSendLTF);
   uiFilterOverlaps       = g_uiPanel.GetState(g_btnIdxFilterOver);
   uiShowBuyRanges        = g_uiPanel.GetState(g_btnIdxShowBuy);
   uiShowSellRanges       = g_uiPanel.GetState(g_btnIdxShowSell);
}

//+------------------------------------------------------------------+
//| Structure to store POI data                                      |
//+------------------------------------------------------------------+
struct ValidRange
{
   datetime startTime;
   datetime endTime;
   double   topBorder;
   double   bottomBorder;
   bool     isBuy;
   int      startIndex;
   int      confirmIndex;
   int      endIndex;
   int      actualConfCandles;
   double   liquidityLevel;
   bool     isConfirmed;
   bool     isActive;
   double   poiHigh;
   double   poiLow;
   bool     notificationSent;
   string   uniqueKey;
   string   symbol;
   string   timeframe;
};

// Current chart info
string currentSymbol;
string currentTFStr;
ENUM_TIMEFRAMES currentTFEnum;

// Notified ranges tracking
ValidRange notifiedRanges[];
int notifiedCount = 0;

// Persistent notified keys (global — shared across all symbols)
string g_notifiedKeys[];
int    g_notifiedKeysCount = 0;

// Arrays to collect HTF ranges for drawing (pale blue/pink)
ValidRange htfBuyRanges[], htfSellRanges[];
ValidRange htfBuyPendingRanges[], htfSellPendingRanges[];
int htfBuyCount = 0, htfSellCount = 0;
int htfBuyPendingCount = 0, htfSellPendingCount = 0;

// Arrays for LTF overlays (grey color)
ValidRange ltfOverlayRanges[];
ValidRange ltfOverlayPendingRanges[];
int ltfOverlayCount = 0, ltfOverlayPendingCount = 0;

// Store last sent notification for each asset to prevent duplicates (in-memory)
string lastNotificationSymbols[];
string lastNotificationMessages[];
int lastNotificationCount = 0;

//+------------------------------------------------------------------+
//| Generate unique key for a range                                  |
//+------------------------------------------------------------------+
string GetRangeKey(ValidRange &range)
{
   string type = range.isBuy ? "BUY" : "SELL";
   return StringFormat("%s_%s_%s_%I64d_%.5f_%.5f", 
                       type,
                       range.symbol,
                       range.timeframe,
                       (long)range.startTime,
                       range.poiLow,
                       range.poiHigh);
}

//+------------------------------------------------------------------+
//| Check if a range has already been notified (in-memory)           |
//+------------------------------------------------------------------+
bool IsAlreadyNotified(string key)
{
   for(int i = 0; i < notifiedCount; i++)
   {
      if(notifiedRanges[i].uniqueKey == key)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if a key is in the persistent notified list                |
//+------------------------------------------------------------------+
bool IsKeyPersisted(const string key)
{
   for(int i = 0; i < g_notifiedKeysCount; i++)
   {
      if(g_notifiedKeys[i] == key)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Add a key to the persistent notified list (dedup)                |
//+------------------------------------------------------------------+
void AddPersistedKey(const string key)
{
   if(IsKeyPersisted(key)) return;

   ArrayResize(g_notifiedKeys, g_notifiedKeysCount + 1);
   g_notifiedKeys[g_notifiedKeysCount] = key;
   g_notifiedKeysCount++;
}

//+------------------------------------------------------------------+
//| Save persisted keys to disk (single global file)                 |
//+------------------------------------------------------------------+
void SavePersistedKeys()
{
   UIPersist_SaveStringList("Notified", g_notifiedKeys);
}

//+------------------------------------------------------------------+
//| Load persisted keys from disk (single global file)               |
//+------------------------------------------------------------------+
void LoadPersistedKeys()
{
   UIPersist_LoadStringList("Notified", g_notifiedKeys);
   g_notifiedKeysCount = ArraySize(g_notifiedKeys);
}

//+------------------------------------------------------------------+
//| Mark a range as notified                                         |
//+------------------------------------------------------------------+
void MarkAsNotified(ValidRange &range)
{
   range.uniqueKey = GetRangeKey(range);
   range.notificationSent = true;
   
   if(IsAlreadyNotified(range.uniqueKey))
      return;
   
   ArrayResize(notifiedRanges, notifiedCount + 1);
   notifiedRanges[notifiedCount] = range;
   notifiedCount++;
}

//+------------------------------------------------------------------+
//| Check if a timeframe is higher than current                      |
//+------------------------------------------------------------------+
bool IsHigherTF(ENUM_TIMEFRAMES tf)
{
   return (tf > currentTFEnum);
}

//+------------------------------------------------------------------+
//| Check if a timeframe is lower than current                       |
//+------------------------------------------------------------------+
bool IsLowerTF(ENUM_TIMEFRAMES tf)
{
   return (tf < currentTFEnum);
}

//+------------------------------------------------------------------+
//| Get timeframe category (HTF or LTF) from input strings          |
//+------------------------------------------------------------------+
int GetTimeframeCategory(string tfStr)
{
   string htfArray[];
   ParseTimeframes(InpHTF, htfArray);
   for(int i = 0; i < ArraySize(htfArray); i++)
   {
      if(htfArray[i] == tfStr)
         return 1;
   }
   
   string ltfArray[];
   ParseTimeframes(InpLTF, ltfArray);
   for(int i = 0; i < ArraySize(ltfArray); i++)
   {
      if(ltfArray[i] == tfStr)
         return 2;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Custom Wick Detection Function                                   |
//+------------------------------------------------------------------+
bool HasWick(int shift, double minWickRatio, double minRange, MqlRates &data[])
{
   if(shift < 0 || shift >= ArraySize(data)) return false;
   
   double open  = data[shift].open;
   double close = data[shift].close;
   double high  = data[shift].high;
   double low   = data[shift].low;
   
   if(high == low) return false;
   
   double range = high - low;
   if(minRange > 0 && range < minRange) return false;
   
   double upperWick = high - MathMax(open, close);
   double lowerWick = MathMin(open, close) - low;
   
   return (upperWick >= minWickRatio * range) || (lowerWick >= minWickRatio * range);
}

//+------------------------------------------------------------------+
//| Find Bullish Confirmation                                        |
//+------------------------------------------------------------------+
int FindBullishConfirmation(int wickIndex, int maxGap, double &poiHigh, double &poiLow, MqlRates &data[])
{
   if(wickIndex < 0 || wickIndex >= ArraySize(data)) return -1;
   
   poiHigh = data[wickIndex].high;
   poiLow = data[wickIndex].low;
   double wickLow = data[wickIndex].low;
   double wickHigh = data[wickIndex].high;
   
   for(int gap = 1; gap <= maxGap + 1; gap++)
   {
      int confirmIndex = wickIndex - gap;
      if(confirmIndex < 0 || confirmIndex >= ArraySize(data)) break;
      
      if(data[confirmIndex].high > poiHigh)
         poiHigh = data[confirmIndex].high;
      if(data[confirmIndex].low < poiLow)
         poiLow = data[confirmIndex].low;
      
      if(data[confirmIndex].close < wickLow)
         return -1;
      
      if(data[confirmIndex].close > wickHigh)
         return confirmIndex;
   }
   
   return -1;
}

//+------------------------------------------------------------------+
//| Find Bearish Confirmation                                        |
//+------------------------------------------------------------------+
int FindBearishConfirmation(int wickIndex, int maxGap, double &poiHigh, double &poiLow, MqlRates &data[])
{
   if(wickIndex < 0 || wickIndex >= ArraySize(data)) return -1;
   
   poiHigh = data[wickIndex].high;
   poiLow = data[wickIndex].low;
   double wickLow = data[wickIndex].low;
   double wickHigh = data[wickIndex].high;
   
   for(int gap = 1; gap <= maxGap + 1; gap++)
   {
      int confirmIndex = wickIndex - gap;
      if(confirmIndex < 0 || confirmIndex >= ArraySize(data)) break;
      
      if(data[confirmIndex].high > poiHigh)
         poiHigh = data[confirmIndex].high;
      if(data[confirmIndex].low < poiLow)
         poiLow = data[confirmIndex].low;
      
      if(data[confirmIndex].close > wickHigh)
         return -1;
      
      if(data[confirmIndex].close < wickLow)
         return confirmIndex;
   }
   
   return -1;
}

//+------------------------------------------------------------------+
//| Calculate Range Borders                                          |
//+------------------------------------------------------------------+
void CalculateRangeBorders(int wickIndex, int confirmIndex, int maxCandles, 
                           bool isBuy, double &topBorder, double &bottomBorder,
                           double poiHigh, double poiLow, MqlRates &data[])
{
   if(wickIndex < 0 || wickIndex >= ArraySize(data) || confirmIndex < 0 || confirmIndex >= ArraySize(data))
      return;
   
   if(isBuy)
   {
      bottomBorder = poiLow;
      topBorder = poiHigh;
      
      for(int i = 1; i <= maxCandles; i++)
      {
         int shift = confirmIndex - i;
         if(shift < 0 || shift >= ArraySize(data)) break;
         if(shift >= wickIndex) continue;
         
         if(data[shift].high > topBorder)
            topBorder = data[shift].high;
      }
   }
   else
   {
      topBorder = poiHigh;
      bottomBorder = poiLow;
      
      for(int i = 1; i <= maxCandles; i++)
      {
         int shift = confirmIndex - i;
         if(shift < 0 || shift >= ArraySize(data)) break;
         if(shift >= wickIndex) continue;
         
         if(data[shift].low < bottomBorder)
            bottomBorder = data[shift].low;
      }
   }
}

//+------------------------------------------------------------------+
//| Validate Candles Respect POI                                     |
//+------------------------------------------------------------------+
bool ValidateCandlesRespectPOI(int wickIndex, int confirmIndex, int minCandles, 
                               bool isBuy, double poiLow, double poiHigh, MqlRates &data[])
{
   if(wickIndex < 0 || wickIndex >= ArraySize(data) || confirmIndex < 0 || confirmIndex >= ArraySize(data))
      return false;
   
   for(int i = 1; i <= minCandles; i++)
   {
      int shift = confirmIndex - i;
      if(shift < 0 || shift >= ArraySize(data)) return false;
      if(shift >= wickIndex) continue;
      
      if(isBuy)
      {
         if(data[shift].low < poiLow)
            return false;
      }
      else
      {
         if(data[shift].high > poiHigh)
            return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Find Liquidity Grab                                              |
//+------------------------------------------------------------------+
int FindLiquidityGrab(int wickIndex, int confirmIndex, int minCandles, 
                      bool isBuy, double &liquidityLevel, double poiLow, double poiHigh, MqlRates &data[])
{
   int dataSize = ArraySize(data);
   if(dataSize == 0) return -1;
   
   if(wickIndex < 0 || wickIndex >= dataSize || confirmIndex < 0 || confirmIndex >= dataSize)
      return -1;
   
   for(int i = minCandles; i < dataSize; i++)
   {
      int shift = confirmIndex - i;
      if(shift < 0 || shift >= dataSize) continue;
      if(shift >= wickIndex) continue;
      
      if(isBuy)
      {
         if(data[shift].low < poiLow)
         {
            liquidityLevel = poiLow;
            return i;
         }
      }
      else
      {
         if(data[shift].high > poiHigh)
         {
            liquidityLevel = poiHigh;
            return i;
         }
      }
   }
   
   return -1;
}

//+------------------------------------------------------------------+
//| Check if range is still active                                   |
//+------------------------------------------------------------------+
bool IsRangeActive(int confirmIndex, int minCandles, bool isBuy,
                   double topBorder, double bottomBorder, int &breakoutIndex,
                   int wickIndex, MqlRates &data[])
{
   int dataSize = ArraySize(data);
   if(dataSize == 0) return true;
   
   if(confirmIndex < 0 || confirmIndex >= dataSize) return true;
   if(minCandles < 0) minCandles = 0;
   
   for(int i = minCandles + 1; i < dataSize; i++)
   {
      int shift = confirmIndex - i;
      if(shift < 0 || shift >= dataSize) continue;
      if(shift >= wickIndex) continue;
      
      double candleClose = data[shift].close;
      double candleHigh = data[shift].high;
      double candleLow = data[shift].low;
      
      if(isBuy)
      {
         if(candleClose > topBorder)
         {
            breakoutIndex = shift;
            return false;
         }
         
         if(candleLow < bottomBorder)
         {
            breakoutIndex = shift;
            return false;
         }
      }
      else
      {
         if(candleClose < bottomBorder)
         {
            breakoutIndex = shift;
            return false;
         }
         
         if(candleHigh > topBorder)
         {
            breakoutIndex = shift;
            return false;
         }
      }
   }
   
   breakoutIndex = -1;
   return true;
}

//+------------------------------------------------------------------+
//| Try Find Valid Range                                             |
//+------------------------------------------------------------------+
bool TryFindValidRange(int wickIndex, int confirmIndex, bool isBuy,
                       int minCandles, int maxCandles,
                       double &topBorder, double &bottomBorder,
                       int &bestCandles, double &liquidityLevel,
                       int &breakoutIndex, bool &isConfirmed,
                       double &poiHigh, double &poiLow, MqlRates &data[])
{
   if(!ValidateCandlesRespectPOI(wickIndex, confirmIndex, minCandles, isBuy, poiLow, poiHigh, data))
      return false;
   
   double tempTop = 0, tempBottom = 0;
   CalculateRangeBorders(wickIndex, confirmIndex, maxCandles, isBuy, tempTop, tempBottom, poiHigh, poiLow, data);
   
   int grabIndex = FindLiquidityGrab(wickIndex, confirmIndex, minCandles, isBuy, liquidityLevel, poiLow, poiHigh, data);
   
   int tempBreakout = -1;
   bool isActive = IsRangeActive(confirmIndex, minCandles, isBuy, tempTop, tempBottom, tempBreakout, wickIndex, data);
   
   if(!isActive && tempBreakout >= 0)
   {
      if(isBuy && data[tempBreakout].close > tempTop)
         return false;
      if(!isBuy && data[tempBreakout].close < tempBottom)
         return false;
   }
   
   topBorder = tempTop;
   bottomBorder = tempBottom;
   bestCandles = minCandles;
   
   if(grabIndex >= 0)
   {
      isConfirmed = true;
      breakoutIndex = tempBreakout;
      return true;
   }
   else
   {
      isConfirmed = false;
      breakoutIndex = -1;
      return true;
   }
}

//+------------------------------------------------------------------+
//| Filter Overlapping Ranges - grouped by timeframe                 |
//+------------------------------------------------------------------+
void FilterOverlappingRangesGrouped(ValidRange &ranges[], int &count, bool isBuy)
{
   if(count <= 1 || !uiFilterOverlaps) return;
   
   int originalIndices[];
   ArrayResize(originalIndices, count);
   for(int i = 0; i < count; i++)
      originalIndices[i] = i;
   
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = i + 1; j < count; j++)
      {
         int idx1 = originalIndices[i];
         int idx2 = originalIndices[j];
         
         int cmp = StringCompare(ranges[idx1].timeframe, ranges[idx2].timeframe);
         if(cmp > 0 || (cmp == 0 && ranges[idx1].startTime > ranges[idx2].startTime))
         {
            int temp = originalIndices[i];
            originalIndices[i] = originalIndices[j];
            originalIndices[j] = temp;
         }
      }
   }
   
   bool toKeep[];
   ArrayResize(toKeep, count);
   ArrayInitialize(toKeep, true);
   
   int i = 0;
   while(i < count)
   {
      string currentTF = ranges[originalIndices[i]].timeframe;
      int groupStart = i;
      
      while(i < count && ranges[originalIndices[i]].timeframe == currentTF)
         i++;
      int groupEnd = i;
      
      if(groupEnd - groupStart <= 1)
         continue;
      
      for(int a = groupStart; a < groupEnd; a++)
      {
         int idxA = originalIndices[a];
         if(!toKeep[idxA]) continue;
         
         for(int b = a + 1; b < groupEnd; b++)
         {
            int idxB = originalIndices[b];
            if(!toKeep[idxB]) continue;
            
            datetime iStart = ranges[idxA].startTime;
            datetime iEnd = ranges[idxA].endTime;
            datetime jStart = ranges[idxB].startTime;
            datetime jEnd = ranges[idxB].endTime;
            
            int overlapCandles = InpOverlapCandles;
            datetime overlapTime = 0;
            
            if(overlapCandles > 0)
            {
               ENUM_TIMEFRAMES tf = Period();
               int candleSeconds = 0;
               switch(tf)
               {
                  case PERIOD_M1:  candleSeconds = 60; break;
                  case PERIOD_M2:  candleSeconds = 120; break;
                  case PERIOD_M3:  candleSeconds = 180; break;
                  case PERIOD_M4:  candleSeconds = 240; break;
                  case PERIOD_M5:  candleSeconds = 300; break;
                  case PERIOD_M6:  candleSeconds = 360; break;
                  case PERIOD_M10: candleSeconds = 600; break;
                  case PERIOD_M12: candleSeconds = 720; break;
                  case PERIOD_M15: candleSeconds = 900; break;
                  case PERIOD_M20: candleSeconds = 1200; break;
                  case PERIOD_M30: candleSeconds = 1800; break;
                  case PERIOD_H1:  candleSeconds = 3600; break;
                  case PERIOD_H2:  candleSeconds = 7200; break;
                  case PERIOD_H3:  candleSeconds = 10800; break;
                  case PERIOD_H4:  candleSeconds = 14400; break;
                  case PERIOD_H6:  candleSeconds = 21600; break;
                  case PERIOD_H8:  candleSeconds = 28800; break;
                  case PERIOD_H12: candleSeconds = 43200; break;
                  case PERIOD_D1:  candleSeconds = 86400; break;
                  case PERIOD_W1:  candleSeconds = 604800; break;
                  case PERIOD_MN1: candleSeconds = 2592000; break;
                  default: candleSeconds = 60; break;
               }
               overlapTime = overlapCandles * candleSeconds;
            }
            
            bool overlap = false;
            if(iEnd >= jStart && jEnd >= iStart)
            {
               datetime overlapStart = MathMax(iStart, jStart);
               datetime overlapEnd = MathMin(iEnd, jEnd);
               datetime overlapDuration = overlapEnd - overlapStart;
               
               if(overlapDuration > overlapTime)
                  overlap = true;
            }
            
            if(overlap)
            {
               if(isBuy)
               {
                  if(ranges[idxA].bottomBorder <= ranges[idxB].bottomBorder)
                     toKeep[idxB] = false;
                  else
                     toKeep[idxA] = false;
               }
               else
               {
                  if(ranges[idxA].topBorder >= ranges[idxB].topBorder)
                     toKeep[idxB] = false;
                  else
                     toKeep[idxA] = false;
               }
            }
         }
      }
   }
   
   int newCount = 0;
   for(int i = 0; i < count; i++)
   {
      if(toKeep[i])
      {
         if(newCount != i)
            ranges[newCount] = ranges[i];
         newCount++;
      }
   }
   count = newCount;
}

//+------------------------------------------------------------------+
//| Send push notification                                           |
//+------------------------------------------------------------------+
void SendNotification(string symbol, string buyTimeframes, string sellTimeframes, int total)
{
   if(total <= 0) return;
   
   string message = symbol + "\n";
   message += "-----------------------------------------------\n";
   
   if(StringLen(buyTimeframes) > 0)
      message += "🔵 BUY: " + buyTimeframes + "\n";
   
   if(StringLen(sellTimeframes) > 0)
      message += "🔴 SELL: " + sellTimeframes + "\n";
   
   message += "💡 Total: " + IntegerToString(total);
   
   bool alreadySent = false;
   for(int i = 0; i < lastNotificationCount; i++)
   {
      if(lastNotificationSymbols[i] == symbol && lastNotificationMessages[i] == message)
      {
         alreadySent = true;
         break;
      }
   }
   
   if(alreadySent)
   {
      Print("Skipping duplicate notification for: ", symbol);
      return;
   }
   
   if(SendNotification(message))
   {
      Print("Notification sent: ", message);
      
      int idx = -1;
      for(int i = 0; i < lastNotificationCount; i++)
      {
         if(lastNotificationSymbols[i] == symbol)
         {
            idx = i;
            break;
         }
      }
      
      if(idx == -1)
      {
         ArrayResize(lastNotificationSymbols, lastNotificationCount + 1);
         ArrayResize(lastNotificationMessages, lastNotificationCount + 1);
         idx = lastNotificationCount;
         lastNotificationCount++;
      }
      
      lastNotificationSymbols[idx] = symbol;
      lastNotificationMessages[idx] = message;
   }
   else
   {
      Print("Failed to send notification: ", message);
   }
}

//+------------------------------------------------------------------+
//| Scan a symbol/timeframe for confirmations                        |
//+------------------------------------------------------------------+
void ScanForConfirmations(string symbol, ENUM_TIMEFRAMES tf, string tfStr, int lookbackCandles, 
                          bool isCurrentSymbol = false)
{
   int totalBars = Bars(symbol, tf);
   int limit = MathMin(InpMaxHistoryBars, totalBars);
   
   if(limit < InpMaxConfirmationCandles + InpMaxGapCandles + 20)
      return;
   
   MqlRates data[];
   if(CopyRates(symbol, tf, 0, limit, data) < limit)
      return;
   
   ArraySetAsSeries(data, true);
   
   int maxScanCandles = lookbackCandles + InpMaxConfirmationCandles + InpMaxGapCandles + 10;
   int startBar = MathMin(maxScanCandles, limit - 1);
   if(startBar < 0) startBar = 0;
   
   MqlRates currentCandle = data[0];
   
   for(int i = startBar; i >= 0; i--)
   {
      if(!HasWick(i, InpMinWickRatio, InpMinRange, data))
         continue;
      
      // Check BUY POI
      if(uiShowBuyRanges)
      {
         double poiHigh = 0, poiLow = 0;
         int confirmIndex = FindBullishConfirmation(i, InpMaxGapCandles, poiHigh, poiLow, data);
         if(confirmIndex != -1)
         {
            double topBorder = 0, bottomBorder = 0;
            int bestCandles = 0;
            double liquidityLevel = 0;
            int breakoutIndex = -1;
            bool isConfirmed = false;
            
            if(TryFindValidRange(i, confirmIndex, true, 
                                 InpMinConfirmationCandles, InpMaxConfirmationCandles,
                                 topBorder, bottomBorder, bestCandles, liquidityLevel,
                                 breakoutIndex, isConfirmed, poiHigh, poiLow, data))
            {
               if(isConfirmed)
               {
                  ValidRange range;
                  range.startTime = data[i].time;
                  range.startIndex = i;
                  range.confirmIndex = confirmIndex;
                  range.topBorder = topBorder;
                  range.bottomBorder = bottomBorder;
                  range.isBuy = true;
                  range.actualConfCandles = bestCandles;
                  range.liquidityLevel = liquidityLevel;
                  range.isConfirmed = isConfirmed;
                  range.poiHigh = poiHigh;
                  range.poiLow = poiLow;
                  range.notificationSent = false;
                  range.uniqueKey = "";
                  range.symbol = symbol;
                  range.timeframe = tfStr;
                  
                  if(breakoutIndex >= 0)
                  {
                     range.endIndex = breakoutIndex;
                     
                     if(IsHigherTF(tf))
                     {
                        int candleSeconds = PeriodSeconds(tf);
                        range.endTime = data[breakoutIndex].time + candleSeconds;
                     }
                     else
                     {
                        range.endTime = data[breakoutIndex].time;
                     }
                     range.isActive = false;
                  }
                  else
                  {
                     range.endIndex = -1;
                     range.endTime = data[0].time;
                     range.isActive = true;
                  }
                  
                  bool isHigher = IsHigherTF(tf);
                  
                  if(isCurrentSymbol && isHigher)
                  {
                     int category = GetTimeframeCategory(tfStr);
                     
                     if(category == 1)
                     {
                        if(range.isBuy)
                        {
                           ArrayResize(htfBuyRanges, htfBuyCount + 1);
                           htfBuyRanges[htfBuyCount] = range;
                           htfBuyCount++;
                        }
                        else
                        {
                           ArrayResize(htfSellRanges, htfSellCount + 1);
                           htfSellRanges[htfSellCount] = range;
                           htfSellCount++;
                        }
                     }
                     else if(category == 2 && uiShowLTFOverlays)
                     {
                        if(range.isBuy)
                        {
                           ArrayResize(ltfOverlayRanges, ltfOverlayCount + 1);
                           ltfOverlayRanges[ltfOverlayCount] = range;
                           ltfOverlayCount++;
                        }
                        else
                        {
                           ArrayResize(ltfOverlayRanges, ltfOverlayCount + 1);
                           ltfOverlayRanges[ltfOverlayCount] = range;
                           ltfOverlayCount++;
                        }
                     }
                  }
                  
                  if(range.isConfirmed && range.endIndex >= 0)
                  {
                     int endCandleIndex = (breakoutIndex >= 0) ? breakoutIndex : 0;
                     if(endCandleIndex <= InpLookbackCandles)
                     {
                        string key = GetRangeKey(range);
                        if(!IsAlreadyNotified(key) && !IsKeyPersisted(key))
                        {
                           MarkAsNotified(range);
                           AddPersistedKey(key);
                        }
                     }
                  }
               }
            }
         }
      }
      
      // Check SELL POI
      if(uiShowSellRanges)
      {
         double poiHigh = 0, poiLow = 0;
         int confirmIndex = FindBearishConfirmation(i, InpMaxGapCandles, poiHigh, poiLow, data);
         if(confirmIndex != -1)
         {
            double topBorder = 0, bottomBorder = 0;
            int bestCandles = 0;
            double liquidityLevel = 0;
            int breakoutIndex = -1;
            bool isConfirmed = false;
            
            if(TryFindValidRange(i, confirmIndex, false, 
                                 InpMinConfirmationCandles, InpMaxConfirmationCandles,
                                 topBorder, bottomBorder, bestCandles, liquidityLevel,
                                 breakoutIndex, isConfirmed, poiHigh, poiLow, data))
            {
               if(isConfirmed)
               {
                  ValidRange range;
                  range.startTime = data[i].time;
                  range.startIndex = i;
                  range.confirmIndex = confirmIndex;
                  range.topBorder = topBorder;
                  range.bottomBorder = bottomBorder;
                  range.isBuy = false;
                  range.actualConfCandles = bestCandles;
                  range.liquidityLevel = liquidityLevel;
                  range.isConfirmed = isConfirmed;
                  range.poiHigh = poiHigh;
                  range.poiLow = poiLow;
                  range.notificationSent = false;
                  range.uniqueKey = "";
                  range.symbol = symbol;
                  range.timeframe = tfStr;
                  
                  if(breakoutIndex >= 0)
                  {
                     range.endIndex = breakoutIndex;
                     
                     if(IsHigherTF(tf))
                     {
                        int candleSeconds = PeriodSeconds(tf);
                        range.endTime = data[breakoutIndex].time + candleSeconds;
                     }
                     else
                     {
                        range.endTime = data[breakoutIndex].time;
                     }
                     range.isActive = false;
                  }
                  else
                  {
                     range.endIndex = -1;
                     range.endTime = data[0].time;
                     range.isActive = true;
                  }
                  
                  bool isHigher = IsHigherTF(tf);
                  
                  if(isCurrentSymbol && isHigher)
                  {
                     int category = GetTimeframeCategory(tfStr);
                     
                     if(category == 1)
                     {
                        if(range.isBuy)
                        {
                           ArrayResize(htfBuyRanges, htfBuyCount + 1);
                           htfBuyRanges[htfBuyCount] = range;
                           htfBuyCount++;
                        }
                        else
                        {
                           ArrayResize(htfSellRanges, htfSellCount + 1);
                           htfSellRanges[htfSellCount] = range;
                           htfSellCount++;
                        }
                     }
                     else if(category == 2 && uiShowLTFOverlays)
                     {
                        if(range.isBuy)
                        {
                           ArrayResize(ltfOverlayRanges, ltfOverlayCount + 1);
                           ltfOverlayRanges[ltfOverlayCount] = range;
                           ltfOverlayCount++;
                        }
                        else
                        {
                           ArrayResize(ltfOverlayRanges, ltfOverlayCount + 1);
                           ltfOverlayRanges[ltfOverlayCount] = range;
                           ltfOverlayCount++;
                        }
                     }
                  }
                  
                  if(range.isConfirmed && range.endIndex >= 0)
                  {
                     int endCandleIndex = (breakoutIndex >= 0) ? breakoutIndex : 0;
                     if(endCandleIndex <= InpLookbackCandles)
                     {
                        string key = GetRangeKey(range);
                        if(!IsAlreadyNotified(key) && !IsKeyPersisted(key))
                        {
                           MarkAsNotified(range);
                           AddPersistedKey(key);
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Parse symbols string into array                                  |
//+------------------------------------------------------------------+
void ParseSymbols(string symbolsStr, string &symbols[])
{
   int count = 0;
   string temp = symbolsStr;
   string delimiter = ",";
   int pos = 0;
   
   while((pos = StringFind(temp, delimiter)) != -1)
   {
      string sym = StringSubstr(temp, 0, pos);
      StringTrimLeft(sym);
      StringTrimRight(sym);
      if(sym != "")
      {
         ArrayResize(symbols, count + 1);
         symbols[count] = sym;
         count++;
      }
      temp = StringSubstr(temp, pos + 1);
   }
   
   StringTrimLeft(temp);
   StringTrimRight(temp);
   if(temp != "")
   {
      ArrayResize(symbols, count + 1);
      symbols[count] = temp;
      count++;
   }
}

//+------------------------------------------------------------------+
//| Parse timeframes string into array                               |
//+------------------------------------------------------------------+
void ParseTimeframes(string tfsStr, string &tfs[])
{
   int count = 0;
   string temp = tfsStr;
   string delimiter = ",";
   int pos = 0;
   
   while((pos = StringFind(temp, delimiter)) != -1)
   {
      string tf = StringSubstr(temp, 0, pos);
      StringTrimLeft(tf);
      StringTrimRight(tf);
      if(tf != "")
      {
         ArrayResize(tfs, count + 1);
         tfs[count] = tf;
         count++;
      }
      temp = StringSubstr(temp, pos + 1);
   }
   
   StringTrimLeft(temp);
   StringTrimRight(temp);
   if(temp != "")
   {
      ArrayResize(tfs, count + 1);
      tfs[count] = temp;
      count++;
   }
}

//+------------------------------------------------------------------+
//| Scan a single symbol for all timeframes                          |
//+------------------------------------------------------------------+
void ScanSymbolTimeframes(string symbol, bool isCurrentSymbol = false)
{
   string allTimeframes[];
   string htfArray[], ltfArray[];
   ParseTimeframes(InpHTF, htfArray);
   ParseTimeframes(InpLTF, ltfArray);
   
   int totalCount = 0;
   for(int i = 0; i < ArraySize(htfArray); i++)
   {
      ArrayResize(allTimeframes, totalCount + 1);
      allTimeframes[totalCount] = htfArray[i];
      totalCount++;
   }
   for(int i = 0; i < ArraySize(ltfArray); i++)
   {
      ArrayResize(allTimeframes, totalCount + 1);
      allTimeframes[totalCount] = ltfArray[i];
      totalCount++;
   }
   
   for(int i = 0; i < ArraySize(allTimeframes); i++)
   {
      string tfStr = allTimeframes[i];
      if(tfStr == "") continue;
      
      if(symbol == currentSymbol && tfStr == currentTFStr) continue;
      
      ENUM_TIMEFRAMES tf = GetPeriodValue(tfStr);
      if(tf == PERIOD_M1 || tf == PERIOD_CURRENT) continue;
      
      bool isHigher = IsHigherTF(tf);
      
      if(isHigher)
      {
         if(isCurrentSymbol)
         {
            ScanForConfirmations(symbol, tf, tfStr, InpMaxHistoryBars, isCurrentSymbol);
         }
         else
         {
            ScanForConfirmations(symbol, tf, tfStr, InpLookbackCandles, false);
         }
      }
      else
      {
         if(uiSendLTFNotifications)
            ScanForConfirmations(symbol, tf, tfStr, InpLookbackCandles, false);
      }
   }
}

//+------------------------------------------------------------------+
//| Draw LTF Overlay Rectangle (grey color)                          |
//+------------------------------------------------------------------+
void DrawLTFOverlayRectangle(ValidRange &range, int index, string type)
{
   string rectName = type + "Rect_" + IntegerToString(index);
   color rectColor = InpLTFOverlayColor;
   
   datetime startTime = range.startTime;
   datetime endTime = range.endTime;
   
   ENUM_LINE_STYLE lineStyle = range.isConfirmed ? STYLE_DASHDOT : STYLE_DOT;
   
   ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, startTime, range.topBorder, endTime, range.bottomBorder);
   ObjectSetInteger(0, rectName, OBJPROP_COLOR, rectColor);
   ObjectSetInteger(0, rectName, OBJPROP_STYLE, lineStyle);
   ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, rectName, OBJPROP_FILL, false);
   ObjectSetInteger(0, rectName, OBJPROP_BACK, true);
   ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, rectName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, rectName, OBJPROP_HIDDEN, true);
   
   if(range.isConfirmed && range.endIndex >= 0)
   {
      string arrowName = rectName + "_Arrow";
      string arrowText = range.isBuy ? "▲" : "▼";
      double arrowPrice = range.isBuy ? range.bottomBorder : range.topBorder;
      
      ObjectCreate(0, arrowName, OBJ_TEXT, 0, range.endTime, arrowPrice);
      ObjectSetString(0, arrowName, OBJPROP_TEXT, arrowText);
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, rectColor);
      ObjectSetInteger(0, arrowName, OBJPROP_FONTSIZE, 14);
      ObjectSetString(0, arrowName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, arrowName, OBJPROP_BACK, false);
      ObjectSetInteger(0, arrowName, OBJPROP_SELECTABLE, false);
      
      string labelName = rectName + "_Label";
      double labelPrice;
      
      datetime labelTime = range.endTime + 2 * PeriodSeconds(currentTFEnum);
      
      if(range.isBuy)
      {
         labelPrice = range.bottomBorder - (range.topBorder - range.bottomBorder) * 0.02;
      }
      else
      {
         labelPrice = range.topBorder + (range.topBorder - range.bottomBorder) * 0.02;
      }
      
      ObjectCreate(0, labelName, OBJ_TEXT, 0, labelTime, labelPrice);
      ObjectSetString(0, labelName, OBJPROP_TEXT, range.timeframe);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, rectColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Draw Range Rectangle                                             |
//+------------------------------------------------------------------+
void DrawRangeRectangle(ValidRange &range, int index, string type)
{
   string rectName = type + "RangeRect_" + IntegerToString(index);
   color rectColor;
   
   bool isCurrentTF = (range.timeframe == currentTFStr);
   
   if(isCurrentTF)
   {
      rectColor = range.isBuy ? InpBuyRangeColor : InpSellRangeColor;
   }
   else
   {
      int category = GetTimeframeCategory(range.timeframe);
      bool isHTF = (category == 1);
      
      if(isHTF)
      {
         rectColor = range.isBuy ? InpPaleBuyColor : InpPaleSellColor;
      }
      else
      {
         rectColor = InpLTFOverlayColor;
      }
   }
   
   datetime startTime = range.startTime;
   datetime endTime = range.endTime;
   
   ENUM_LINE_STYLE lineStyle = range.isConfirmed ? STYLE_DASHDOT : STYLE_DOT;
   
   ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, startTime, range.topBorder, endTime, range.bottomBorder);
   ObjectSetInteger(0, rectName, OBJPROP_COLOR, rectColor);
   ObjectSetInteger(0, rectName, OBJPROP_STYLE, lineStyle);
   ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, rectName, OBJPROP_FILL, false);
   ObjectSetInteger(0, rectName, OBJPROP_BACK, true);
   ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, rectName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, rectName, OBJPROP_HIDDEN, true);
   
   if(range.isConfirmed && range.endIndex >= 0)
   {
      string arrowName = rectName + "_Arrow";
      string arrowText = range.isBuy ? "▲" : "▼";
      double arrowPrice = range.isBuy ? range.bottomBorder : range.topBorder;
      
      ObjectCreate(0, arrowName, OBJ_TEXT, 0, range.endTime, arrowPrice);
      ObjectSetString(0, arrowName, OBJPROP_TEXT, arrowText);
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, rectColor);
      ObjectSetInteger(0, arrowName, OBJPROP_FONTSIZE, 14);
      ObjectSetString(0, arrowName, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, arrowName, OBJPROP_BACK, false);
      ObjectSetInteger(0, arrowName, OBJPROP_SELECTABLE, false);
      
      if(!isCurrentTF)
      {
         string labelName = rectName + "_Label";
         double labelPrice;
         
         datetime labelTime = range.endTime + 2 * PeriodSeconds(currentTFEnum);
         
         if(range.isBuy)
         {
            labelPrice = range.bottomBorder - (range.topBorder - range.bottomBorder) * 0.02;
         }
         else
         {
            labelPrice = range.topBorder + (range.topBorder - range.bottomBorder) * 0.02;
         }
         
         ObjectCreate(0, labelName, OBJ_TEXT, 0, labelTime, labelPrice);
         ObjectSetString(0, labelName, OBJPROP_TEXT, range.timeframe);
         ObjectSetInteger(0, labelName, OBJPROP_COLOR, rectColor);
         ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
         ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
         ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      }
   }
}

//+------------------------------------------------------------------+
//| Find POIs and Draw Ranges                                        |
//+------------------------------------------------------------------+
void FindPOIsAndDrawRanges()
{
   ArrayResize(htfBuyRanges, 0); htfBuyCount = 0;
   ArrayResize(htfSellRanges, 0); htfSellCount = 0;
   ArrayResize(htfBuyPendingRanges, 0); htfBuyPendingCount = 0;
   ArrayResize(htfSellPendingRanges, 0); htfSellPendingCount = 0;
   ArrayResize(ltfOverlayRanges, 0); ltfOverlayCount = 0;
   ArrayResize(ltfOverlayPendingRanges, 0); ltfOverlayPendingCount = 0;
   
   currentSymbol = _Symbol;
   currentTFStr = GetPeriodCode(Period());
   currentTFEnum = Period();
   
   // STEP 1: Draw ranges on the current chart
   MqlRates currentData[];
   int totalBars = Bars(currentSymbol, Period());
   int limit = MathMin(InpMaxHistoryBars, totalBars);
   
   if(CopyRates(currentSymbol, Period(), 0, limit, currentData) < limit)
      return;
   
   ArraySetAsSeries(currentData, true);
   
   ValidRange drawBuyRanges[], drawSellRanges[];
   ValidRange drawBuyPendingRanges[], drawSellPendingRanges[];
   int drawBuyCount = 0, drawSellCount = 0;
   int drawBuyPendingCount = 0, drawSellPendingCount = 0;
   
   datetime currentBarTime = currentData[0].time;
   int startBar = MathMin(limit - InpMaxConfirmationCandles - InpMaxGapCandles - 10, limit - 1);
   if(startBar < 0) startBar = 0;
   
   for(int i = startBar; i >= 0; i--)
   {
      if(!HasWick(i, InpMinWickRatio, InpMinRange, currentData))
         continue;
      
      if(uiShowBuyRanges)
      {
         double poiHigh = 0, poiLow = 0;
         int confirmIndex = FindBullishConfirmation(i, InpMaxGapCandles, poiHigh, poiLow, currentData);
         if(confirmIndex != -1)
         {
            double topBorder = 0, bottomBorder = 0;
            int bestCandles = 0;
            double liquidityLevel = 0;
            int breakoutIndex = -1;
            bool isConfirmed = false;
            
            if(TryFindValidRange(i, confirmIndex, true, 
                                 InpMinConfirmationCandles, InpMaxConfirmationCandles,
                                 topBorder, bottomBorder, bestCandles, liquidityLevel,
                                 breakoutIndex, isConfirmed, poiHigh, poiLow, currentData))
            {
               ValidRange range;
               range.startTime = currentData[i].time;
               range.startIndex = i;
               range.confirmIndex = confirmIndex;
               range.topBorder = topBorder;
               range.bottomBorder = bottomBorder;
               range.isBuy = true;
               range.actualConfCandles = bestCandles;
               range.liquidityLevel = liquidityLevel;
               range.isConfirmed = isConfirmed;
               range.poiHigh = poiHigh;
               range.poiLow = poiLow;
               range.notificationSent = false;
               range.uniqueKey = "";
               range.symbol = currentSymbol;
               range.timeframe = currentTFStr;
               
               if(breakoutIndex >= 0)
               {
                  range.endIndex = breakoutIndex;
                  range.endTime = currentData[breakoutIndex].time;
                  range.isActive = false;
               }
               else
               {
                  range.endIndex = -1;
                  range.endTime = currentBarTime;
                  range.isActive = true;
               }
               
               if(isConfirmed)
               {
                  ArrayResize(drawBuyRanges, drawBuyCount + 1);
                  drawBuyRanges[drawBuyCount] = range;
                  drawBuyCount++;
               }
               else if(uiShowPendingRanges)
               {
                  ArrayResize(drawBuyPendingRanges, drawBuyPendingCount + 1);
                  drawBuyPendingRanges[drawBuyPendingCount] = range;
                  drawBuyPendingCount++;
               }
            }
         }
      }
      
      if(uiShowSellRanges)
      {
         double poiHigh = 0, poiLow = 0;
         int confirmIndex = FindBearishConfirmation(i, InpMaxGapCandles, poiHigh, poiLow, currentData);
         if(confirmIndex != -1)
         {
            double topBorder = 0, bottomBorder = 0;
            int bestCandles = 0;
            double liquidityLevel = 0;
            int breakoutIndex = -1;
            bool isConfirmed = false;
            
            if(TryFindValidRange(i, confirmIndex, false, 
                                 InpMinConfirmationCandles, InpMaxConfirmationCandles,
                                 topBorder, bottomBorder, bestCandles, liquidityLevel,
                                 breakoutIndex, isConfirmed, poiHigh, poiLow, currentData))
            {
               ValidRange range;
               range.startTime = currentData[i].time;
               range.startIndex = i;
               range.confirmIndex = confirmIndex;
               range.topBorder = topBorder;
               range.bottomBorder = bottomBorder;
               range.isBuy = false;
               range.actualConfCandles = bestCandles;
               range.liquidityLevel = liquidityLevel;
               range.isConfirmed = isConfirmed;
               range.poiHigh = poiHigh;
               range.poiLow = poiLow;
               range.notificationSent = false;
               range.uniqueKey = "";
               range.symbol = currentSymbol;
               range.timeframe = currentTFStr;
               
               if(breakoutIndex >= 0)
               {
                  range.endIndex = breakoutIndex;
                  range.endTime = currentData[breakoutIndex].time;
                  range.isActive = false;
               }
               else
               {
                  range.endIndex = -1;
                  range.endTime = currentBarTime;
                  range.isActive = true;
               }
               
               if(isConfirmed)
               {
                  ArrayResize(drawSellRanges, drawSellCount + 1);
                  drawSellRanges[drawSellCount] = range;
                  drawSellCount++;
               }
               else if(uiShowPendingRanges)
               {
                  ArrayResize(drawSellPendingRanges, drawSellPendingCount + 1);
                  drawSellPendingRanges[drawSellPendingCount] = range;
                  drawSellPendingCount++;
               }
            }
         }
      }
   }
   
   if(uiFilterOverlaps)
   {
      FilterOverlappingRangesGrouped(drawBuyRanges, drawBuyCount, true);
      FilterOverlappingRangesGrouped(drawSellRanges, drawSellCount, false);
   }
   
   CleanupRanges();
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, false);
   
   for(int i = 0; i < drawBuyCount; i++)
      DrawRangeRectangle(drawBuyRanges[i], i, "Buy");
      
   for(int i = 0; i < drawSellCount; i++)
      DrawRangeRectangle(drawSellRanges[i], i, "Sell");
   
   for(int i = 0; i < drawBuyPendingCount; i++)
      DrawRangeRectangle(drawBuyPendingRanges[i], i, "BuyPending");
      
   for(int i = 0; i < drawSellPendingCount; i++)
      DrawRangeRectangle(drawSellPendingRanges[i], i, "SellPending");
   
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, true);
   ChartRedraw();
   
   // STEP 2: Scan the current symbol's higher timeframes for overlays
   ScanSymbolTimeframes(currentSymbol, true);
   
   // STEP 3: Filter HTF overlay ranges by timeframe group
   if(uiFilterOverlaps)
   {
      FilterOverlappingRangesGrouped(htfBuyRanges, htfBuyCount, true);
      FilterOverlappingRangesGrouped(htfSellRanges, htfSellCount, false);
      FilterOverlappingRangesGrouped(htfBuyPendingRanges, htfBuyPendingCount, true);
      FilterOverlappingRangesGrouped(htfSellPendingRanges, htfSellPendingCount, false);
   }
   
   // STEP 4: Draw HTF overlay ranges (pale colors)
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, false);
   
   for(int i = 0; i < htfBuyCount; i++)
      DrawRangeRectangle(htfBuyRanges[i], i, "HTFBuy");
      
   for(int i = 0; i < htfSellCount; i++)
      DrawRangeRectangle(htfSellRanges[i], i, "HTFSell");
   
   for(int i = 0; i < htfBuyPendingCount; i++)
      DrawRangeRectangle(htfBuyPendingRanges[i], i, "HTFBuyPending");
      
   for(int i = 0; i < htfSellPendingCount; i++)
      DrawRangeRectangle(htfSellPendingRanges[i], i, "HTFSellPending");
   
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, true);
   ChartRedraw();
   
   // STEP 5: Filter LTF overlay ranges (grey)
   if(uiFilterOverlaps)
   {
      FilterOverlappingRangesGrouped(ltfOverlayRanges, ltfOverlayCount, true);
      FilterOverlappingRangesGrouped(ltfOverlayRanges, ltfOverlayCount, false);
      FilterOverlappingRangesGrouped(ltfOverlayPendingRanges, ltfOverlayPendingCount, true);
      FilterOverlappingRangesGrouped(ltfOverlayPendingRanges, ltfOverlayPendingCount, false);
   }
   
   // STEP 6: Draw LTF overlay ranges (grey color)
   if(uiShowLTFOverlays)
   {
      ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, false);
      
      for(int i = 0; i < ltfOverlayCount; i++)
         DrawLTFOverlayRectangle(ltfOverlayRanges[i], i, "LTFOverlay");
         
      for(int i = 0; i < ltfOverlayPendingCount; i++)
         DrawLTFOverlayRectangle(ltfOverlayPendingRanges[i], i, "LTFOverlayPending");
      
      ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, true);
      ChartRedraw();
   }
   
   // STEP 7: Scan other symbols for notifications (background) and send grouped notifications
   if(uiSendHTFNotifications || uiSendLTFNotifications)
   {
      string symbols[];
      ParseSymbols(InpSymbols, symbols);
      
      for(int s = 0; s < ArraySize(symbols); s++)
      {
         string symbol = symbols[s];
         if(symbol == "") continue;
         if(symbol == currentSymbol) continue;
         
         ScanSymbolTimeframes(symbol, false);
      }
      
      if(notifiedCount > 0)
      {
         string symbolsWithOpportunities[];
         string buyTimeframes[];
         string sellTimeframes[];
         int totalCounts[];
         int assetCount = 0;
         
         for(int n = 0; n < notifiedCount; n++)
         {
            string symbol = notifiedRanges[n].symbol;
            string tf = notifiedRanges[n].timeframe;
            bool isBuy = notifiedRanges[n].isBuy;
            
            int category = GetTimeframeCategory(tf);
            bool isHTF = (category == 1);
            bool isLTF = (category == 2);
            
            if((isHTF && !uiSendHTFNotifications) || (isLTF && !uiSendLTFNotifications))
               continue;
            
            int idx = -1;
            for(int a = 0; a < assetCount; a++)
            {
               if(symbolsWithOpportunities[a] == symbol)
               {
                  idx = a;
                  break;
               }
            }
            
            if(idx == -1)
            {
               ArrayResize(symbolsWithOpportunities, assetCount + 1);
               ArrayResize(buyTimeframes, assetCount + 1);
               ArrayResize(sellTimeframes, assetCount + 1);
               ArrayResize(totalCounts, assetCount + 1);
               
               symbolsWithOpportunities[assetCount] = symbol;
               buyTimeframes[assetCount] = "";
               sellTimeframes[assetCount] = "";
               totalCounts[assetCount] = 0;
               idx = assetCount;
               assetCount++;
            }
            
            string tfList = isBuy ? buyTimeframes[idx] : sellTimeframes[idx];
            bool alreadyExists = false;
            
            if(StringLen(tfList) > 0)
            {
               string tfArray[];
               StringSplit(tfList, ',', tfArray);
               for(int t = 0; t < ArraySize(tfArray); t++)
               {
                  StringTrimLeft(tfArray[t]);
                  StringTrimRight(tfArray[t]);
                  if(tfArray[t] == tf)
                  {
                     alreadyExists = true;
                     break;
                  }
               }
            }
            
            if(!alreadyExists)
            {
               if(isBuy)
               {
                  if(StringLen(buyTimeframes[idx]) > 0)
                     buyTimeframes[idx] += ", " + tf;
                  else
                     buyTimeframes[idx] = tf;
               }
               else
               {
                  if(StringLen(sellTimeframes[idx]) > 0)
                     sellTimeframes[idx] += ", " + tf;
                  else
                     sellTimeframes[idx] = tf;
               }
            }
         }
         
         for(int a = 0; a < assetCount; a++)
         {
            int buyCount = 0, sellCount = 0;
            
            if(StringLen(buyTimeframes[a]) > 0)
            {
               string tfArray[];
               StringSplit(buyTimeframes[a], ',', tfArray);
               buyCount = ArraySize(tfArray);
            }
            
            if(StringLen(sellTimeframes[a]) > 0)
            {
               string tfArray[];
               StringSplit(sellTimeframes[a], ',', tfArray);
               sellCount = ArraySize(tfArray);
            }
            
            totalCounts[a] = buyCount + sellCount;
         }
         
         for(int a = 0; a < assetCount; a++)
         {
            if(totalCounts[a] > 0)
            {
               SendNotification(symbolsWithOpportunities[a], 
                                buyTimeframes[a], 
                                sellTimeframes[a], 
                                totalCounts[a]);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Send all current opportunities immediately (manual trigger)      |
//+------------------------------------------------------------------+
void SendCurrentOpportunitiesNow()
{
   Print("=== SEND NOW: collecting current opportunities ===");

   // 1) Temporarily clear the in-memory persisted keys so the scanner
   //    re-collects every currently-active confirmed range.
   string savedKeys[];
   ArrayResize(savedKeys, g_notifiedKeysCount);
   for(int i = 0; i < g_notifiedKeysCount; i++)
      savedKeys[i] = g_notifiedKeys[i];
   int savedCount = g_notifiedKeysCount;

   ArrayResize(g_notifiedKeys, 0);
   g_notifiedKeysCount = 0;

   ArrayResize(notifiedRanges, 0);
   notifiedCount = 0;

   currentSymbol  = _Symbol;
   currentTFStr   = GetPeriodCode(Period());
   currentTFEnum  = Period();

   // 2) Scan everything
   ScanSymbolTimeframes(currentSymbol, true);

   string symbols[];
   ParseSymbols(InpSymbols, symbols);
   for(int s = 0; s < ArraySize(symbols); s++)
   {
      string symbol = symbols[s];
      if(symbol == "") continue;
      if(symbol == currentSymbol) continue;
      ScanSymbolTimeframes(symbol, false);
   }

   // 3) Merge the saved keys back in (plus any new ones the scan added)
   for(int i = 0; i < savedCount; i++)
      AddPersistedKey(savedKeys[i]);
   SavePersistedKeys();

   if(notifiedCount == 0)
   {
      Print("SEND NOW: no confirmed opportunities found.");
      return;
   }

   // 4) Group by symbol -> buy/sell timeframes
   string symbolsWithOpportunities[];
   string buyTimeframes[];
   string sellTimeframes[];
   int    totalCounts[];
   int    assetCount = 0;

   for(int n = 0; n < notifiedCount; n++)
   {
      string symbol = notifiedRanges[n].symbol;
      string tf     = notifiedRanges[n].timeframe;
      bool   isBuy  = notifiedRanges[n].isBuy;

      if(symbol == "") continue;

      int idx = -1;
      for(int a = 0; a < assetCount; a++)
      {
         if(symbolsWithOpportunities[a] == symbol)
         {
            idx = a;
            break;
         }
      }

      if(idx == -1)
      {
         ArrayResize(symbolsWithOpportunities, assetCount + 1);
         ArrayResize(buyTimeframes, assetCount + 1);
         ArrayResize(sellTimeframes, assetCount + 1);
         ArrayResize(totalCounts, assetCount + 1);

         symbolsWithOpportunities[assetCount] = symbol;
         buyTimeframes[assetCount] = "";
         sellTimeframes[assetCount] = "";
         totalCounts[assetCount] = 0;
         idx = assetCount;
         assetCount++;
      }

      string tfList = isBuy ? buyTimeframes[idx] : sellTimeframes[idx];
      bool alreadyExists = false;

      if(StringLen(tfList) > 0)
      {
         string tfArray[];
         StringSplit(tfList, ',', tfArray);
         for(int t = 0; t < ArraySize(tfArray); t++)
         {
            StringTrimLeft(tfArray[t]);
            StringTrimRight(tfArray[t]);
            if(tfArray[t] == tf)
            {
               alreadyExists = true;
               break;
            }
         }
      }

      if(!alreadyExists)
      {
         if(isBuy)
         {
            if(StringLen(buyTimeframes[idx]) > 0)
               buyTimeframes[idx] += ", " + tf;
            else
               buyTimeframes[idx] = tf;
         }
         else
         {
            if(StringLen(sellTimeframes[idx]) > 0)
               sellTimeframes[idx] += ", " + tf;
            else
               sellTimeframes[idx] = tf;
         }
      }
   }

   // 5) Count and send
   for(int a = 0; a < assetCount; a++)
   {
      int buyCount = 0, sellCount = 0;

      if(StringLen(buyTimeframes[a]) > 0)
      {
         string tfArray[];
         StringSplit(buyTimeframes[a], ',', tfArray);
         buyCount = ArraySize(tfArray);
      }
      if(StringLen(sellTimeframes[a]) > 0)
      {
         string tfArray[];
         StringSplit(sellTimeframes[a], ',', tfArray);
         sellCount = ArraySize(tfArray);
      }
      totalCounts[a] = buyCount + sellCount;
   }

   for(int a = 0; a < assetCount; a++)
   {
      if(totalCounts[a] > 0)
      {
         // Force a send: temporarily bypass SendNotification's message dedup
         for(int i = 0; i < lastNotificationCount; i++)
            lastNotificationMessages[i] = "";

         SendNotification(symbolsWithOpportunities[a],
                          buyTimeframes[a],
                          sellTimeframes[a],
                          totalCounts[a]);
      }
   }

   Print("SEND NOW: finished. Symbols with opportunities: ", assetCount);
}

//+------------------------------------------------------------------+
//| Cleanup Ranges                                                   |
//+------------------------------------------------------------------+
void CleanupRanges()
{
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string objName = ObjectName(0, i);
      if(StringFind(objName, "BuyRangeRect_") == 0 || 
         StringFind(objName, "SellRangeRect_") == 0 ||
         StringFind(objName, "BuyPendingRangeRect_") == 0 ||
         StringFind(objName, "SellPendingRangeRect_") == 0 ||
         StringFind(objName, "HTFBuyRangeRect_") == 0 ||
         StringFind(objName, "HTFSellRangeRect_") == 0 ||
         StringFind(objName, "HTFBuyPendingRangeRect_") == 0 ||
         StringFind(objName, "HTFSellPendingRangeRect_") == 0 ||
         StringFind(objName, "LTFOverlayRect_") == 0 ||
         StringFind(objName, "LTFOverlayPendingRect_") == 0)
      {
         ObjectDelete(0, objName);
      }
   }
}

//+------------------------------------------------------------------+
//| Chart Event Handler                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_CLICK)
   {
      int chartX = (int)lparam;
      int chartY = (int)dparam;

      string actionName = "";
      bool toggleClicked = g_uiPanel.OnClick(chartX, chartY, actionName);

      if(actionName == "send_now")
      {
         SendCurrentOpportunitiesNow();
         ChartRedraw();
         return;
      }

      if(toggleClicked)
      {
         SyncUIFlagsFromPanel();
         FindPOIsAndDrawRanges();
         ChartRedraw();
         return;
      }
   }

   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      int chartX = (int)lparam;
      int chartY = (int)dparam;

      g_uiPanel.OnMouseMove(chartX, chartY);
      return;
   }

   if(id == CHARTEVENT_CHART_CHANGE)
   {
      g_uiPanel.Reposition();
      FindPOIsAndDrawRanges();
   }
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpMinWickRatio <= 0 || InpMinWickRatio >= 1)
   {
      Print("MinWickRatio must be between 0 and 1");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpMinRange < 0)
   {
      Print("MinRange cannot be negative");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpMaxGapCandles < 0)
   {
      Print("MaxGapCandles cannot be negative");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpMinConfirmationCandles < 1)
   {
      Print("MinConfirmationCandles must be at least 1");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpMaxConfirmationCandles < InpMinConfirmationCandles)
   {
      Print("MaxConfirmationCandles must be >= MinConfirmationCandles");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpMaxHistoryBars < InpMaxConfirmationCandles + 20)
   {
      Print("MaxHistoryBars too low. Minimum: ", InpMaxConfirmationCandles + 20);
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpLookbackCandles < 1)
   {
      Print("LookbackCandles must be at least 1");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpOverlapCandles < 0)
   {
      Print("OverlapCandles cannot be negative");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   ArrayResize(notifiedRanges, 0);
   notifiedCount = 0;
   
   ArrayResize(htfBuyRanges, 0);
   ArrayResize(htfSellRanges, 0);
   ArrayResize(htfBuyPendingRanges, 0);
   ArrayResize(htfSellPendingRanges, 0);
   ArrayResize(ltfOverlayRanges, 0);
   ArrayResize(ltfOverlayPendingRanges, 0);
   
   ArrayResize(lastNotificationSymbols, 0);
   ArrayResize(lastNotificationMessages, 0);
   lastNotificationCount = 0;
   
   // Load global persistent notified keys
   LoadPersistedKeys();
   
   InitUIPanel();
   
   FindPOIsAndDrawRanges();
   
   // Persist any newly notified keys discovered on this run
   SavePersistedKeys();
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Persist notified keys and button states before cleanup
   SavePersistedKeys();
   g_uiPanel.SaveStates();
   
   g_uiPanel.Destroy();
   CleanupRanges();
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| OnCalculate                                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   static int lastBars = 0;
   int currentBars = Bars(_Symbol, _Period);
   
   if(currentBars != lastBars)
   {
      lastBars = currentBars;
      FindPOIsAndDrawRanges();
      SavePersistedKeys();
   }
   
   return rates_total;
}