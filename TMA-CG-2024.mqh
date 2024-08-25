//+------------------------------------------------------------------+
//|                                                  TMA-CG-2024.mqh |
//|                                        Copyright 2024, JBlanked. |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, JBlanked."
#property link      "https://www.jblanked.com/"
#property description "Non-repainting triangular moving average original coded by Mladen. All credits to him for the idea. Edits by JBlanked, rajiv, and eevviill."
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMladenTMACG
  {
public:
                     CMladenTMACG::CMladenTMACG(
      const string symbol,
      const ENUM_TIMEFRAMES timeframe,
      const int halfLength = 56,
      const ENUM_APPLIED_PRICE appliedPrice = PRICE_WEIGHTED,
      const double bandsDeviation = 1.618,
      const int maximumBars = 5000,
      const ENUM_TIMEFRAMES currentTimeframe = PERIOD_CURRENT
   )
     {
      this.m_symbol           = symbol;            // symbol
      this.m_timeframe        = timeframe;         // timeframe
      this.m_currentTimeframe = currentTimeframe;  // current timeframe
      this.maximumCandles     = maximumBars;       // maximum bars to calculate
      this.m_halfLength       = halfLength;        // Half Length
      this.m_appliedPrice     = appliedPrice;      // Applied Price
      this.m_bandsDeviation   = bandsDeviation;    // Bands Deviation
      this.isSetAsSeries      = false;
      this.init();
     }


                     CMladenTMACG::CMladenTMACG()
     {
      this.m_symbol           = _Symbol;        // symbol
      this.m_timeframe        = ChartPeriod();  // timeframe
      this.m_currentTimeframe = ChartPeriod();  // current timeframe
      this.maximumCandles     = 5000;           // maximum bars to calculate
      this.m_halfLength       = 56;             // Half Length
      this.m_appliedPrice     = PRICE_WEIGHTED; // Applied Price
      this.m_bandsDeviation   = 1.618;          // Bands Deviation
      this.isSetAsSeries      = false;
      this.init();
     }

   CMladenTMACG::   ~CMladenTMACG()
     {

     }

   void              run(int limitCandles)
     {
      if(!this.isSetAsSeries)
        {
         this.setAsSeries();
        }

      limitCandles = limitCandles > maximumCandles ? maximumCandles : limitCandles;

#ifdef __MQL5__
      CopyBuffer(this.atrHandle, 0, 0, limitCandles + 3 + this.m_halfLength, this.atr);
      CopyBuffer(this.maHandle, 0, 0, limitCandles + 3 + this.m_halfLength, this.ma);
#endif

      //--- calculate TMA
      calculateTma(limitCandles - 1, this.m_timeframe);
      // run loop
      for(int i = limitCandles - 1; i >= 0; i--)
        {
         //--- set barshift
         const int      shift1 = iBarShift(this.m_symbol, this.m_timeframe, iTime(this.m_symbol, this.m_currentTimeframe, i));
         const datetime time1  = iTime(this.m_symbol, this.m_timeframe, shift1);

         if(shift1 > (maximumCandles + 3 + this.m_halfLength))
           {
            continue;
           }

         // initialize buffer values
         tmBuffer[i] = tmBuffer[shift1];
         upBuffer[i] = upBuffer[shift1];
         dnBuffer[i] = dnBuffer[shift1];
         upArrow[i] = EMPTY_VALUE;
         dnArrow[i] = EMPTY_VALUE;

         //--- set arrows and interpolate
         if(
            iHigh(this.m_symbol, this.m_currentTimeframe, i + 1)   > upBuffer[i + 1] &&
            iClose(this.m_symbol, this.m_currentTimeframe, i + 1)  > iOpen(this.m_symbol, this.m_currentTimeframe, i + 1) &&
            iClose(this.m_symbol, this.m_currentTimeframe, i)    < iOpen(this.m_symbol, PERIOD_CURRENT, i)
         )
           {
#ifdef __MQL4__
            upArrow[i] = iHigh(this.m_symbol, PERIOD_CURRENT, i) + iATR(this.m_symbol, PERIOD_CURRENT, 20, i);
#else
            upArrow[i] = iHigh(this.m_symbol, PERIOD_CURRENT, i) + atr[i];
#endif
           }
         if(
            iLow(this.m_symbol, PERIOD_CURRENT, i + 1)    < dnBuffer[i + 1] &&
            iClose(this.m_symbol, PERIOD_CURRENT, i + 1)  < iOpen(this.m_symbol, PERIOD_CURRENT, i + 1) &&
            iClose(this.m_symbol, PERIOD_CURRENT, i)    > iOpen(this.m_symbol, PERIOD_CURRENT, i)
         )
           {
#ifdef __MQL4__
            dnArrow[i] = iLow(this.m_symbol, PERIOD_CURRENT, i) - iATR(this.m_symbol, PERIOD_CURRENT, 20, i);
#else
            dnArrow[i] = iLow(this.m_symbol, PERIOD_CURRENT, i) - atr[i];
#endif
           }

         if(this.m_timeframe <= Period() || shift1 == iBarShift(this.m_symbol, this.m_timeframe, iTime(this.m_symbol, PERIOD_CURRENT, i - 1)))
            continue;

         for(n = 1; i + n < Bars(this.m_symbol, PERIOD_CURRENT) && iTime(this.m_symbol, PERIOD_CURRENT, i + n) >= time1; n++)
            continue;

         double factor = 1.0 / n;

         for(int k = 1; k < n; k++)
           {
            tmBuffer[i + k] = k * factor * tmBuffer[i + n] + (1.0 - k * factor) * tmBuffer[i];
            upBuffer[i + k] = k * factor * upBuffer[i + n] + (1.0 - k * factor) * upBuffer[i];
            dnBuffer[i + k] = k * factor * dnBuffer[i + n] + (1.0 - k * factor) * dnBuffer[i];
           }
        }
     }

   double            tmBuffer[];       // Buffer 0
   double            upBuffer[];       // Buffer 1
   double            dnBuffer[];       // Buffer 2
   double            upArrow[];        // Buffer 3
   double            dnArrow[];        // Buffer 4
   double            wuBuffer[];       // Buffer 5
   double            wdBuffer[];       // Buffer 6

private:

   int               maximumCandles;   // Maximum Bars to Calculate

   string            m_symbol;         // Symbol
   ENUM_TIMEFRAMES   m_timeframe;      // Timeframe
   ENUM_TIMEFRAMES   m_currentTimeframe; // Current Timeframe
   int               m_halfLength;     // Half Length
   ENUM_APPLIED_PRICE m_appliedPrice;  // Applied Price
   double            m_bandsDeviation; // Bands Deviation

#ifdef __MQL5__
   int               atrHandle;
   int               maHandle;
   double            atr[];
   double            ma[];
#endif

   bool              isSetAsSeries;
   int               n;

   bool              init(void)
     {
#ifdef __MQL5__
      atrHandle = iATR(this.m_symbol, PERIOD_CURRENT, 20);
      maHandle = iMA(this.m_symbol, this.m_timeframe, 1, 0, MODE_SMA, this.m_appliedPrice);
      return atrHandle != INVALID_HANDLE && maHandle != INVALID_HANDLE;
#else
      return true;
#endif
     }

   void              setAsSeries(void)
     {
      //--- initialize
      ArrayInitialize(tmBuffer, EMPTY_VALUE);
      ArrayInitialize(upBuffer, EMPTY_VALUE);
      ArrayInitialize(dnBuffer, EMPTY_VALUE);
      ArrayInitialize(wuBuffer, EMPTY_VALUE);
      ArrayInitialize(wdBuffer, EMPTY_VALUE);
      ArrayInitialize(upArrow, EMPTY_VALUE);
      ArrayInitialize(dnArrow, EMPTY_VALUE);
#ifdef __MQL5__
      ArrayInitialize(atr, EMPTY_VALUE);
      ArrayInitialize(ma, EMPTY_VALUE);
#endif

      //--- set as series
      ArraySetAsSeries(tmBuffer, true);
      ArraySetAsSeries(upBuffer, true);
      ArraySetAsSeries(dnBuffer, true);
      ArraySetAsSeries(wuBuffer, true);
      ArraySetAsSeries(wdBuffer, true);
      ArraySetAsSeries(upArrow, true);
      ArraySetAsSeries(dnArrow, true);
#ifdef __MQL5__
      ArraySetAsSeries(atr, true);
      ArraySetAsSeries(ma, true);
#endif

      //---resize
      ArrayResize(tmBuffer, this.maximumCandles + 3 + this.m_halfLength);
      ArrayResize(upBuffer, this.maximumCandles + 3 + this.m_halfLength);
      ArrayResize(dnBuffer, this.maximumCandles + 3 + this.m_halfLength);
      ArrayResize(wuBuffer, this.maximumCandles + 3 + this.m_halfLength);
      ArrayResize(wdBuffer, this.maximumCandles + 3 + this.m_halfLength);
      ArrayResize(upArrow, this.maximumCandles + 3 + this.m_halfLength);
      ArrayResize(dnArrow, this.maximumCandles + 3 + this.m_halfLength);
#ifdef __MQL5__
      ArrayResize(atr, this.maximumCandles + 3 + this.m_halfLength);
      ArrayResize(ma, this.maximumCandles + 3 + this.m_halfLength);
#endif

      this.isSetAsSeries = true;
     }

   void              calculateTma(int limit, ENUM_TIMEFRAMES timeframe) // this may need a bar shift to set the correct timeframes value
     {
      int i, j, k;
      double FullLength = 2.0 * this.m_halfLength + 1.0;

      for(i = limit; i >= 0; i--)
        {
#ifdef __MQL4__
         double sum  = (this.m_halfLength + 1) * iMA(this.m_symbol, timeframe, 1, 0, MODE_SMA, this.m_appliedPrice, i);
#else
         double sum  = (this.m_halfLength + 1) * ma[i];
#endif
         double sumw = (this.m_halfLength + 1);
         for(j = 1, k = this.m_halfLength; j <= this.m_halfLength; j++, k--)
           {
#ifdef __MQL4__
            sum  += k * iMA(this.m_symbol, timeframe, 1, 0, MODE_SMA, this.m_appliedPrice, i + j);
#else
            sum  += k * ma[i + j];
#endif
            sumw += k;

            if(j <= i)
              {
#ifdef __MQL4__
               sum  += k * iMA(this.m_symbol, timeframe, 1, 0, MODE_SMA, this.m_appliedPrice, i - j);
#else
               sum  += k * ma[i - j];
#endif
               sumw += k;
              }
           }
         tmBuffer[i] = sum / sumw;

#ifdef __MQL4__
         double diff = iMA(this.m_symbol, timeframe, 1, 0, MODE_SMA, this.m_appliedPrice, i) - tmBuffer[i];
#else
         double diff = ma[i] - tmBuffer[i];
#endif
         if(i > (Bars(this.m_symbol, timeframe) - this.m_halfLength - 1))
            continue;
         if(i == (Bars(this.m_symbol, timeframe) - this.m_halfLength - 1))
           {
            upBuffer[i] = tmBuffer[i];
            dnBuffer[i] = tmBuffer[i];
            if(diff >= 0)
              {
               wuBuffer[i] = MathPow(diff, 2);
               wdBuffer[i] = 0;
              }
            else
              {
               wdBuffer[i] = MathPow(diff, 2);
               wuBuffer[i] = 0;
              }
            continue;
           }

         if(diff >= 0)
           {
            wuBuffer[i] = (wuBuffer[i + 1] * (FullLength - 1) + MathPow(diff, 2)) / FullLength;
            wdBuffer[i] =  wdBuffer[i + 1] * (FullLength - 1) / FullLength;
           }
         else
           {
            wdBuffer[i] = (wdBuffer[i + 1] * (FullLength - 1) + MathPow(diff, 2)) / FullLength;
            wuBuffer[i] =  wuBuffer[i + 1] * (FullLength - 1) / FullLength;
           }
         upBuffer[i] = tmBuffer[i] + this.m_bandsDeviation * MathSqrt(wuBuffer[i]);
         dnBuffer[i] = tmBuffer[i] - this.m_bandsDeviation * MathSqrt(wdBuffer[i]);
        }
     }
   //+------------------------------------------------------------------+

  };
//+------------------------------------------------------------------+
