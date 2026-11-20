//+------------------------------------------------------------------+
//|                                               UITogglePanel.mqh  |
//|                                    Copyright 2024, Your Name     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Name"
#property link      "https://www.mql5.com"

#ifndef __UI_TOGGLE_PANEL_MQH__
#define __UI_TOGGLE_PANEL_MQH__

#include "UIPanelTypes.mqh"
#include "UIToggleButton.mqh"
#include "UIActionButton.mqh"
#include "UIPersist.mqh"

//+------------------------------------------------------------------+
//| CTogglePanel - Manages a collapsible panel with:                 |
//|   - An optional action button (fires callback)                   |
//|   - A list of toggle buttons                                     |
//+------------------------------------------------------------------+
class CTogglePanel
{
private:
   string          m_name;
   string          m_panelBgName;
   string          m_headerBgName;
   string          m_headerLblName;
   string          m_toggleIconName;

   int             m_rightMargin;
   int             m_x;
   int             m_y;
   int             m_width;
   int             m_headerHeight;
   int             m_buttonHeight;
   int             m_buttonSpacing;
   int             m_padding;

   bool            m_collapsed;
   bool            m_headerHovered;
   bool            m_initialized;

   // Toggle buttons
   CToggleButton   m_buttons[];
   string          m_buttonNames[];
   int             m_buttonCount;

   // Optional action button (only one supported)
   CActionButton   m_actionButton;
   string          m_actionName;
   bool            m_hasAction;

   // Persistence
   string          m_persistScope;
   bool            m_persistEnabled;

public:
   CTogglePanel();
   ~CTogglePanel();

   bool     Create(const string name, int rightMargin, int y, int width,
                   const string title, bool startCollapsed = false);

   // Add the action button ABOVE all toggles. Call this BEFORE AddToggle().
   bool     AddActionButton(const string key, const string label);

   int      AddToggle(const string key, const string label, bool initialState);

   void     Destroy();
   void     RefreshAll();
   void     Reposition();

   // Returns TRUE if a toggle was clicked (state changed internally),
   // FALSE otherwise. If the action button was clicked, `outActionName`
   // receives its key; if a toggle or nothing was clicked, it is cleared.
   bool     OnClick(int chartX, int chartY, string &outActionName);
   bool     OnMouseMove(int chartX, int chartY);

   void     ToggleCollapse();
   void     SetCollapsed(bool collapsed);

   bool     GetState(int index) const;
   bool     GetState(const string key) const;
   bool     SetState(int index, bool state);
   bool     SetState(const string key, bool state);

   bool     IsCollapsed() const { return m_collapsed; }
   int      GetTotalHeight() const;

   // Persistence
   void     EnablePersistence(const string scope);
   void     SaveStates();
   void     LoadStates();
   void     SaveCollapse();
   void     LoadCollapse();

private:
   void     UpdatePanelLayout();
   void     UpdateHeaderAppearance();
   int      FindButtonIndex(const string key) const;
   bool     IsHeaderHit(int chartX, int chartY) const;
   int      GetChartWidth() const;
   int      GetTogglesStartY() const;
};

//+------------------------------------------------------------------+
CTogglePanel::CTogglePanel()
{
   m_name = "";
   m_panelBgName = "";
   m_headerBgName = "";
   m_headerLblName = "";
   m_toggleIconName = "";
   m_rightMargin = 10;
   m_x = 10;
   m_y = 20;
   m_width = UI_PANEL_WIDTH;
   m_headerHeight = UI_HEADER_HEIGHT;
   m_buttonHeight = UI_BUTTON_HEIGHT;
   m_buttonSpacing = UI_BUTTON_SPACING;
   m_padding = UI_PADDING;
   m_collapsed = false;
   m_headerHovered = false;
   m_initialized = false;
   m_buttonCount = 0;
   m_actionName = "";
   m_hasAction = false;
   m_persistScope = "";
   m_persistEnabled = false;
   ArrayResize(m_buttons, 0);
   ArrayResize(m_buttonNames, 0);
}

//+------------------------------------------------------------------+
CTogglePanel::~CTogglePanel()
{
   Destroy();
}

//+------------------------------------------------------------------+
int CTogglePanel::GetChartWidth() const
{
   return (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
}

//+------------------------------------------------------------------+
int CTogglePanel::GetTogglesStartY() const
{
   int y = m_y + m_headerHeight + m_padding;
   if(m_hasAction)
      y += m_buttonHeight + m_buttonSpacing;
   return y;
}

//+------------------------------------------------------------------+
bool CTogglePanel::Create(const string name, int rightMargin, int y, int width,
                          const string title, bool startCollapsed)
{
   m_name = name;
   m_width = width;
   m_y = y;
   m_rightMargin = rightMargin;
   m_collapsed = startCollapsed;

   m_x = GetChartWidth() - m_rightMargin - m_width;

   m_panelBgName    = UI_PREFIX_PANEL  + name + "_BG";
   m_headerBgName   = UI_PREFIX_HEADER + name + "_BG";
   m_headerLblName  = UI_PREFIX_HEADER + name + "_LBL";
   m_toggleIconName = UI_PREFIX_HEADER + name + "_ICON";

   if(!ObjectCreate(0, m_panelBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return false;

   ObjectSetInteger(0, m_panelBgName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_YDISTANCE, m_y);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_XSIZE, m_width);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_YSIZE, m_headerHeight);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_BORDER_COLOR, UI_BORDER_COLOR);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_BGCOLOR, UI_BG_COLOR);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_BACK, false);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, m_panelBgName, OBJPROP_ZORDER, 90);

   if(!ObjectCreate(0, m_headerBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return false;

   ObjectSetInteger(0, m_headerBgName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_YDISTANCE, m_y);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_XSIZE, m_width);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_YSIZE, m_headerHeight);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_BORDER_COLOR, UI_BORDER_COLOR);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_BGCOLOR, UI_HEADER_COLOR);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_BACK, false);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_ZORDER, 95);

   if(!ObjectCreate(0, m_headerLblName, OBJ_LABEL, 0, 0, 0))
      return false;

   ObjectSetInteger(0, m_headerLblName, OBJPROP_XDISTANCE, m_x + 8);
   ObjectSetInteger(0, m_headerLblName, OBJPROP_YDISTANCE, m_y + 5);
   ObjectSetInteger(0, m_headerLblName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, m_headerLblName, OBJPROP_TEXT, title);
   ObjectSetString(0, m_headerLblName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, m_headerLblName, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, m_headerLblName, OBJPROP_COLOR, UI_TEXT_COLOR);
   ObjectSetInteger(0, m_headerLblName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, m_headerLblName, OBJPROP_BACK, false);
   ObjectSetInteger(0, m_headerLblName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, m_headerLblName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, m_headerLblName, OBJPROP_ZORDER, 100);

   if(!ObjectCreate(0, m_toggleIconName, OBJ_LABEL, 0, 0, 0))
      return false;

   ObjectSetInteger(0, m_toggleIconName, OBJPROP_XDISTANCE, m_x + m_width - 8);
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_YDISTANCE, m_y + 5);
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetString(0, m_toggleIconName, OBJPROP_TEXT, m_collapsed ? "▶" : "▼");
   ObjectSetString(0, m_toggleIconName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_COLOR, UI_TEXT_COLOR);
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_BACK, false);
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_ZORDER, 100);

   m_initialized = true;
   UpdatePanelLayout();
   return true;
}

//+------------------------------------------------------------------+
bool CTogglePanel::AddActionButton(const string key, const string label)
{
   if(!m_initialized) return false;
   if(m_hasAction)    return false;

   m_actionName = key;

   int btnX = m_x + m_padding;
   int btnY = m_y + m_headerHeight + m_padding;
   int btnW = m_width - m_padding * 2;

   if(!m_actionButton.Create(key, label, btnX, btnY, btnW, m_buttonHeight))
      return false;

   m_actionButton.SetColors(UI_ACTION_COLOR, UI_ACTION_COLOR_HOVER, UI_ACTION_TEXT_COLOR);
   m_hasAction = true;

   UpdatePanelLayout();
   return true;
}

//+------------------------------------------------------------------+
void CTogglePanel::Destroy()
{
   for(int i = 0; i < m_buttonCount; i++)
      m_buttons[i].Destroy();

   if(m_hasAction)
      m_actionButton.Destroy();

   ArrayResize(m_buttons, 0);
   ArrayResize(m_buttonNames, 0);
   m_buttonCount = 0;
   m_hasAction = false;
   m_actionName = "";

   if(m_panelBgName != "")    ObjectDelete(0, m_panelBgName);
   if(m_headerBgName != "")   ObjectDelete(0, m_headerBgName);
   if(m_headerLblName != "")  ObjectDelete(0, m_headerLblName);
   if(m_toggleIconName != "") ObjectDelete(0, m_toggleIconName);

   m_initialized = false;
}

//+------------------------------------------------------------------+
void CTogglePanel::Reposition()
{
   if(!m_initialized) return;

   int newX = GetChartWidth() - m_rightMargin - m_width;
   if(newX == m_x) return;

   m_x = newX;

   ObjectSetInteger(0, m_panelBgName,  OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(0, m_panelBgName,  OBJPROP_YDISTANCE, m_y);

   ObjectSetInteger(0, m_headerBgName, OBJPROP_XDISTANCE, m_x);
   ObjectSetInteger(0, m_headerBgName, OBJPROP_YDISTANCE, m_y);

   ObjectSetInteger(0, m_headerLblName, OBJPROP_XDISTANCE, m_x + 8);
   ObjectSetInteger(0, m_headerLblName, OBJPROP_YDISTANCE, m_y + 5);

   ObjectSetInteger(0, m_toggleIconName, OBJPROP_XDISTANCE, m_x + m_width - 8);
   ObjectSetInteger(0, m_toggleIconName, OBJPROP_YDISTANCE, m_y + 5);

   if(m_hasAction)
   {
      int actX = m_x + m_padding;
      int actY = m_y + m_headerHeight + m_padding;
      m_actionButton.SetPosition(actX, actY);
   }

   int togglesStartY = GetTogglesStartY();
   for(int i = 0; i < m_buttonCount; i++)
   {
      int btnX = m_x + m_padding;
      int btnY = togglesStartY + i * (m_buttonHeight + m_buttonSpacing);
      m_buttons[i].SetPosition(btnX, btnY);
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
int CTogglePanel::AddToggle(const string key, const string label, bool initialState)
{
   if(!m_initialized) return -1;

   int index = m_buttonCount;
   ArrayResize(m_buttons, index + 1);
   ArrayResize(m_buttonNames, index + 1);
   m_buttonNames[index] = key;

   int togglesStartY = GetTogglesStartY();
   int btnX = m_x + m_padding;
   int btnY = togglesStartY + index * (m_buttonHeight + m_buttonSpacing);
   int btnW = m_width - m_padding * 2;

   if(!m_buttons[index].Create(key, label, btnX, btnY, btnW, m_buttonHeight, initialState))
      return -1;

   m_buttonCount++;
   UpdatePanelLayout();
   return index;
}

//+------------------------------------------------------------------+
void CTogglePanel::RefreshAll()
{
   for(int i = 0; i < m_buttonCount; i++)
      m_buttons[i].Refresh();
   if(m_hasAction)
      m_actionButton.Refresh();
}

//+------------------------------------------------------------------+
int CTogglePanel::FindButtonIndex(const string key) const
{
   for(int i = 0; i < m_buttonCount; i++)
   {
      if(m_buttonNames[i] == key)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
bool CTogglePanel::GetState(int index) const
{
   if(index < 0 || index >= m_buttonCount) return false;
   return m_buttons[index].GetState();
}

//+------------------------------------------------------------------+
bool CTogglePanel::GetState(const string key) const
{
   int idx = FindButtonIndex(key);
   if(idx < 0) return false;
   return m_buttons[idx].GetState();
}

//+------------------------------------------------------------------+
bool CTogglePanel::SetState(int index, bool state)
{
   if(index < 0 || index >= m_buttonCount) return false;
   m_buttons[index].SetState(state);
   SaveStates();
   return true;
}

//+------------------------------------------------------------------+
bool CTogglePanel::SetState(const string key, bool state)
{
   int idx = FindButtonIndex(key);
   if(idx < 0) return false;
   m_buttons[idx].SetState(state);
   SaveStates();
   return true;
}

//+------------------------------------------------------------------+
bool CTogglePanel::IsHeaderHit(int chartX, int chartY) const
{
   return (chartX >= m_x && chartX <= m_x + m_width &&
           chartY >= m_y && chartY <= m_y + m_headerHeight);
}

//+------------------------------------------------------------------+
bool CTogglePanel::OnClick(int chartX, int chartY, string &outActionName)
{
   outActionName = "";

   if(IsHeaderHit(chartX, chartY))
   {
      ToggleCollapse();
      return false;
   }

   if(m_collapsed) return false;

   // Action button first (it sits above toggles)
   if(m_hasAction && m_actionButton.IsHitChart(chartX, chartY))
   {
      outActionName = m_actionName;
      return false;
   }

   // Toggles
   for(int i = 0; i < m_buttonCount; i++)
   {
      if(m_buttons[i].IsHitChart(chartX, chartY))
      {
         m_buttons[i].SetState(!m_buttons[i].GetState());
         SaveStates();
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
bool CTogglePanel::OnMouseMove(int chartX, int chartY)
{
   bool headerHover = IsHeaderHit(chartX, chartY);
   if(headerHover != m_headerHovered)
   {
      m_headerHovered = headerHover;
      UpdateHeaderAppearance();
   }

   if(!m_collapsed)
   {
      if(m_hasAction)
         m_actionButton.SetHover(m_actionButton.IsHitChart(chartX, chartY));

      for(int i = 0; i < m_buttonCount; i++)
         m_buttons[i].SetHover(m_buttons[i].IsHitChart(chartX, chartY));
   }

   return headerHover;
}

//+------------------------------------------------------------------+
void CTogglePanel::UpdatePanelLayout()
{
   int height = m_collapsed ? m_headerHeight : GetTotalHeight();
   ObjectSetInteger(0, m_panelBgName, OBJPROP_YSIZE, height);

   if(m_hasAction)
   {
      int actX = m_x + m_padding;
      int actY = m_y + m_headerHeight + m_padding;
      m_actionButton.SetPosition(actX, actY);
      m_actionButton.Show(!m_collapsed);
   }

   int togglesStartY = GetTogglesStartY();
   for(int i = 0; i < m_buttonCount; i++)
   {
      int btnX = m_x + m_padding;
      int btnY = togglesStartY + i * (m_buttonHeight + m_buttonSpacing);
      m_buttons[i].SetPosition(btnX, btnY);
      m_buttons[i].Show(!m_collapsed);
   }

   ObjectSetString(0, m_toggleIconName, OBJPROP_TEXT, m_collapsed ? "▶" : "▼");
}

//+------------------------------------------------------------------+
void CTogglePanel::UpdateHeaderAppearance()
{
   color bg = m_headerHovered ? UI_HEADER_HOVER : UI_HEADER_COLOR;
   ObjectSetInteger(0, m_headerBgName, OBJPROP_BGCOLOR, bg);
}

//+------------------------------------------------------------------+
void CTogglePanel::ToggleCollapse()
{
   m_collapsed = !m_collapsed;
   UpdatePanelLayout();
   SaveCollapse();
   ChartRedraw();
}

//+------------------------------------------------------------------+
void CTogglePanel::SetCollapsed(bool collapsed)
{
   if(m_collapsed != collapsed)
   {
      m_collapsed = collapsed;
      UpdatePanelLayout();
      SaveCollapse();
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
int CTogglePanel::GetTotalHeight() const
{
   int h = m_headerHeight + m_padding * 2;
   if(m_hasAction)
      h += m_buttonHeight + m_buttonSpacing;
   h += m_buttonCount * (m_buttonHeight + m_buttonSpacing);
   return h;
}

//+------------------------------------------------------------------+
void CTogglePanel::EnablePersistence(const string scope)
{
   m_persistScope = scope;
   m_persistEnabled = true;
   LoadCollapse();
}

//+------------------------------------------------------------------+
void CTogglePanel::SaveStates()
{
   if(!m_persistEnabled) return;
   for(int i = 0; i < m_buttonCount; i++)
   {
      UIPersist_SaveBool(m_persistScope, m_buttonNames[i], m_buttons[i].GetState());
   }
   SaveCollapse();
}

//+------------------------------------------------------------------+
void CTogglePanel::LoadStates()
{
   if(!m_persistEnabled) return;
   for(int i = 0; i < m_buttonCount; i++)
   {
      bool stored = UIPersist_LoadBool(m_persistScope, m_buttonNames[i], m_buttons[i].GetState());
      m_buttons[i].SetState(stored);
   }
}

//+------------------------------------------------------------------+
//| Persist / restore the panel's collapse state                     |
//+------------------------------------------------------------------+
void CTogglePanel::SaveCollapse()
{
   if(!m_persistEnabled) return;
   UIPersist_SaveBool(m_persistScope, "__panel_collapsed", m_collapsed);
}

//+------------------------------------------------------------------+
void CTogglePanel::LoadCollapse()
{
   if(!m_persistEnabled) return;
   bool stored = UIPersist_LoadBool(m_persistScope, "__panel_collapsed", m_collapsed);
   if(stored != m_collapsed)
   {
      m_collapsed = stored;
      UpdatePanelLayout();
   }
}

#endif