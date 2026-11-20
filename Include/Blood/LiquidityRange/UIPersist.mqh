//+------------------------------------------------------------------+
//|                                                    UIPersist.mqh |
//|                                    Copyright 2024, Your Name     |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Name"
#property link      "https://www.mql5.com"

#ifndef __UI_PERSIST_MQH__
#define __UI_PERSIST_MQH__

//+------------------------------------------------------------------+
//| Save a bool value under a named key, scoped to a file            |
//+------------------------------------------------------------------+
void UIPersist_SaveBool(const string scope, const string key, const bool value)
{
   string fileName = "LRUI_" + scope + ".dat";

   int handle = FileOpen(fileName, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      handle = FileOpen(fileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE) return;
      FileWrite(handle, key + "=" + (value ? "1" : "0"));
      FileClose(handle);
      return;
   }

   string lines[];
   int count = 0;
   while(!FileIsEnding(handle))
   {
      string line = FileReadString(handle);
      if(line == "") continue;
      ArrayResize(lines, count + 1);
      lines[count] = line;
      count++;
   }

   bool found = false;
   for(int i = 0; i < count; i++)
   {
      int eq = StringFind(lines[i], "=");
      if(eq <= 0) continue;
      string k = StringSubstr(lines[i], 0, eq);
      if(k == key)
      {
         lines[i] = key + "=" + (value ? "1" : "0");
         found = true;
         break;
      }
   }
   if(!found)
   {
      ArrayResize(lines, count + 1);
      lines[count] = key + "=" + (value ? "1" : "0");
      count++;
   }

   FileClose(handle);
   handle = FileOpen(fileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE) return;
   for(int i = 0; i < count; i++)
      FileWrite(handle, lines[i]);
   FileClose(handle);
}

//+------------------------------------------------------------------+
//| Load a bool; returns defaultValue if not found.                  |
//+------------------------------------------------------------------+
bool UIPersist_LoadBool(const string scope, const string key, const bool defaultValue)
{
   string fileName = "LRUI_" + scope + ".dat";
   int handle = FileOpen(fileName, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE) return defaultValue;

   while(!FileIsEnding(handle))
   {
      string line = FileReadString(handle);
      if(line == "") continue;
      int eq = StringFind(line, "=");
      if(eq <= 0) continue;
      string k = StringSubstr(line, 0, eq);
      if(k == key)
      {
         string v = StringSubstr(line, eq + 1);
         StringTrimLeft(v);
         StringTrimRight(v);
         FileClose(handle);
         return (v == "1" || v == "true" || v == "TRUE");
      }
   }
   FileClose(handle);
   return defaultValue;
}

//+------------------------------------------------------------------+
//| Save a list of string keys to a dedicated file (one per line).   |
//+------------------------------------------------------------------+
void UIPersist_SaveStringList(const string scope, const string &items[])
{
   string fileName = "LRUI_" + scope + ".lst";
   int handle = FileOpen(fileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE) return;

   int n = ArraySize(items);
   for(int i = 0; i < n; i++)
   {
      if(items[i] == "") continue;
      FileWrite(handle, items[i]);
   }
   FileClose(handle);
}

//+------------------------------------------------------------------+
//| Load a list of string keys from a file.                          |
//+------------------------------------------------------------------+
void UIPersist_LoadStringList(const string scope, string &items[])
{
   ArrayResize(items, 0);
   string fileName = "LRUI_" + scope + ".lst";
   int handle = FileOpen(fileName, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE) return;

   int count = 0;
   while(!FileIsEnding(handle))
   {
      string line = FileReadString(handle);
      if(line == "") continue;
      ArrayResize(items, count + 1);
      items[count] = line;
      count++;
   }
   FileClose(handle);
}

#endif