//+------------------------------------------------------------------+
//|                                              UIToggleButton.mqh  |
//|                                    Copyright 2024, Your Name     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Name"
#property link      "https://www.mql5.com"

#ifndef __UI_TOGGLE_BUTTON_MQH__
#define __UI_TOGGLE_BUTTON_MQH__

#include "UIPanelTypes.mqh"

//+------------------------------------------------------------------+
//| CToggleButton - Represents a single toggle button                |
//+------------------------------------------------------------------+
class CToggleButton
{
private:
   string   m_name;
   string   m_label;
   string   m_bgName;
   string   m_lblName;
   int      m_x;
   int      m_y;
   int      m_width;
   int      m_height;
   bool     m_state;
   bool     m_hovered;
   color    m_onColor;
   color    m_offColor;
   color    m_onHoverColor;
   color    m_offHoverColor;

public:
   CToggleButton();
   ~CToggleButton();

   bool     Create(const string name, const string label, int x, int y,
                   int width, int height, bool initialState);
   void     Destroy();
   void     SetPosition(int x, int y);
   void     Show(bool visible);
   void     Refresh();

   bool     GetState() const { return m_state; }
   void     SetState(bool state);
   void     SetHover(bool hovered);

   bool     IsHit(int chartX, int chartY) const;
   bool     IsHitChart(int chartX, int chartY) const;

   string   GetName() const { return m_name; }

private:
   void     UpdateBackground();
   void     UpdateLabel();
};

//+------------------------------------------------------------------+
CToggleButton::CToggleButton()
{
   m_name = "";
   m_label = "";
   m_bgName = "";
   m_lblName = "";
   m_x = 0;
   m_y = 0;
   m_width = UI_PANEL_WIDTH - UI_PADDING * 2;
   m_height = UI_BUTTON_HEIGHT;
   m_state = false;
   m_hovered = false;
   m_onColor = UI_ON_COLOR;
   m_offColor = UI_OFF_COLOR;
   m_onHoverColor = UI_ON_COLOR_HOVER;
   m_offHoverColor = UI_OFF_COLOR_HOVER;
}

//+------------------------------------------------------------------+
CToggleButton::~CToggleButton()
{
   Destroy();
}

//+------------------------------------------------------------------+
bool CToggleButton::Create(const string name, const string label, int x, int y,
                           int width, int height, bool initialState)
{
   m_name = name;
   m_label = label;
   m_x = x;
   m_y = y;
   m_width = width;
   m_height = height;
   m_state = initialState;
   m_hovered = false;

   m_bgName  = UI_PREFIX_BUTTON + name + "_BG";
   m_lblName = UI_PREFIX_BUTTON + name + "_LBL";

   // Background rectangle
   if(!ObjectCreate(0, m_bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return false;

   ObjectSetInteger(0, m_bgName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(0, m_bgName, OBJPROP_YDISTANCE, m_y);
   ObjectSetInteger(0, m_bgName, OBJPROP_XSIZE, m_width);
   ObjectSetInteger(0, m_bgName, OBJPROP_YSIZE, m_height);
   ObjectSetInteger(0, m_bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, m_bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, m_bgName, OBJPROP_BORDER_COLOR, UI_BORDER_COLOR);
   ObjectSetInteger(0, m_bgName, OBJPROP_BACK, false);
   ObjectSetInteger(0, m_bgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, m_bgName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, m_bgName, OBJPROP_ZORDER, 100);

   // Label text - anchored at the CENTER of the button
   if(!ObjectCreate(0, m_lblName, OBJ_LABEL, 0, 0, 0))
      return false;

   ObjectSetInteger(0, m_lblName, OBJPROP_XDISTANCE, m_x + m_width / 2);
   ObjectSetInteger(0, m_lblName, OBJPROP_YDISTANCE, m_y + m_height / 2);
   ObjectSetInteger(0, m_lblName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, m_lblName, OBJPROP_TEXT, m_label);
   ObjectSetString(0, m_lblName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, m_lblName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, m_lblName, OBJPROP_COLOR, UI_TEXT_COLOR);
   ObjectSetInteger(0, m_lblName, OBJPROP_ANCHOR, ANCHOR_CENTER);
   ObjectSetInteger(0, m_lblName, OBJPROP_BACK, false);
   ObjectSetInteger(0, m_lblName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, m_lblName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, m_lblName, OBJPROP_ZORDER, 101);

   Refresh();
   return true;
}

//+------------------------------------------------------------------+
void CToggleButton::Destroy()
{
   if(m_bgName != "")  ObjectDelete(0, m_bgName);
   if(m_lblName != "") ObjectDelete(0, m_lblName);
   m_bgName = "";
   m_lblName = "";
}

//+------------------------------------------------------------------+
void CToggleButton::SetPosition(int x, int y)
{
   m_x = x;
   m_y = y;

   ObjectSetInteger(0, m_bgName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(0, m_bgName, OBJPROP_YDISTANCE, m_y);

   ObjectSetInteger(0, m_lblName, OBJPROP_XDISTANCE, m_x + m_width / 2);
   ObjectSetInteger(0, m_lblName, OBJPROP_YDISTANCE, m_y + m_height / 2);
}

//+------------------------------------------------------------------+
void CToggleButton::Show(bool visible)
{
   ObjectSetInteger(0, m_bgName, OBJPROP_TIMEFRAMES, visible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
   ObjectSetInteger(0, m_lblName, OBJPROP_TIMEFRAMES, visible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
}

//+------------------------------------------------------------------+
void CToggleButton::Refresh()
{
   UpdateBackground();
   UpdateLabel();
}

//+------------------------------------------------------------------+
void CToggleButton::SetState(bool state)
{
   m_state = state;
   Refresh();
}

//+------------------------------------------------------------------+
void CToggleButton::SetHover(bool hovered)
{
   if(m_hovered != hovered)
   {
      m_hovered = hovered;
      UpdateBackground();
   }
}

//+------------------------------------------------------------------+
void CToggleButton::UpdateBackground()
{
   color bg;
   if(m_state)
      bg = m_hovered ? m_onHoverColor : m_onColor;
   else
      bg = m_hovered ? m_offHoverColor : m_offColor;

   ObjectSetInteger(0, m_bgName, OBJPROP_BGCOLOR, bg);
}

//+------------------------------------------------------------------+
void CToggleButton::UpdateLabel()
{
   ObjectSetString(0, m_lblName, OBJPROP_TEXT, m_label);
   ObjectSetInteger(0, m_lblName, OBJPROP_COLOR, UI_TEXT_COLOR);
}

//+------------------------------------------------------------------+
bool CToggleButton::IsHitChart(int chartX, int chartY) const
{
   return (chartX >= m_x && chartX <= m_x + m_width &&
           chartY >= m_y && chartY <= m_y + m_height);
}

//+------------------------------------------------------------------+
bool CToggleButton::IsHit(int chartX, int chartY) const
{
   return IsHitChart(chartX, chartY);
}

#endif