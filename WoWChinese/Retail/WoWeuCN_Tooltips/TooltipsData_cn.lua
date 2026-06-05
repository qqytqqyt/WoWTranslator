WoWeuCN_Tooltips_base = "12.0.1.66198";   -- version
WoWeuCN_Tooltips_date = "2026-03-02"; -- date of creation base

WoWeuCN_Tooltips_lang = "CN";      -- language

WowenCN_Tooltips_WeekDiff = 86400

WoWeuCN_Tooltips_Messages = {   
    loaded     = "加载完成", 
    isactive   = "已启用", 
    isinactive = "未启用", 
    author     = "Silvermoon (EU) - Nekonia",
 }; 
 
WoWeuCN_Tooltips_Interface = { 
    active     = "激活插件", 
    options1   = "额外选项:", 
    transspell = "翻译法术提示", 
    transitem  = "翻译道具提示",
    nameonly   = "仅显示中文名称（Name only）",
    transunit  = "翻译NPC提示",
    transachievement = "翻译成就面板",
    transadvanced = "高级翻译模式",
    transnameplate = "翻译血条姓名版（需安装Plater插件，/reload后生效）",
 }; 

 WoWeuCN_Tooltips_Font1 = "Interface\\AddOns\\WoWeuCN_Tooltips\\Fonts\\woweucn.ttf"; 
 WoWeuCN_Tooltips_Font2 = "Interface\\AddOns\\WoWeuCN_Tooltips\\Fonts\\woweucn.ttf"; 

 WoWeuCN_Tooltips_TranslateEncounterJournal = true;

 local function initData(typeName)
   for i=0,1500000,100000 do
      local name = "WoWeuCN_Tooltips_" .. typeName .. "Data_".. i
      _G[name] = {};
      local indexName = "WoWeuCN_Tooltips_" .. typeName .. "IndexData_".. i
      _G[indexName] = {};
   end
 end

 initData("Item");
 initData("Spell");
 initData("Unit");
 initData("Achievement");
 
 WoWeuCN_Tooltips_EncounterData ={}
 WoWeuCN_Tooltips_EncounterSectionData ={}
 
 WoWeuCN_Plater_Mod_Text = "!PLATER:2!7VTdahNBGLVCEXwC6dWQm+5CEpL+V4ywNj9EsK1NQi2lhOnuF3fpZmaZnY31bi0UQURBCt54IWJLKbRFBBWtgu/gG9iY9MpXcHeT3SZp1NYLUchAMjM7c77znTMz354Un5un82BNTUemcRkMHXMwk/yuAUmV0hVp+NZMbeOVvyVPqc41w6zf36k+2K7uH1TXN78fPKxurR09s6vrr4+e7tb33x6+f1Tf3/z2+Mnhhzf1vU+1j3uH73ZrW/dqG9tf7TVpaODc+QsvpdEBbaufSiO5aVihZY1GUphx1VTxCjBpvE8au7QgTb64GWSFCobidMpC//OSRWSuUYIEE/RSGFlE41ml0aeZAwgjIJU8XtadUZkq3ki8iJwWiWjEBMaRTBVAKjDwPnt/WgkRylFTbNEXW8wAD7IoOBRJzDHiKhAP5TYG3GKNKRDlOKJOZax7aWUK2SRKoEJzKDRSFn3eYAsmipeEZpogO2ErWLdA8JfFdtpGeGLIWcWJ7XgBMhfGwsjkzDR0jQuhSCgcxBbFAOgwCk1YAhFNR5R1MHqrYgdfh9RWuYHkdtmeVYnTWSpwSqzyMjCfvDVdq6vvLYveuUdVwDpXr2EWdb+5FCcBbvsV4nIOeB5WueBzLsaXxLYIraJbziG4qQk0VXQjzbqzaFOrN0lT5sptO36/HeMXQ8QHFJpJhZacqC0JtSF/7kfggnuv3FctnFyLNvWK7mUY9N/W4O+M+3O7uqXrAYeWupMGzkQlmVOW17gOOQNkDesBe+hKCEWjbbGcaehqSDxbOJXeEc6e/j/kdjsuJ6ugWDq42EYBde4RZxacgiuqmXPgmqV0w7Ta4o/d3vnNHBdtSVHckq32SnavZPdK9n9bsntV+lQG/51q2yavo/RKEztpjnUg3E7dZtQy7JSsY9O0M2VsFDXFtJMMy2BnjYrR3Jc0HVftFC6VtFX7BhCZWoQDa26mOthTTimaja2OjQzjydhELB6PjY6MX+dUrgAzHV8GzvV9+ZzCikJJ2nsCLEMN1zDT/gE="
 WoWeuCN_Plater_Mod_Empty = "nb5tlnpqqy8prf208NMEw9GxcctLEBKL0T2qtZUS72s9wTqrqKxbPGx8AlfH2IiOIwF)YyJj9KFfC1urV97zMNz4zg0cRHGfc151zD3jOuaTdtet1mfc6temeAX5TrWgHSX39JRACESosOYp720ZNLUCv6OjFS6I0Pd3CZG0r3V5655lFC9Z)lF5K3V8Q1V8q(I)N96I1pnpB6PzJN92GHiugdSSTjL9rW1GE(wUEUEEgPdcbS28or8s7rL6wQw02mjcvm2qWdd8jiu1eDnc(FDbAAmlrxu4yjVROadJPkvb2HkokQXwHKgYkirpXFNvYJ32G2Szu)cKLeY7MOzYFxGsWc)Mm8H7VlcK(Eo20QeFILfX1PIjs8WEmPkINGb2ehIj40gnmk4GV(VMRHl0MUQT7b)8"
