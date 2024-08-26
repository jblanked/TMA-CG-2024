//+------------------------------------------------------------------+
//|                                                  TMA-CG-2024.mq4 |
//|                                        Copyright 2024, JBlanked. |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, JBlanked."
#property link      "https://www.jblanked.com/"
#property description "Non-repainting triangular moving average original coded by Mladen. All credits to him for the idea. Edits by JBlanked, rajiv, and eevviill."
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots 7

/*
   - Thread: https://www.forexfactory.com/thread/1300763-tma-cg-2024
   - Download indicator source code: https://github.com/jblanked/TMA-CG-2024
   - Download library source code: https://github.com/jblanked/TMA-CG-2024/blob/main/TMA-CG-2024.mqh

   All credits are due to Mladen.

   Created August 25th, 2024 (jblanked)
      - created a class to simplfy use in Indicators, Expert Advisors, and more
      - replaced iCustom(s) with iBarShift
      - created an MT5 version
      - switched init() to OnInit()
      - switched start() to OnCalculate()
      - switched deinit() to OnDeInit()
      - removed alerts
      - switched externs into inputs
      - implemented CIndicator class
      - switched string input TimeFrame to ENUM_TIMEFRAMES input inpTimeframe
      - limit to draw maximum 5000 candles
*/

#include <jb-indicator.mqh> // download from https://github.com/jblanked/MQL-Library/blob/main/JB-Indicator.mqh
#include <tma-cg-2024.mqh> // download from https://github.com/jblanked/TMA-CG-2024/blob/main/TMA-CG-2024.mqh

input ENUM_TIMEFRAMES      inpTimeFrame      = PERIOD_CURRENT; // Timeframe
input int                  inpHalfLength     = 56;             // Half Length
input ENUM_APPLIED_PRICE   inpAppliedPrice   = PRICE_WEIGHTED; // Applied Price
input double               inpBandsDeviation = 1.618;          // Bands Deviation
input int                  inpMaximumCandles = 5000;           // Maximum Candles

double tmBuffer[];
double upBuffer[];
double dnBuffer[];
double wuBuffer[];
double wdBuffer[];
double upArrow[];
double dnArrow[];

CIndicator indi;
CMladenTMACG *tma;
int maximumCandles, barShift;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
// check half length input
   if(inpHalfLength < 1)
     {
      Print("Half Length cannot be less than 1");
      return INIT_FAILED;
     }

//--- indicator buffers mapping
   if(!indi.createBuffer("Midline", DRAW_LINE, STYLE_DOT, clrDimGray, 1, 0, tmBuffer, true, INDICATOR_DATA, 233))
     {
      return INIT_FAILED;
     }

   if(!indi.createBuffer("Upline", DRAW_LINE, STYLE_SOLID, clrMaroon, 2, 1, upBuffer, true, INDICATOR_DATA, 233))
     {
      return INIT_FAILED;
     }

   if(!indi.createBuffer("Dnline", DRAW_LINE, STYLE_SOLID, clrDarkBlue, 2, 2, dnBuffer, true, INDICATOR_DATA, 233))
     {
      return INIT_FAILED;
     }

   if(!indi.createBuffer("Buy", DRAW_ARROW, STYLE_DOT, clrBlue, 1, 3, upArrow, true, INDICATOR_DATA, 233))
     {
      return INIT_FAILED;
     }

   if(!indi.createBuffer("Sell", DRAW_ARROW, STYLE_DOT, clrRed, 1, 4, dnArrow, true, INDICATOR_DATA, 234))
     {
      return INIT_FAILED;
     }
#ifdef __MQL4__
   if(!indi.createBuffer(NULL, DRAW_NONE, STYLE_SOLID, clrNONE, 1, 5, wuBuffer, false, INDICATOR_CALCULATIONS, 242))
     {
      return INIT_FAILED;
     }

   if(!indi.createBuffer(NULL, DRAW_NONE, STYLE_SOLID, clrNONE, 1, 6, wdBuffer, false, INDICATOR_CALCULATIONS, 241))
     {
      return INIT_FAILED;
     }
#else
   if(!indi.createBuffer("Buffer 5", DRAW_NONE, STYLE_SOLID, clrNONE, 1, 5, wuBuffer, false, INDICATOR_CALCULATIONS, 242))
     {
      return INIT_FAILED;
     }

   if(!indi.createBuffer("Buffer 6", DRAW_NONE, STYLE_SOLID, clrNONE, 1, 6, wdBuffer, false, INDICATOR_CALCULATIONS, 241))
     {
      return INIT_FAILED;
     }
#endif
//--- set draw begin
#ifdef __MQL4__
   SetIndexDrawBegin(0, inpHalfLength);
   SetIndexDrawBegin(1, inpHalfLength);
   SetIndexDrawBegin(2, inpHalfLength);
#else
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, inpHalfLength);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, inpHalfLength);
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, inpHalfLength);
#endif

//--- initialize buffer arrays
   ArrayInitialize(tmBuffer, EMPTY_VALUE);
   ArrayInitialize(upBuffer, EMPTY_VALUE);
   ArrayInitialize(dnBuffer, EMPTY_VALUE);
   ArrayInitialize(wuBuffer, EMPTY_VALUE);
   ArrayInitialize(wdBuffer, EMPTY_VALUE);
   ArrayInitialize(upArrow, EMPTY_VALUE);
   ArrayInitialize(dnArrow, EMPTY_VALUE);

//--- set tma
   tma = new CMladenTMACG(_Symbol, inpTimeFrame, inpHalfLength, inpAppliedPrice, inpBandsDeviation, inpMaximumCandles);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//
   int trueLimit = rates_total - prev_calculated;
//--- set buffers as series
   if(prev_calculated < 1)
     {
      ArraySetAsSeries(tmBuffer, true);
      ArraySetAsSeries(upBuffer, true);
      ArraySetAsSeries(dnBuffer, true);
      ArraySetAsSeries(wuBuffer, true);
      ArraySetAsSeries(wdBuffer, true);
      ArraySetAsSeries(upArrow, true);
      ArraySetAsSeries(dnArrow, true);
     }
   else
     {
      trueLimit++;
     }
//--- run tma
   tma.run(trueLimit > inpMaximumCandles ? inpMaximumCandles : trueLimit);
//--- copy array valus
   for(int i = trueLimit > inpMaximumCandles ? inpMaximumCandles - 1 : trueLimit - 1; i >= 0; i--)
     {

      barShift = iBarShift(_Symbol, inpTimeFrame, iTime(_Symbol, PERIOD_CURRENT, i));

      if(barShift >= ArraySize(tma.wdBuffer))
        {
         continue;
        }

      wuBuffer[i] = tma.wuBuffer[barShift];
      wdBuffer[i] = tma.wdBuffer[barShift];
      tmBuffer[i] = tma.tmBuffer[barShift];
      upBuffer[i] = tma.upBuffer[barShift];
      dnBuffer[i] = tma.dnBuffer[barShift];
      upArrow[i] = tma.upArrow[barShift];
      dnArrow[i] = tma.dnArrow[barShift];
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   indi.deletePointer(tma);
  }
//+------------------------------------------------------------------+
