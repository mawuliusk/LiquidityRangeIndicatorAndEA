//+------------------------------------------------------------------+
//|                                                 UIPanelTypes.mqh |
//|                                    Copyright 2024, Your Name     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Name"
#property link      "https://www.mql5.com"

#ifndef __UI_PANEL_TYPES_MQH__
#define __UI_PANEL_TYPES_MQH__

// Panel color scheme
#define UI_BG_COLOR          C'30,30,30'
#define UI_BG_COLOR_DARK     C'20,20,20'
#define UI_BORDER_COLOR      C'80,80,80'
#define UI_TEXT_COLOR        clrWhite
#define UI_TEXT_COLOR_DIM    C'180,180,180'
#define UI_ON_COLOR          C'40,140,60'      // Green background
#define UI_ON_COLOR_HOVER    C'60,180,80'
#define UI_OFF_COLOR         C'140,40,40'      // Red background
#define UI_OFF_COLOR_HOVER   C'180,60,60'
#define UI_HEADER_COLOR      C'50,50,50'
#define UI_HEADER_HOVER      C'70,70,70'

// Action button (grey)
#define UI_ACTION_COLOR       C'100,100,100'
#define UI_ACTION_COLOR_HOVER C'140,140,140'
#define UI_ACTION_TEXT_COLOR  clrWhite

// Panel dimensions
#define UI_PANEL_WIDTH       180
#define UI_HEADER_HEIGHT     24
#define UI_BUTTON_HEIGHT     22
#define UI_BUTTON_SPACING    2
#define UI_PADDING           4

// Object name prefixes (thematically named: LR = LiquidityRange)
#define UI_PREFIX_PANEL      "LRUI_Panel_"
#define UI_PREFIX_HEADER     "LRUI_Header_"
#define UI_PREFIX_BUTTON     "LRUI_Btn_"
#define UI_PREFIX_LABEL      "LRUI_Lbl_"
#define UI_PREFIX_ACTION     "LRUI_Act_"

#endif