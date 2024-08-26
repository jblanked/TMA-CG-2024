# TMA-CG-2024
 Non-repainting triangular moving average original coded by Mladen, edited by JBlanked

All credit goes to Mladen for his idea and humility in sharing the code (TMA-CG-Mladen-NFP)

In this version, I:
- Created a class to simplify use in Indicators, Expert Advisors, and more
- Replaced iCustom(s) with iBarShift
- Created an MT5 version
- Switched init() to OnInit()
- Switched start() to OnCalculate()
- Switched deinit() to OnDeInit()
- Removed alerts
- Converted externs into inputs
- Implemented the CIndicator class
- Changed the string input TimeFrame to ENUM_TIMEFRAMES input inpTimeframe
- Limited the drawing to a maximum of 5000 candles (user input)

If you want to contribute, fork the repository and submit your changes.
