-- Addon: WoWpoPolsku_Quests (wersja: CLASSIC.01) 2018.08.11
-- Opis: AddOn wyświetla przetłumaczone questy w języku polskim.
-- Autor: Platine  (e-mail: platine.wow@gmail.com)
-- Addon project page: https://wowpopolsku.pl

-- Zmienne lokalne
local QTR_version = GetAddOnMetadata("WoWchinese_Quests", "Version");
local QTR_onDebug = false;      
local QTR_name = UnitName("player");
local QTR_class= UnitClass("player");
local QTR_race = UnitRace("player");
local QTR_sex = UnitSex("player");     -- 1:neutral,  2:męski,  3:żeński
local QTR_waitTable = {};
local QTR_waitFrame = nil;
local QTR_MessOrig = {
      details    = "Description", 
      objectives = "Objectives", 
      rewards    = "Rewards", 
      itemchoose1= "You will be able to choose one of these rewards:", 
      itemchoose2= "Choose one of these rewards:", 
      itemreceiv1= "You will also receive:", 
      itemreceiv2= "You receiving the reward:", 
      learnspell = "Learn Spell:", 
      reqmoney   = "Required Money:", 
      reqitems   = "Required items:", 
      experience = "Experience:", 
      currquests = "Current Quests", 
      avaiquests = "Available Quests", };
local QTR_quest_EN = {
      id = 0,
      title = "",
      details = "",
      objectives = "",
      progress = "",
      completion = "",
      itemchoose = "",
      itemreceive = "", };      
local QTR_quest_LG = {
      id = 0,
      title = "",
      details = "",
      objectives = "",
      progress = "",
      completion = "",
      itemchoose = "",
      itemreceive = "", };      
local QTR_Reklama = {
      ON = "Reklamuj dodatek na czacie kanału nr:",
      PERIOD= "Okres czasu pomiędzy kolejnymi reklamami:",
      CHOICE= "Który tekst wyświetlać? (gdy zaznaczysz oba, to naprzemian):",
      OTHER1= "tłumacz w dodatku QuestGuru ",
      OTHER2= "tłumacz w dodatku Immersion ",
      OTHER3= "tłumacz w dodatku Storyline ",
      ACTIV1= "(aktywny)",
      ACTIV2= "(nieaktywny)",
      WWW1  = "Odwiedź stronę WWW dodatku:",
      WWW2  = "https://wowpopolsku.pl",
      WWW3  = "kliknij i wciśnij Ctrl+C aby skopiować do schowka",
      TEXT1 = "WoWpoPolsku-Quests - addon that displays the translated quests (wowpopolsku.pl)",
      TEXT2 = "WoWpoPolsku-Quests - dodatek wyświetlający questy po polsku (wowpopolsku.pl)", };
local last_time = GetTime();
local last_text = 0;
local curr_trans = "1";
local curr_goss = "X";
local curr_hash = 0;
local Original_Font1 = "Fonts\\MORPHEUS.ttf";
local Original_Font2 = "Fonts\\FRIZQT__.ttf";
local p_race = {
      ["Blood Elf"] = { M1="Krwawy Elf", D1="krwawego elfa", C1="krwawemu elfowi", B1="krwawego elfa", N1="krwawym elfem", K1="krwawym elfie", W1="Krwawy Elfie", M2="Krwawa Elfka", D2="krwawej elfki", C2="krwawej elfce", B2="krwawą elfkę", N2="krwawą elfką", K2="krwawej elfce", W2="Krwawa Elfko" }, 
      ["Dark Iron Dwarf"] = { M1="Krasnolud Ciemnego Żelaza", D1="krasnoluda Ciemnego Żelaza", C1="krasnoludowi Ciemnego Żelaza", B1="krasnoluda Ciemnego Żelaza", N1="krasnoludem Ciemnego Żelaza", K1="krasnoludzie Ciemnego Żelaza", W1="Krasnoludzie Ciemnego Żelaza", M2="Krasnoludka Ciemnego Żelaza", D2="krasnoludki Ciemnego Żelaza", C2="krasnoludce Ciemnego Żelaza", B2="krasnoludkę Ciemnego Żelaza", N2="krasnoludką Ciemnego Żelaza", K2="krasnoludce Ciemnego Żelaza", W2="Krasnoludko Ciemnego Żelaza" },
      ["Draenei"] = { M1="Draenei", D1="draeneia", C1="draeneiowi", B1="draeneia", N1="draeneiem", K1="draeneiu", W1="Draeneiu", M2="Draeneika", D2="draeneiki", C2="draeneice", B2="draeneikę", N2="draeneiką", K2="draeneice", W2="Draeneiko" },
      ["Dwarf"] = { M1="Krasnolud", D1="krasnoluda", C1="krasnoludowi", B1="krasnoluda", N1="krasnoludem", K1="krasnoludzie", W1="Krasnoludzie", M2="Krasnoludka", D2="krasnoludki", C2="krasnoludce", B2="krasnoludkę", N2="krasnoludką", K2="krasnoludce", W2="Krasnoludko" },
      ["Gnome"] = { M1="Gnom", D1="gnoma", C1="gnomowi", B1="gnoma", N1="gnomem", K1="gnomie", W1="Gnomie", M2="Gnomka", D2="gnomki", C2="gnomce", B2="gnomkę", N2="gnomką", K2="gnomce", W2="Gnomko" },
      ["Goblin"] = { M1="Goblin", D1="goblina", C1="goblinowi", B1="goblina", N1="goblinem", K1="goblinie", W1="Goblinie", M2="Goblinka", D2="goblinki", C2="goblince", B2="goblinkę", N2="goblinką", K2="goblince", W2="Goblinko" },
      ["Highmountain Tauren"] = { M1="Tauren z Wysokiej Góry", D1="taurena z Wysokiej Góry", C1="taurenowi z Wysokiej Góry", B1="taurena z Wysokiej Góry", N1="taurenen z Wysokiej Góry", K1="taurenie z Wysokiej Góry", W1="Taurenie z Wysokiej Góry", M2="Taurenka z Wysokiej Góry", D2="taurenki z Wysokiej Góry", C2="taurence z Wysokiej Góry", B2="taurenkę z Wysokiej Góry", N2="taurenką z Wysokiej Góry", K2="taurence z Wysokiej Góry", W2="Taurenko z Wysokiej Góry" },
      ["Human"] = { M1="Człowiek", D1="człowieka", C1="człowiekowi", B1="człowieka", N1="człowiekiem", K1="człowieku", W1="Człowieku", M2="Człowiek", D2="człowieka", C2="człowiekowi", B2="człowieka", N2="człowiekiem", K2="człowieku", W2="Człowieku" },
      ["Kul Tiran"] = { M1="Kul Tiran", D1="Kul Tirana", C1="Kul Tiranowi", B1="Kul Tirana", N1="Kul Tiranem", K1="Kul Tiranie", W1="Kul Tiranie", M2="Kul Tiranka", D2="Kul Tiranki", C2="Kul Tirance", B2="Kul Tirankę", N2="Kul Tiranką", K2="Kul Tirance", W2="Kul Tiranko" },
      ["Lightforged Draenei"] = { M1="Świetlisty Draenei", D1="świetlistego draeneia", C1="świetlistemu draeneiowi", B1="świetlistego draeneia", N1="świetlistym draeneiem", K1="świetlistym draeneiu", W1="Świetlisty Draeneiu", M2="Świetlista Draeneika", D2="świetlistej draeneiki", C2="świetlistej draeneice", B2="świetlistą draeneikę", N2="świetlistą draeneiką", K2="świetlistej draeneice", W2="Świetlista Draeneiko" },
      ["Mag'har Orc"] = { M1="Ork z Mag'har", D1="orka z Mag'har", C1="orkowi z Mag'har", B1="orka z Mag'har", N1="orkiem z Mag'har", K1="orku z Mag'har", W1="Orku z Mag'har", M2="Orczyca z Mag'har", D2="orczycy z Mag'har", C2="orczycy z Mag'har", B2="orczycę z Mag'har", N2="orczycą z Mag'har", K2="orczyce z Mag'har", W2="Orczyco z Mag'har" },
      ["Nightborne"] = { M1="Dziecię Nocy", D1="dziecięcia nocy", C1="dziecięciu nocy", B1="dziecię nocy", N1="dziecięcem nocy", K1="dziecięciu nocy", W1="Dziecię Nocy", M2="Dziecię Nocy", D2="dziecięcia nocy", C2="dziecięciu nocy", B2="dziecię nocy", N2="dziecięcem nocy", K2="dziecięciu nocy", W2="Dziecię Nocy" },
      ["Night Elf"] = { M1="Nocny Elf", D1="nocnego elfa", C1="nocnemu elfowi", B1="nocnego elfa", N1="nocnym elfem", K1="nocnym elfie", W1="Nocny Elfie", M2="Nocna Elfka", D2="nocnej elfki", C2="nocnej elfce", B2="nocną elfkę", N2="nocną elfką", K2="nocnej elfce", W2="Nocna Elfko" },
      ["Orc"] = { M1="Ork", D1="orka", C1="orkowi", B1="orka", N1="orkiem", K1="orku", W1="Orku", M2="Orczyca", D2="orczycy", C2="orczycy", B2="orczycę", N2="orczycą", K2="orczycy", W2="Orczyco" },
      ["Pandaren"] = { M1="Pandaren", D1="pandarena", C1="pondarenowi", B1="pandarena", N1="pandarenem", K1="pandarenie", W1="Pandarenie", M2="Pandarenka", D2="pandarenki", C2="pondarence", B2="pandarenkę", N2="pandarenką", K2="pandarence", W2="Pandarenko" },
      ["Tauren"] = { M1="Tauren", D1="taurena", C1="taurenowi", B1="taurena", N1="taurenem", K1="taurenie", W1="Taurenie", M2="Taurenka", D2="taurenki", C2="taurence", B2="taurenkę", N2="taurenką", K2="taurence", W2="Taurenko" },
      ["Troll"] = { M1="Troll", D1="trolla", C1="trollowi", B1="trolla", N1="trollem", K1="trollu", W1="Trollu", M2="Trollica", D2="trollicy", C2="trollicy", B2="trollicę", N2="trollicą", K2="trollicy", W2="Trollico" },
      ["Undead"] = { M1="Nieumarły", D1="nieumarłego", C1="nieumarłemu", B1="nieumarłego", N1="nieumarłym", K1="nieumarłym", W1="Nieumarły", M2="Nieumarła", D2="nieumarłej", C2="nieumarłej", B2="nieumarłą", N2="nieumarłą", K2="nieumarłej", W2="Nieumarła" },
      ["Void Elf"] = { M1="Elf Pustki", D1="elfa Pustki", C1="elfowi Pustki", B1="elfa Pustki", N1="elfem Pustki", K1="elfie Pustki", W1="Elfie Pustki", M2="Elfka Pustki", D2="elfki Pustki", C2="elfce Pustki", B2="elfkę Pustki", N2="elfką Pustki", K2="elfce Pustki", W2="Elfko Pustki" },
      ["Worgen"] = { M1="Worgen", D1="worgena", C1="worgenowi", B1="worgena", N1="worgenem", K1="worgenie", W1="Worgenie", M2="Worgenka", D2="worgenki", C2="worgence", B2="worgenkę", N2="worgenką", K2="worgence", W2="Worgenko" },
      ["Zandalari Troll"] = { M1="Troll Zandalari", D1="trolla Zandalari", C1="trollowi Zandalari", B1="trolla Zandalari", N1="trollem Zandalari", K1="trollu Zandalari", W1="Trollu Zandalari", M2="Trollica Zandalari", D2="trollicy Zandalari", C2="trollicy Zandalari", B2="trollicę Zandalari", N2="trollicą Zandalari", K2="trollicy Zandalari", W2="Trollico Zandalari" }, }
local p_class = {
      ["Death Knight"] = { M1="Rycerz Śmierci", D1="rycerz śmierci", C1="rycerzowi śmierci", B1="rycerza śmierci", N1="rycerzem śmierci", K1="rycerzu śmierci", W1="Rycerzu Śmierci", M2="Rycerz Śmierci", D2="rycerz śmierci", C2="rycerzowi śmierci", B2="rycerza śmierci", N2="rycerzem śmierci", K2="rycerzu śmierci", W2="Rycerzu Śmierci" },
      ["Demon Hunter"] = { M1="Łowca demonów", D1="łowcy demonów", C1="łowcy demonów", B1="łowcę demonów", N1="łowcą demonów", K1="łowcy demonów", W1="Łowco demonów", M2="Łowczyni demonów", D2="łowczyni demonów", C2="łowczyni demonów", B2="łowczynię demonów", N2="łowczynią demonów", K2="łowczyni demonów", W2="Łowczyni demonów" },
      ["Druid"] = { M1="Druid", D1="druida", C1="druidowi", B1="druida", N1="druidem", K1="druidzie", W1="Druidzie", M2="Druidka", D2="druidki", C2="druidce", B2="druikę", N2="druidką", K2="druidce", W2="Druidko" },
      ["Hunter"] = { M1="Łowca", D1="łowcy", C1="łowcy", B1="łowcę", N1="łowcą", K1="łowcy", W1="Łowco", M2="Łowczyni", D2="łowczyni", C2="łowczyni", B2="łowczynię", N2="łowczynią", K2="łowczyni", W2="Łowczyni" },
      ["Mage"] = { M1="Czarodziej", D1="czarodzieja", C1="czarodziejowi", B1="czarodzieja", N1="czarodziejem", K1="czarodzieju", W1="Czarodzieju", M2="Czarodziejka", D2="czarodziejki", C2="czarodziejce", B2="czarodziejkę", N2="czarodziejką", K2="czarodziejce", W2="Czarodziejko" },
      ["Monk"] = { M1="Mnich", D1="mnicha", C1="mnichowi", B1="mnicha", N1="mnichem", K1="mnichu", W1="Mnichu", M2="Mniszka", D2="mniszki", C2="mniszce", B2="mniszkę", N2="mniszką", K2="mniszce", W2="Mniszko" },
      ["Paladin"] = { M1="Paladyn", D1="paladyna", C1="paladynowi", B1="paladyna", N1="paladynem", K1="paladynie", W1="Paladynie", M2="Paladynka", D2="paladynki", C2="paladynce", B2="paladynkę", N2="paladynką", K2="paladynce", W2="Paladynko" },
      ["Priest"] = { M1="Kapłan", D1="kapłana", C1="kapłanowi", B1="kapłana", N1="kapłanem", K1="kapłanie", W1="Kapłanie", M2="Kapłanka", D2="kapłanki", C2="kapłance", B2="kapłankę", N2="kapłanką", K2="kapłance", W2="Kapłanko" },
      ["Rogue"] = { M1="Łotrzyk", D1="łotrzyka", C1="łotrzykowi", B1="łotrzyka", N1="łotrzykiem", K1="łotrzyku", W1="Łotrzyku", M2="Łotrzyca", D2="łotrzycy", C2="łotrzycy", B2="łotrzycę", N2="łotrzycą", K2="łotrzycy", W2="Łotrzyco" },
      ["Shaman"] = { M1="Szaman", D1="szamana", C1="szamanowi", B1="szamana", N1="szamanem", K1="szamanie", W1="Szamanie", M2="Szamanka", D2="szamanki", C2="szamance", B2="szamankę", N2="szamanką", K2="szamance", W2="Szamanko" },
      ["Warlock"] = { M1="Czarnoksiężnik", D1="czarnoksiężnika", C1="czarnoksiężnikowi", B1="czarnoksiężnika", N1="czarnoksiężnikiem", K1="czarnoksiężniku", W1="Czarnoksiężniku", M2="Czarnoksiężniczka", D2="czarnoksiężniczki", C2="czarnoksiężniczce", B2="czarnoksiężniczkę", N2="czarnoksiężniczką", K2="czarnoksiężniczce", W2="Czarnoksiężniczko" },
      ["Warrior"] = { M1="Wojownik", D1="wojownika", C1="wojownikowi", B1="wojownika", N1="wojownikiem", K1="wojowniku", W1="Wojowniku", M2="Wojowniczka", D2="wojowniczki", C2="wojowniczce", B2="wojowniczkę", N2="wojowniczką", K2="wojowniczce", W2="Wojowniczko" }, }
if (p_race[QTR_race]) then      
   player_race = { M1=p_race[QTR_race].M1, D1=p_race[QTR_race].D1, C1=p_race[QTR_race].C1, B1=p_race[QTR_race].B1, N1=p_race[QTR_race].N1, K1=p_race[QTR_race].K1, W1=p_race[QTR_race].W1, M2=p_race[QTR_race].M2, D2=p_race[QTR_race].D2, C2=p_race[QTR_race].C2, B2=p_race[QTR_race].B2, N2=p_race[QTR_race].N2, K2=p_race[QTR_race].K2, W2=p_race[QTR_race].W2 };
else   
   player_race = { M1=QTR_race, D1=QTR_race, C1=QTR_race, B1=QTR_race, N1=QTR_race, K1=QTR_race, W1=QTR_race, M2=QTR_race, D2=QTR_race, C2=QTR_race, B2=QTR_race, N2=QTR_race, K2=QTR_race, W2=QTR_race };
   print ("|cff55ff00QTR - nowa rasa: "..QTR_race);
end
if (p_class[QTR_class]) then
   player_class = { M1=p_class[QTR_class].M1, D1=p_class[QTR_class].D1, C1=p_class[QTR_class].C1, B1=p_class[QTR_class].B1, N1=p_class[QTR_class].N1, K1=p_class[QTR_class].K1, W1=p_class[QTR_class].W1, M2=p_class[QTR_class].M2, D2=p_class[QTR_class].D2, C2=p_class[QTR_class].C2, B2=p_class[QTR_class].B2, N2=p_class[QTR_class].N2, K2=p_class[QTR_class].K2, W2=p_class[QTR_class].W2 };
else
   player_class = { M1=QTR_class, D1=QTR_class, C1=QTR_class, B1=QTR_class, N1=QTR_class, K1=QTR_class, W1=QTR_class, M2=QTR_class, D2=QTR_class, C2=QTR_class, B2=QTR_class, N2=QTR_class, K2=QTR_class, W2=QTR_class };
   print ("|cff55ff00QTR - nowa klasa: "..QTR_class);
end


local function StringHash(text)           -- funkcja tworząca Hash (32-bitowa liczba) podanego tekstu
  local counter = 1;
  local pomoc = 0;
  local dlug = string.len(text);
  for i = 1, dlug, 3 do 
    counter = math.fmod(counter*8161, 4294967279);  -- 2^32 - 17: Prime!
    pomoc = (string.byte(text,i)*16776193);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+1) or (dlug-i+256))*8372226);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+2) or (dlug-i+256))*3932164);
    counter = counter + pomoc;
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end


-- Zmienne programowe zapisane na stałe na komputerze
function QTR_CheckVars()
  if (not QTR_PS) then
     QTR_PS = {};
  end
  if (not QTR_SAVED) then
     QTR_SAVED = {};
  end
  if (not QTR_MISSING) then
     QTR_MISSING = {};
  end
  if (not QTR_GOSSIP) then
     QTR_GOSSIP = {};
  end
  if (not QTR_CONTROL) then
     QTR_CONTROL = {};
  end
  -- inicjalizacja: tłumaczenia włączone
  if (not QTR_PS["active"]) then
     QTR_PS["active"] = "1";
  end
  -- inicjalizacja: tłumaczenie tytułu questu włączone
  if (not QTR_PS["transtitle"] ) then
     QTR_PS["transtitle"] = "0";   
  end
  -- zmienna specjalna dostępności funkcji GetQuestID 
  if ( QTR_PS["isGetQuestID"] ) then
     isGetQuestID=QTR_PS["isGetQuestID"];
  end;
  -- okresowe wyświetlanie reklam o dodatku 
  if (not QTR_PS["reklama"] ) then
     QTR_PS["reklama"] = "0";
     QTR_PS["period"] = 20;
     QTR_PS["text1"] = "0";
     QTR_PS["text2"] = "1";
     QTR_PS["channel"] = "0";
  end;
  if (not QTR_PS["other1"] ) then
     QTR_PS["other1"] = "1";
  end;
  if (not QTR_PS["other2"] ) then
     QTR_PS["other2"] = "1";
  end;
  if (not QTR_PS["other3"] ) then
     QTR_PS["other3"] = "1";
  end;
  if (not QTR_PS["channel"] ) then
     QTR_PS["channel"] = "0";
  end;
   -- zapis kontrolny oryginalnych questów EN
  if (not QTR_PS["control"]) then
     QTR_PS["control"] = "1";
  end
   -- zapis wersji patcha Wow'a
  if (not QTR_PS["patch"]) then
     QTR_PS["patch"] = GetBuildInfo();
  end
 -- jeszcze nazwa gracza w przepadkach / per character
  if (not QTR_PC) then
     QTR_PC = {};
  end
  if (not QTR_PC["name1"] ) then
     QTR_PC["name1"] = QTR_name;
  end;
  if (not QTR_PC["name2"] ) then
     QTR_PC["name2"] = QTR_name.."a";
  end;
  if (not QTR_PC["name3"] ) then
     QTR_PC["name3"] = QTR_name.."owi";
  end;
  if (not QTR_PC["name4"] ) then
     QTR_PC["name4"] = QTR_name.."a";
  end;
  if (not QTR_PC["name5"] ) then
     QTR_PC["name5"] = QTR_name.."em";
  end;
  if (not QTR_PC["name6"] ) then
     QTR_PC["name6"] = QTR_name.."ie";
  end;
  if (not QTR_PC["name7"] ) then
     QTR_PC["name7"] = QTR_name;
  end;
  QTR_GS = {};       -- tablica na teksty oryginalne
end


-- Sprawdza dostępność funkcji specjalnej Wow'a: GetQuestID()
function DetectEmuServer()
  QTR_PS["isGetQuestID"]="0";
  isGetQuestID="0";
  -- funkcja GetQuestID() występuje tylko na oryginalnych serwerach Blizzarda
  if ( GetQuestID() ) then
     QTR_PS["isGetQuestID"]="1";
     isGetQuestID="1";
  end
end


-- Obsługa komend slash
function QTR_SlashCommand(msg)
   if (msg=="on" or msg=="ON") then
      if (QTR_PS["active"]=="1") then
         print ("QTR - tłumaczenie są włączone.");
      else
         print ("|cffffff00QTR - włączam tłumaczenie.");
         QTR_PS["active"] = "1";
         QTR_ToggleButton0:Enable();
         QTR_ToggleButton1:Enable();
         QTR_ToggleButton2:Enable();
         if (isQuestGuru()) then
            QTR_ToggleButton3:Enable();
         end
         if (isImmersion()) then
            QTR_ToggleButton4:Enable();
         end
         QTR_Translate_On(1);
      end
   elseif (msg=="off" or msg=="OFF") then
      if (QTR_PS["active"]=="0") then
         print ("QTR - tłumaczenia są wyłączone.");
      else
         print ("|cffffff00QTR - wyłączam tłumaczenia.");
         QTR_PS["active"] = "0";
         QTR_ToggleButton0:Disable();
         QTR_ToggleButton1:Disable();
         QTR_ToggleButton2:Disable();
         if (isQuestGuru()) then
            QTR_ToggleButton3:Disable();
         end
         if (isImmersion()) then
            QTR_ToggleButton4:Disable();
         end
         QTR_Translate_Off(1);
      end
   elseif (msg=="title on" or msg=="TITLE ON" or msg=="title 1") then
      if (QTR_PS["transtilte"]=="1") then
         print ("QTR - tłumaczenie tytułów jest włączone.");
      else
         print ("|cffffff00QTR - włączam tłumaczenie tytułów.");
         QTR_PS["transtitle"] = "1";
         QuestInfoTitleHeader:SetFont(QTR_Font1, 18);
      end
   elseif (msg=="title off" or msg=="TITLE OFF" or msg=="title 0") then
      if (QTR_PS["transtilte"]=="0") then
         print ("QTR - tłumaczenie tytułów jest wyłączone.");
      else
         print ("|cffffff00QTR - wyłączam tłumaczenie tytułów.");
         QTR_PS["transtitle"] = "0";
         QuestInfoTitleHeader:SetFont(Original_Font1, 18);
      end
   elseif (msg=="title" or msg=="TITLE") then
      if (QTR_PS["transtilte"]=="1") then
         print ("QTR - tłumaczenie tytułów jest włączone.");
      else
         print ("QTR - tłumaczenie tytułów jest wyłączone.");
      end
   elseif (msg=="") then
      InterfaceOptionsFrame_Show();
      InterfaceOptionsFrame_OpenToCategory("WoWpoPolsku-Quests");
   else
      print ("QTR - menu szybkich komend addonu:");
      print ("      /qtr on  - włącza tłumaczenia");
      print ("      /qtr off - wyłącza tłumaczenia");
      print ("      /qtr title on  - włącza tłumaczenie tytułu");
      print ("      /qtr title off - wyłącza tłumaczenie tytułu");
   end
   if (QTR_PS["reklama"]=="1") then
      QTR_SendReklama();
   end
end



function QTR_SetCheckButtonState()
  QTRCheckButton0:SetChecked(QTR_PS["active"]=="1");
  QTRCheckButton3:SetChecked(QTR_PS["transtitle"]=="1");
  QTRCheckButton5:SetChecked(QTR_PS["reklama"]=="1");
  QTRCheckText1:SetChecked(QTR_PS["text1"]=="1");
  QTRCheckText2:SetChecked(QTR_PS["text2"]=="1");
  QTRCheckOther1:SetChecked(QTR_PS["other1"]=="1");
  QTRCheckOther2:SetChecked(QTR_PS["other2"]=="1");
  QTRCheckOther3:SetChecked(QTR_PS["other3"]=="1");
  QTREditBox:SetText(QTR_PS["channel"]);
  QTREditP1:SetText(QTR_PC["name1"]);
  QTREditP2:SetText(QTR_PC["name2"]);
  QTREditP3:SetText(QTR_PC["name3"]);
  QTREditP4:SetText(QTR_PC["name4"]);
  QTREditP5:SetText(QTR_PC["name5"]);
  QTREditP6:SetText(QTR_PC["name6"]);
  QTREditP7:SetText(QTR_PC["name7"]);
end



function QTR_BlizzardOptions()
  -- Create main frame for information text
  local QTROptions = CreateFrame("FRAME", "WoWchinese_Quests_Options");
  QTROptions.name = "WoWchinese-Quests";
  QTROptions.refresh = function (self) QTR_SetCheckButtonState() end;
  InterfaceOptions_AddCategory(QTROptions);

  local QTROptionsHeader = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsHeader:SetFontObject(GameFontNormalLarge);
  QTROptionsHeader:SetJustifyH("LEFT"); 
  QTROptionsHeader:SetJustifyV("TOP");
  QTROptionsHeader:ClearAllPoints();
  QTROptionsHeader:SetPoint("TOPLEFT", 16, -16);
  QTROptionsHeader:SetText("WoWchinese-Quests, ver. "..QTR_version.." ("..QTR_base..") by Platine © 2010-2018");

  local QTRDateOfBase = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRDateOfBase:SetFontObject(GameFontNormalLarge);
  QTRDateOfBase:SetJustifyH("LEFT"); 
  QTRDateOfBase:SetJustifyV("TOP");
  QTRDateOfBase:ClearAllPoints();
  QTRDateOfBase:SetPoint("TOPRIGHT", QTROptionsHeader, "TOPRIGHT", 0, -22);
  QTRDateOfBase:SetText("Data bazy tłumaczeń: "..QTR_date);
  QTRDateOfBase:SetFont(QTR_Font2, 16);

  local QTRCheckButton0 = CreateFrame("CheckButton", "QTRCheckButton0", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton0:SetPoint("TOPLEFT", QTROptionsHeader, "BOTTOMLEFT", 0, -20);
  QTRCheckButton0:SetScript("OnClick", function(self) if (QTR_PS["active"]=="1") then QTR_PS["active"]="0" else QTR_PS["active"]="1" end; end);
  QTRCheckButton0Text:SetFont(QTR_Font2, 13);
  QTRCheckButton0Text:SetText(QTR_Interface.active);

  local QTROptionsMode1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsMode1:SetFontObject(GameFontWhite);
  QTROptionsMode1:SetJustifyH("LEFT");
  QTROptionsMode1:SetJustifyV("TOP");
  QTROptionsMode1:ClearAllPoints();
  QTROptionsMode1:SetPoint("TOPLEFT", QTRCheckButton0, "BOTTOMLEFT", 30, -20);
  QTROptionsMode1:SetFont(QTR_Font2, 13);
  QTROptionsMode1:SetText(QTR_Interface.options1);
  
  local QTRCheckButton3 = CreateFrame("CheckButton", "QTRCheckButton3", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton3:SetPoint("TOPLEFT", QTROptionsMode1, "BOTTOMLEFT", 0, -5);
  QTRCheckButton3:SetScript("OnClick", function(self) if (QTR_PS["transtitle"]=="0") then QTR_PS["transtitle"]="1" else QTR_PS["transtitle"]="0" end; end);
  QTRCheckButton3Text:SetFont(QTR_Font2, 13);
  QTRCheckButton3Text:SetText(QTR_Interface.transtitle);

  local QTROptionsMode2 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTROptionsMode2:SetFontObject(GameFontWhite);
  QTROptionsMode2:SetJustifyH("LEFT");
  QTROptionsMode2:SetJustifyV("TOP");
  QTROptionsMode2:ClearAllPoints();
  QTROptionsMode2:SetPoint("TOPLEFT", QTROptionsMode1, "TOPRIGHT", 70, 0);
  QTROptionsMode2:SetFont(QTR_Font2, 13);
  QTROptionsMode2:SetText("Nazwa gracza w różnych przypadkach:");
  
  local QTREditP1 = CreateFrame("EditBox", "QTREditP1", QTROptions, "InputBoxTemplate");
  QTREditP1:SetPoint("TOPRIGHT", QTROptionsMode2, "BOTTOMRIGHT", 0, -10);
  QTREditP1:SetHeight(20);
  QTREditP1:SetWidth(100);
  QTREditP1:SetAutoFocus(false);
  QTREditP1:SetText(QTR_PC["name1"]);
  QTREditP1:SetCursorPosition(0);
  QTREditP1:SetScript("OnTextChanged", function(self) if (strlen(QTREditP1:GetText())>0) then QTR_PC["name1"]=QTREditP1:GetText() end; end);

  local QTRName1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRName1:SetFontObject(GameFontNormalLarge);
  QTRName1:SetJustifyH("LEFT"); 
  QTRName1:SetJustifyV("TOP");
  QTRName1:ClearAllPoints();
  QTRName1:SetPoint("TOPRIGHT", QTREditP1, "TOPLEFT", -8, -4);
  QTRName1:SetText("Mianownik:");
  QTRName1:SetFont(QTR_Font2, 13);

  local QTREditP2 = CreateFrame("EditBox", "QTREditP2", QTROptions, "InputBoxTemplate");
  QTREditP2:SetPoint("TOPRIGHT", QTREditP1, "BOTTOMRIGHT", 0, 0);
  QTREditP2:SetHeight(20);
  QTREditP2:SetWidth(100);
  QTREditP2:SetAutoFocus(false);
  QTREditP2:SetText(QTR_PC["name2"]);
  QTREditP2:SetCursorPosition(0);
  QTREditP2:SetScript("OnTextChanged", function(self) if (strlen(QTREditP2:GetText())>0) then QTR_PC["name2"]=QTREditP2:GetText() end; end);

  local QTRName2 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRName2:SetFontObject(GameFontNormalLarge);
  QTRName2:SetJustifyH("LEFT"); 
  QTRName2:SetJustifyV("TOP");
  QTRName2:ClearAllPoints();
  QTRName2:SetPoint("TOPRIGHT", QTREditP2, "TOPLEFT", -8, -4);
  QTRName2:SetText("Dopełniacz:");
  QTRName2:SetFont(QTR_Font2, 13);

  local QTREditP3 = CreateFrame("EditBox", "QTREditP3", QTROptions, "InputBoxTemplate");
  QTREditP3:SetPoint("TOPRIGHT", QTREditP2, "BOTTOMRIGHT", 0, 0);
  QTREditP3:SetHeight(20);
  QTREditP3:SetWidth(100);
  QTREditP3:SetAutoFocus(false);
  QTREditP3:SetText(QTR_PC["name3"]);
  QTREditP3:SetCursorPosition(0);
  QTREditP3:SetScript("OnTextChanged", function(self) if (strlen(QTREditP3:GetText())>0) then QTR_PC["name3"]=QTREditP3:GetText() end; end);

  local QTRName3 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRName3:SetFontObject(GameFontNormalLarge);
  QTRName3:SetJustifyH("LEFT"); 
  QTRName3:SetJustifyV("TOP");
  QTRName3:ClearAllPoints();
  QTRName3:SetPoint("TOPRIGHT", QTREditP3, "TOPLEFT", -8, -4);
  QTRName3:SetText("Celownik:");
  QTRName3:SetFont(QTR_Font2, 13);

  local QTREditP4 = CreateFrame("EditBox", "QTREditP4", QTROptions, "InputBoxTemplate");
  QTREditP4:SetPoint("TOPRIGHT", QTREditP3, "BOTTOMRIGHT", 0, 0);
  QTREditP4:SetHeight(20);
  QTREditP4:SetWidth(100);
  QTREditP4:SetAutoFocus(false);
  QTREditP4:SetText(QTR_PC["name4"]);
  QTREditP4:SetCursorPosition(0);
  QTREditP4:SetScript("OnTextChanged", function(self) if (strlen(QTREditP4:GetText())>0) then QTR_PC["name4"]=QTREditP4:GetText() end; end);

  local QTRName4 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRName4:SetFontObject(GameFontNormalLarge);
  QTRName4:SetJustifyH("LEFT"); 
  QTRName4:SetJustifyV("TOP");
  QTRName4:ClearAllPoints();
  QTRName4:SetPoint("TOPRIGHT", QTREditP4, "TOPLEFT", -8, -4);
  QTRName4:SetText("Biernik:");
  QTRName4:SetFont(QTR_Font2, 13);

  local QTREditP5 = CreateFrame("EditBox", "QTREditP5", QTROptions, "InputBoxTemplate");
  QTREditP5:SetPoint("TOPRIGHT", QTREditP4, "BOTTOMRIGHT", 0, 0);
  QTREditP5:SetHeight(20);
  QTREditP5:SetWidth(100);
  QTREditP5:SetAutoFocus(false);
  QTREditP5:SetText(QTR_PC["name5"]);
  QTREditP5:SetCursorPosition(0);
  QTREditP5:SetScript("OnTextChanged", function(self) if (strlen(QTREditP5:GetText())>0) then QTR_PC["name5"]=QTREditP5:GetText() end; end);

  local QTRName5 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRName5:SetFontObject(GameFontNormalLarge);
  QTRName5:SetJustifyH("LEFT"); 
  QTRName5:SetJustifyV("TOP");
  QTRName5:ClearAllPoints();
  QTRName5:SetPoint("TOPRIGHT", QTREditP5, "TOPLEFT", -8, -4);
  QTRName5:SetText("Narzędnik:");
  QTRName5:SetFont(QTR_Font2, 13);

  local QTREditP6 = CreateFrame("EditBox", "QTREditP6", QTROptions, "InputBoxTemplate");
  QTREditP6:SetPoint("TOPRIGHT", QTREditP5, "BOTTOMRIGHT", 0, 0);
  QTREditP6:SetHeight(20);
  QTREditP6:SetWidth(100);
  QTREditP6:SetAutoFocus(false);
  QTREditP6:SetText(QTR_PC["name6"]);
  QTREditP6:SetCursorPosition(0);
  QTREditP6:SetScript("OnTextChanged", function(self) if (strlen(QTREditP6:GetText())>0) then QTR_PC["name6"]=QTREditP6:GetText() end; end);

  local QTRName6 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRName6:SetFontObject(GameFontNormalLarge);
  QTRName6:SetJustifyH("LEFT"); 
  QTRName6:SetJustifyV("TOP");
  QTRName6:ClearAllPoints();
  QTRName6:SetPoint("TOPRIGHT", QTREditP6, "TOPLEFT", -8, -4);
  QTRName6:SetText("Miejscownik:");
  QTRName6:SetFont(QTR_Font2, 13);

  local QTREditP7 = CreateFrame("EditBox", "QTREditP7", QTROptions, "InputBoxTemplate");
  QTREditP7:SetPoint("TOPRIGHT", QTREditP6, "BOTTOMRIGHT", 0, 0);
  QTREditP7:SetHeight(20);
  QTREditP7:SetWidth(100);
  QTREditP7:SetAutoFocus(false);
  QTREditP7:SetText(QTR_PC["name7"]);
  QTREditP7:SetCursorPosition(0);
  QTREditP7:SetScript("OnTextChanged", function(self) if (strlen(QTREditP7:GetText())>0) then QTR_PC["name7"]=QTREditP7:GetText() end; end);

  local QTRName7 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRName7:SetFontObject(GameFontNormalLarge);
  QTRName7:SetJustifyH("LEFT"); 
  QTRName7:SetJustifyV("TOP");
  QTRName7:ClearAllPoints();
  QTRName7:SetPoint("TOPRIGHT", QTREditP7, "TOPLEFT", -8, -4);
  QTRName7:SetText("Wołacz:");
  QTRName7:SetFont(QTR_Font2, 13);

  local QTRCheckButton5 = CreateFrame("CheckButton", "QTRCheckButton5", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckButton5:SetPoint("TOPLEFT", QTRCheckButton3, "BOTTOMLEFT", 0, -20);
  QTRCheckButton5:SetScript("OnClick", function(self) if (QTR_PS["reklama"]=="0") then QTR_PS["reklama"]="1" else QTR_PS["reklama"]="0" end; end);
  QTRCheckButton5Text:SetFont(QTR_Font2, 13);
  QTRCheckButton5Text:SetText(QTR_Reklama.ON);

  local QTREditBox = CreateFrame("EditBox", "QTREditBox", QTROptions, "InputBoxTemplate");
  QTREditBox:SetPoint("TOPLEFT", QTRCheckButton5Text, "TOPRIGHT", 10, 3);
  QTREditBox:SetHeight(20);
  QTREditBox:SetWidth(20);
  QTREditBox:SetAutoFocus(false);
  QTREditBox:SetText(QTR_PS["channel"]);
  QTREditBox:SetCursorPosition(0);
  QTREditBox:SetScript("OnTextChanged", function(self) if (strlen(QTREditBox:GetText())>0) then QTR_PS["channel"]=QTREditBox:GetText() end; end);

--  local QTRChannelsFrame = CreateFrame("frame", "QTRChannelsFrame", QTROptions, "UIDropDownMenuTemplate")
--  QTRChannelsFrame:SetPoint("TOPLEFT", QTREditBox, "BOTTOMRIGHT", -150, 0);
--  UIDropDownMenu_SetText(QTRChannelsFrame, "Dostepne kanały:");
--  QTRChannelsFrame.onClick = function(self, arg1, arg2, checked) QTREditBox:SetText(arg1); end
--  QTRChannelsFrame.initialize = function(self, level)
--	  local info = UIDropDownMenu_CreateInfo();
--     info.text = "0: LocalArea SAY";
--     info.value= "0";
--     info.func = self.onClick;
--     info.arg1 = "0";
--     info.arg2 = "LocalArea SAY";
--     UIDropDownMenu_AddButton(info, level);
--     local ind1 = "0";
--     for ind,nam in ipairs({GetChannelList()}) do
--        if nam and (strlen(nam)==1) then
--           ind1 = nam;      -- channel number     
--        else
--           info.text = ind1 .. ": " .. nam;        -- nam wychodzi jako BOOLEAN
--           info.value= ind1;
--           info.func = self.onClick;
--           info.arg1 = ind1;
--           info.arg2 = nam;
--           UIDropDownMenu_AddButton(info, level);
--	     end
--     end
--  end   
  
  local QTRPeriodText = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRPeriodText:SetFontObject(GameFontWhite);
  QTRPeriodText:SetJustifyH("LEFT");
  QTRPeriodText:SetJustifyV("TOP");
  QTRPeriodText:ClearAllPoints();
  QTRPeriodText:SetPoint("TOPLEFT", QTRCheckButton5, "BOTTOMLEFT", 30, -20);
  QTRPeriodText:SetFont(QTR_Font2, 13);
  QTRPeriodText:SetText(QTR_Reklama.PERIOD);
  
  local QTR_slider = CreateFrame("Slider","MyAddonSlider",QTROptions,'OptionsSliderTemplate');
  QTR_slider:ClearAllPoints();
  QTR_slider:SetPoint("TOPLEFT",QTRPeriodText, "BOTTOMLEFT", 80, -30);
  getglobal(QTR_slider:GetName() .. 'Low'):SetText('15 min.');
  getglobal(QTR_slider:GetName() .. 'High'):SetText('90 min.');
  getglobal(QTR_slider:GetName() .. 'Text'):SetText('20 min.');
  QTR_slider:SetMinMaxValues(15, 90);
  QTR_slider:SetValue(QTR_PS["period"]);
  getglobal(QTR_slider:GetName() .. 'Text'):SetText(QTR_PS["period"] .. " min.");
  QTR_slider:SetValueStep(5);
  QTR_slider:SetScript("OnValueChanged", function(self)
      QTR_PS["period"] = math.floor(QTR_slider:GetValue()+0.5);
      getglobal(QTR_slider:GetName() .. 'Text'):SetText(QTR_PS["period"] .. " min.");
      end);

  local QTRChoiceText = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRChoiceText:SetFontObject(GameFontWhite);
  QTRChoiceText:SetJustifyH("LEFT");
  QTRChoiceText:SetJustifyV("TOP");
  QTRChoiceText:ClearAllPoints();
  QTRChoiceText:SetPoint("TOPLEFT", QTRPeriodText, "BOTTOMLEFT", -50, -80);
  QTRChoiceText:SetFont(QTR_Font2, 13);
  QTRChoiceText:SetText(QTR_Reklama.CHOICE);
  
  local QTRCheckText1 = CreateFrame("CheckButton", "QTRCheckText1", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckText1:SetPoint("TOPLEFT", QTRChoiceText, "BOTTOMLEFT", -10, -10);
  QTRCheckText1:SetScript("OnClick", function(self) if (QTR_PS["text1"]=="0") then QTR_PS["text1"]="1" else QTR_PS["text1"]="0" end; end);
  QTRCheckText1Text:SetFont(QTR_Font2, 13);
  QTRCheckText1Text:SetText(QTR_Reklama.TEXT1);

  local QTRCheckText2 = CreateFrame("CheckButton", "QTRCheckText2", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckText2:SetPoint("TOPLEFT", QTRCheckText1, "BOTTOMLEFT", 0, 0);
  QTRCheckText2:SetScript("OnClick", function(self) if (QTR_PS["text2"]=="0") then QTR_PS["text2"]="1" else QTR_PS["text2"]="0" end; end);
  QTRCheckText2Text:SetFont(QTR_Font2, 13);
  QTRCheckText2Text:SetText(QTR_Reklama.TEXT2);
  
  local QTRIntegration0 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRIntegration0:SetFontObject(GameFontWhite);
  QTRIntegration0:SetJustifyH("LEFT");
  QTRIntegration0:SetJustifyV("TOP");
  QTRIntegration0:ClearAllPoints();
  QTRIntegration0:SetPoint("TOPLEFT", QTRCheckText2, "BOTTOMLEFT", 0, -20);
  QTRIntegration0:SetFont(QTR_Font2, 13);
  QTRIntegration0:SetText("Integracja z innymi addonami:");
  
  local QTRIntegration1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRIntegration1:SetFontObject(GameFontNormal);
  QTRIntegration1:SetJustifyH("LEFT");
  QTRIntegration1:SetJustifyV("TOP");
  QTRIntegration1:ClearAllPoints();
  QTRIntegration1:SetPoint("TOPLEFT", QTRIntegration0, "TOPRIGHT", 15, 0);
  QTRIntegration1:SetFont(QTR_Font2, 13);
  QTRIntegration1:SetText("QuestGuru,  Immersion,  Storyline");

  local QTRCheckOther1 = CreateFrame("CheckButton", "QTRCheckOther1", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckOther1:SetPoint("TOPLEFT", QTRIntegration1, "BOTTOMLEFT", -10, -10);
  QTRCheckOther1:SetScript("OnClick", function(self) if (QTR_PS["other1"]=="0") then QTR_PS["other1"]="1" else QTR_PS["other1"]="0" end; end);
  QTRCheckOther1Text:SetFont(QTR_Font2, 13);
  if (QuestGuru ~= nil ) then
     QTRCheckOther1Text:SetText(QTR_Reklama.OTHER1..QTR_Reklama.ACTIV1);
  else
     QTRCheckOther1Text:SetText(QTR_Reklama.OTHER1..QTR_Reklama.ACTIV2);
  end

  local QTRCheckOther2 = CreateFrame("CheckButton", "QTRCheckOther2", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckOther2:SetPoint("TOPLEFT", QTRCheckOther1, "BOTTOMLEFT", 0, 0);
  QTRCheckOther2:SetScript("OnClick", function(self) if (QTR_PS["other2"]=="0") then QTR_PS["other2"]="1" else QTR_PS["other2"]="0" end; end);
  QTRCheckOther2Text:SetFont(QTR_Font2, 13);
  if (ImmersionFrame ~= nil ) then
     QTRCheckOther2Text:SetText(QTR_Reklama.OTHER2..QTR_Reklama.ACTIV1);
  else
     QTRCheckOther2Text:SetText(QTR_Reklama.OTHER2..QTR_Reklama.ACTIV2);
  end
  
  local QTRCheckOther3 = CreateFrame("CheckButton", "QTRCheckOther3", QTROptions, "OptionsCheckButtonTemplate");
  QTRCheckOther3:SetPoint("TOPLEFT", QTRCheckOther2, "BOTTOMLEFT", 0, 0);
  QTRCheckOther3:SetScript("OnClick", function(self) if (QTR_PS["other3"]=="0") then QTR_PS["other3"]="1" else QTR_PS["other3"]="0" end; end);
  QTRCheckOther3Text:SetFont(QTR_Font2, 13);
  QTRCheckOther3Text:SetText(QTR_Reklama.OTHER3);
  
  local QTRWWW1 = QTROptions:CreateFontString(nil, "ARTWORK");
  QTRWWW1:SetFontObject(GameFontWhite);
  QTRWWW1:SetJustifyH("LEFT");
  QTRWWW1:SetJustifyV("TOP");
  QTRWWW1:ClearAllPoints();
  QTRWWW1:SetPoint("BOTTOMLEFT", 16, 16);
  QTRWWW1:SetFont(QTR_Font2, 13);
  QTRWWW1:SetText(QTR_Reklama.WWW1);
  
  local QTRWWW2 = CreateFrame("EditBox", "QTRWWW2", QTROptions, "InputBoxTemplate");
  QTRWWW2:ClearAllPoints();
  QTRWWW2:SetPoint("TOPLEFT", QTRWWW1, "TOPRIGHT", 10, 4);
  QTRWWW2:SetHeight(20);
  QTRWWW2:SetWidth(155);
  QTRWWW2:SetAutoFocus(false);
  QTRWWW2:SetFontObject(GameFontGreen);
  QTRWWW2:SetText(QTR_Reklama.WWW2);
  QTRWWW2:SetCursorPosition(0);
  QTRWWW2:SetScript("OnEnter", function(self)
	  GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
      getglobal("GameTooltipTextLeft1"):SetFont(QTR_Font2, 13);
  	  GameTooltip:SetText(QTR_Reklama.WWW3, nil, nil, nil, nil, true)
	  GameTooltip:Show() --Show the tooltip
     end);
  QTRWWW2:SetScript("OnLeave", function(self)
      getglobal("GameTooltipTextLeft1"):SetFont(Original_Font2, 13);
	  GameTooltip:Hide() --Hide the tooltip
     end);
  QTRWWW2:SetScript("OnTextChanged", function(self) QTRWWW2:SetText(QTR_Reklama.WWW2); end);

--  if (ImmersionFrame ~= nil ) then
--     local QTRslider = CreateFrame("Slider", "QTRslider", QTROptions, "OptionsSliderTemplate");
--     QTRslider:SetPoint("TOPLEFT", QTRIntegration0, "BOTTOMLEFT", 0, -40);
--     QTRslider:SetMinMaxValues(0.5, 3.0);
--     QTRslider.minValue, QTRslider.maxValue = QTRslider:GetMinMaxValues();
--     QTRslider.Low:SetText(QTRslider.minValue.." sek");
--     QTRslider.High:SetText(QTRslider.maxValue.." sek");
--     getglobal(QTRslider:GetName() .. 'Text'):SetText('Opóźnienie Immersion');
--     getglobal(QTRslider:GetName() .. 'Text'):SetFont(QTR_Font2, 13);
--     QTRslider:SetValue(QTR_PS["delayImmersion"]);
--     QTRslider:SetValueStep(0.1);
--     QTRslider:SetScript("OnValueChanged", function(self,event,arg1) 
--                                           QTR_PS["delayImmersion"]=string.format("%.1f",event); 
--                                           QTRsliderVal:SetText(QTR_PS["delayImmersion"]);
--                                           end);
--     QTRsliderVal = QTROptions:CreateFontString(nil, "ARTWORK");
--     QTRsliderVal:SetFontObject(GameFontNormal);
--     QTRsliderVal:SetJustifyH("CENTER");
--     QTRsliderVal:SetJustifyV("TOP");
--     QTRsliderVal:ClearAllPoints();
--     QTRsliderVal:SetPoint("CENTER", QTRslider, "CENTER", 0, -12);
--     QTRsliderVal:SetFont(QTR_Font2, 13);
--     QTRsliderVal:SetText(QTR_PS["delayImmersion"]);   
--     end
  
end


function QTR_SaveQuest(event)
   if (event=="QUEST_DETAIL") then
      QTR_SAVED[QTR_quest_EN.id.." TITLE"]=GetTitleText();            -- save original title to future translation
      QTR_SAVED[QTR_quest_EN.id.." DESCRIPTION"]=GetQuestText();      -- save original text to future translation
      QTR_SAVED[QTR_quest_EN.id.." OBJECTIVE"]=GetObjectiveText();    -- save original text to future translation
   end
   if (event=="QUEST_PROGRESS") then
      QTR_SAVED[QTR_quest_EN.id.." PROGRESS"]=GetProgressText();      -- save original text to future translation
   end
   if (event=="QUEST_COMPLETE") then
      QTR_SAVED[QTR_quest_EN.id.." COMPLETE"]=GetRewardText();        -- save original text to future translation
   end
   if (QTR_SAVED[QTR_quest_EN.id.." TITLE"]==nil) then
      QTR_SAVED[QTR_quest_EN.id.." TITLE"]=GetTitleText();            -- zapisz tytył w przypadku tylko Zakończenia
   end
   QTR_SAVED[QTR_quest_EN.id.." PLAYER"]=QTR_name..'@'..QTR_race..'@'..QTR_class;  -- zapisz dane gracza
end


function QTR_wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if (QTR_waitFrame == nil) then
    QTR_waitFrame = CreateFrame("Frame","QTR_WaitFrame", UIParent);
    QTR_waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #QTR_waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(QTR_waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(QTR_waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(QTR_waitTable,{delay,func,{...}});
  return true;
end


function QTR_SendReklama()
  local now = GetTime();
  if (last_time + QTR_PS["period"]*60 < now) then                  -- OK, czas wypisać reklamę
     if ((QTR_PS["text1"]=="1") and (QTR_PS["text2"]=="1")) then   -- oba teksty naprzemiennie
        if (last_text==2) then
           if (tonumber(QTR_PS["channel"])>0) then
              SendChatMessage(QTR_Reklama.TEXT1,"CHANNEL",nil,tonumber(QTR_PS["channel"]));
           else
              SendChatMessage(QTR_Reklama.TEXT1,"SAY");
           end
           last_text = 1;
        else
           if (tonumber(QTR_PS["channel"])>0) then
              SendChatMessage(QTR_Reklama.TEXT2,"CHANNEL",nil,tonumber(QTR_PS["channel"]));
           else
              SendChatMessage(QTR_Reklama.TEXT2,"SAY");
           end
           last_text = 2;
        end
     elseif (QTR_PS["text1"]=="1") then
        if (tonumber(QTR_PS["channel"])>0) then
           SendChatMessage(QTR_Reklama.TEXT1,"CHANNEL",nil,tonumber(QTR_PS["channel"]));
        else
           SendChatMessage(QTR_Reklama.TEXT1,"SAY");
        end        
        last_text = 1;
     elseif (QTR_PS["text2"]=="1") then
        if (tonumber(QTR_PS["channel"])>0) then
           SendChatMessage(QTR_Reklama.TEXT2,"CHANNEL",nil,tonumber(QTR_PS["channel"]));
        else
           SendChatMessage(QTR_Reklama.TEXT2,"SAY");
        end
        last_text = 2;
     end
     last_time = now;
  end   
end


function QTR_ON_OFF()
   if (curr_trans=="1") then
      curr_trans="0";
      QTR_Translate_Off(1);
   else   
      curr_trans="1";
      QTR_Translate_On(1);
   end
end


function GS_ON_OFF()
   if (curr_goss=="1") then         -- wyłącz tłumaczenie - pokaż oryginalny tekst
      curr_goss="0";
      GossipGreetingText:SetText(QTR_GS[curr_hash]);
      GossipGreetingText:SetFont(Original_Font2, 13);      
      QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(curr_hash).."] EN");
   else                             -- pokaż tłumaczenie PL
      curr_goss="1";
      local Greeting_PL = GS_Gossip[curr_hash];
      GossipGreetingText:SetText(QTR_ExpandUnitInfo(Greeting_PL));
      GossipGreetingText:SetFont(QTR_Font2, 13);      
      QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(curr_hash).."] PL");
   end
end


-- Pierwsza funkcja wywoływana po załadowaniu dodatku
function QTR_OnLoad()
   QTR = CreateFrame("Frame");
   QTR:SetScript("OnEvent", QTR_OnEvent);
   QTR:RegisterEvent("ADDON_LOADED");
   QTR:RegisterEvent("QUEST_ACCEPTED");
   QTR:RegisterEvent("QUEST_DETAIL");
   QTR:RegisterEvent("QUEST_PROGRESS");
   QTR:RegisterEvent("QUEST_COMPLETE");
--   QTR:RegisterEvent("QUEST_FINISHED");
--   QTR:RegisterEvent("QUEST_GREETING");
   QTR:RegisterEvent("GOSSIP_SHOW");

   -- przycisk z nr ID questu w QuestFrame (NPC)
   QTR_ToggleButton0 = CreateFrame("Button",nil, QuestFrame, "UIPanelButtonTemplate");
   QTR_ToggleButton0:SetWidth(150);
   QTR_ToggleButton0:SetHeight(20);
   QTR_ToggleButton0:SetText("Quest ID=?");
   QTR_ToggleButton0:Show();
   QTR_ToggleButton0:ClearAllPoints();
   QTR_ToggleButton0:SetPoint("TOPLEFT", QuestFrame, "TOPLEFT", 120, -50);
   QTR_ToggleButton0:SetScript("OnClick", QTR_ON_OFF);
   
   -- przycisk z nr ID questu w QuestFrameProgressPanel
   QTR_ToggleButton1 = CreateFrame("Button",nil, QuestLogFrame, "UIPanelButtonTemplate");
   QTR_ToggleButton1:SetWidth(150);
   QTR_ToggleButton1:SetHeight(20);
   QTR_ToggleButton1:SetText("Quest ID=?");
   QTR_ToggleButton1:Show();
   QTR_ToggleButton1:ClearAllPoints();
   QTR_ToggleButton1:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 178, -58);
   QTR_ToggleButton1:SetScript("OnClick", QTR_ON_OFF);

   -- przycisk z nr ID questu w QuestMapDetailsScrollFrame
   QTR_ToggleButton2 = CreateFrame("Button",nil, QuestMapDetailsScrollFrame, "UIPanelButtonTemplate");
   QTR_ToggleButton2:SetWidth(150);
   QTR_ToggleButton2:SetHeight(20);
   QTR_ToggleButton2:SetText("Quest ID=?");
   QTR_ToggleButton2:Show();
   QTR_ToggleButton2:ClearAllPoints();
   QTR_ToggleButton2:SetPoint("TOPLEFT", QuestMapDetailsScrollFrame, "TOPLEFT", 116, 29);
   QTR_ToggleButton2:SetScript("OnClick", QTR_ON_OFF);

   -- przycisk z nr HASH gossip w QuestMapDetailsScrollFrame
   QTR_ToggleButtonGS = CreateFrame("Button",nil, GossipFrameGreetingPanel, "UIPanelButtonTemplate");
   QTR_ToggleButtonGS:SetWidth(220);
   QTR_ToggleButtonGS:SetHeight(20);
   QTR_ToggleButtonGS:SetText("Gossip-Hash=?");
   QTR_ToggleButtonGS:Show();
   QTR_ToggleButtonGS:ClearAllPoints();
   QTR_ToggleButtonGS:SetPoint("TOPLEFT", GossipFrameGreetingPanel, "TOPLEFT", 90, -50);
   QTR_ToggleButtonGS:SetScript("OnClick", GS_ON_OFF);

   -- funkcja wywoływana po kliknięciu na nazwę questu w QuestTracker   
--   hooksecurefunc(QUEST_TRACKER_MODULE, "OnBlockHeaderClick", QTR_PrepareReload);
   
   -- funkcja wywoływana po kliknięciu na nazwę questu w QuestLog
  QuestLogDetailScrollFrame:HookScript("OnShow", QTR_Prepare1sek);
  EmptyQuestLogFrame:HookScript("OnShow", QTR_EmptyQuestLog);
  hooksecurefunc("SelectQuestLogEntry", QTR_Prepare1sek);

--  QuestLogTitleButton:HookScript("OnClick", QTR_PrepareReload);
--  if hooksecurefunc then
--     hooksecurefunc("QuestLogTitleButton_OnClick", function() QTR_PrepareReload() end);
--  end

--   hooksecurefunc("QuestMapFrame_ShowQuestDetails", QTR_PrepareReload);
   
   isQuestGuru();
   isImmersion();
   isStoryline();
end


function isQuestGuru()
   if (QuestGuru ~= nil ) then
      if (QTR_ToggleButton3==nil) then
         -- przycisk z nr ID questu w QuestGuru
         QTR_ToggleButton3 = CreateFrame("Button",nil, QuestGuru, "UIPanelButtonTemplate");
         QTR_ToggleButton3:SetWidth(150);
         QTR_ToggleButton3:SetHeight(20);
         QTR_ToggleButton3:SetText("Quest ID=?");
         QTR_ToggleButton3:Show();
         QTR_ToggleButton3:ClearAllPoints();
         QTR_ToggleButton3:SetPoint("TOPLEFT", QuestGuru, "TOPLEFT", 330, -33);
         QTR_ToggleButton3:SetScript("OnClick", QTR_ON_OFF);
         -- uaktualniono dane w QuestLogu
         QuestGuru:HookScript("OnUpdate", function() QTR_PrepareReload() end);
      end
      return true;
   else
      return false;   
   end
end


function isImmersion()
   if (ImmersionFrame ~= nil ) then
      if (QTR_ToggleButton4==nil) then
         -- przycisk z nr ID questu
         QTR_ToggleButton4 = CreateFrame("Button",nil, ImmersionFrame.TalkBox, "UIPanelButtonTemplate");
         QTR_ToggleButton4:SetWidth(150);
         QTR_ToggleButton4:SetHeight(20);
         QTR_ToggleButton4:SetText("Quest ID=?");
         QTR_ToggleButton4:Show();
         QTR_ToggleButton4:ClearAllPoints();
         QTR_ToggleButton4:SetPoint("TOPLEFT", ImmersionFrame.TalkBox, "TOPRIGHT", -200, -116);
         QTR_ToggleButton4:SetScript("OnClick", QTR_ON_OFF);
         -- otworzono okno dodatku Immersion : wywołanie przez OnEvent
         ImmersionFrame.TalkBox:HookScript("OnHide",function() QTR_ToggleButton4:Hide(); end);
         QTR_ToggleButton4:Disable();     -- nie można na razie przyciskać
         QTR_ToggleButton4:Hide();        -- wstępnie przycisk niewidoczny (bo może jest wybór questów)
      end
      return true;
   else   
      return false;
   end
end
   

function isStoryline()
   if (Storyline_NPCFrame ~= nil ) then
      if (QTR_ToggleButton5==nil) then
         -- przycisk z nr ID questu
         QTR_ToggleButton5 = CreateFrame("Button",nil, Storyline_NPCFrameChat, "UIPanelButtonTemplate");
         QTR_ToggleButton5:SetWidth(150);
         QTR_ToggleButton5:SetHeight(20);
         QTR_ToggleButton5:SetText("Quest ID=?");
         QTR_ToggleButton5:Hide();
         QTR_ToggleButton5:ClearAllPoints();
         QTR_ToggleButton5:SetPoint("BOTTOMLEFT", Storyline_NPCFrameChat, "BOTTOMLEFT", 244, -16);
         QTR_ToggleButton5:SetScript("OnClick", QTR_ON_OFF);
         Storyline_NPCFrameObjectivesContent:HookScript("OnShow", function() QTR_Storyline_Objectives() end);
         Storyline_NPCFrameRewards:HookScript("OnShow", function() QTR_Storyline_Rewards() end);
         Storyline_NPCFrameChat:HookScript("OnHide", function() QTR_Storyline_Hide() end);
--         QTR_ToggleButton5:Disable();     -- nie można przyciskać
      end
      return true;
   else
      return false;
   end
end


-- Określa aktualny numer ID questu z różnych metod
function QTR_GetQuestID()
   if ( isGetQuestID=="1" ) then
      quest_ID = GetQuestID();
   end
   
   if ((QuestLogFrame:IsVisible()) and ((quest_ID==nil) or (quest_ID==0))) then
      local questTitle, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(GetQuestLogSelection());
      quest_ID = questID;
   end
   
--   quest_ID = QuestFrame.questID;
--   if (quest_ID==nil) then
--      quest_ID = QuestLogPopupDetailFrame.questID;
--   end
     
   if(quest_ID==nil) then
      if (isImmersion() and ImmersionFrame:IsVisible()) then
         local nameOrig=ImmersionFrame.TalkBox.NameFrame.Name:GetText();
         local i = 1;
         while GetQuestLogTitle(i) do    -- przeglądaj wszystkie questy w QuestLogu
            local questTitle, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i);
            if (questTitle==nameOrig) then
               quest_ID = questID;
               break;
            end
            i = i + 1;
         end         
      end
      if (isStoryline() and Storyline_NPCFrameTitle:IsVisible()) then
         local nameOrig=Storyline_NPCFrameTitle:GetText();
         local i = 1;
         while GetQuestLogTitle(i) do    -- przeglądaj wszystkie questy w QuestLogu
            local questTitle, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i);
            if (questTitle==nameOrig) then
               quest_ID = questID;
               break;
            end
            i = i + 1;
         end        
      end
   end   
   
   if (quest_ID==nil) then
      if (QTR_onDebug) then
         print('Nie znalazł ID');
      end   
      quest_ID=0;
   else   
      if (QTR_onDebug) then
         print('Znalazł ID='..tostring(quest_ID));
      end   
   end   
   
   
   return (quest_ID);
end



-- Wywoływane przy przechwytywanych zdarzeniach
function QTR_OnEvent(self, event, name, ...)
   isStoryline();       -- utwórz przycisk, gdy Storyline aktywny
   if (QTR_onDebug) then
      print('OnEvent-event: '..event);   
   end   
   if (event=="ADDON_LOADED" and name=="WoWchinese_Quests") then
      SlashCmdList["WOWCHINESE_QUESTS"] = function(msg) QTR_SlashCommand(msg); end
      SLASH_WOWCHINESE_QUESTS1 = "/wowchinese-quests";
      SLASH_WOWCHINESE_QUESTS2 = "/qtr";
      QTR_CheckVars();
      -- twórz interface Options w Blizzard-Interface-Addons
      QTR_BlizzardOptions();
      print ("|cffffff00WoWchinese-Quests ver. "..QTR_version.." - "..QTR_Messages.loaded);
      QTR:UnregisterEvent("ADDON_LOADED");
      QTR.ADDON_LOADED = nil;
      if (not isGetQuestID) then
         DetectEmuServer();
      end
   elseif (event=="QUEST_DETAIL" or event=="QUEST_PROGRESS" or event=="QUEST_COMPLETE") then
      if ( QuestFrame:IsVisible() or isImmersion()) then
         QTR_QuestPrepare(event);
      elseif (isStoryline()) then
         if (not QTR_wait(1,QTR_Storyline_Quest)) then
         -- opóźnienie 1 sek
         end
      end	-- QuestFrame is Visible
   elseif (event=="GOSSIP_SHOW") then
      QTR_Gossip_Show();
   elseif (isImmersion() and event=="QUEST_ACCEPTED") then
      QTR_delayed3();
   end
   if (QTR_PS["reklama"]=="1") then
      QTR_SendReklama();
   end
end


-- Otworzono okienko rozmowy z NPC
function QTR_Gossip_Show()
   local Nazwa_NPC = GossipFrameNpcNameText:GetText();
   curr_hash = 0;
   if (Nazwa_NPC) then
      local Greeting_Text = GossipGreetingText:GetText();
      if (string.find(Greeting_Text,"@")==nil) then         -- nie jest to tekst po polsku
         Nazwa_NPC = string.gsub(Nazwa_NPC, '"', '\"');
         Greeting_Text = string.gsub(Greeting_Text, '"', '\"');
         local Czysty_Text = string.gsub(Greeting_Text, '\r', '');
         Czysty_Text = string.gsub(Czysty_Text, '\n', '$B');
         Czysty_Text = string.gsub(Czysty_Text, QTR_name, '$N');
         Czysty_Text = string.gsub(Czysty_Text, string.upper(QTR_name), '$N$');
         Czysty_Text = string.gsub(Czysty_Text, QTR_race, '$R');
         Czysty_Text = string.gsub(Czysty_Text, string.lower(QTR_race), '$R');
         Czysty_Text = string.gsub(Czysty_Text, QTR_class, '$C');
         Czysty_Text = string.gsub(Czysty_Text, string.lower(QTR_class), '$C');
         Czysty_Text = string.gsub(Czysty_Text, '$N$', '');
         Czysty_Text = string.gsub(Czysty_Text, '$N', '');
         Czysty_Text = string.gsub(Czysty_Text, '$B', '');
         Czysty_Text = string.gsub(Czysty_Text, '$R', '');
         Czysty_Text = string.gsub(Czysty_Text, '$C', '');
         local Hash = StringHash(Czysty_Text);
         curr_hash = Hash;
         QTR_GS[Hash] = Greeting_Text;                      -- zapis oryginalnego tekstu
         if ( GS_Gossip[Hash] ) then   -- istnieje tłumaczenie tekstu GOSSIP tego NPC
            curr_goss = "1";
            local Greeting_PL = GS_Gossip[Hash];
            GossipGreetingText:SetText(QTR_ExpandUnitInfo(Greeting_PL));
            GossipGreetingText:SetFont(QTR_Font2, 13);
            QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] PL");
            QTR_ToggleButtonGS:Enable();
         else                               -- nie ma tłumaczenia w bazie GOSSIP
            curr_goss = "0";
            -- zapis do pliku
            QTR_GOSSIP[Nazwa_NPC..'@'..tostring(Hash)] = Greeting_Text;
            QTR_ToggleButtonGS:SetText("Gossip-Hash=["..tostring(Hash).."] EN");
            QTR_ToggleButtonGS:Disable();
         end
         if (GetNumGossipOptions()>0) then    -- są jeszcze przyciski funkcji dodatkowych
            local pozycja=GetNumGossipActiveQuests()+GetNumGossipAvailableQuests()+1;
            local titleButton="";
            for i = 1, GetNumGossipOptions(), 1 do 
               titleButton=getglobal("GossipTitleButton"..tostring(pozycja+i)):GetText();
               Hash = StringHash(titleButton);
               if ( GS_Gossip[Hash] ) then   -- istnieje tłumaczenie tekstu dodatkowego
                  getglobal("GossipTitleButton"..tostring(pozycja+i)):SetText(GS_Gossip[Hash]);
                  getglobal("GossipTitleButton"..tostring(pozycja+i)):SetFont(QTR_Font2, 13);
               else
                  QTR_GOSSIP[Nazwa_NPC..'@'..tostring(Hash)] = titleButton;
               end
            end
         end
      end
   end
end


-- Otworzono pusty QuestLog
function QTR_EmptyQuestLog()
   QTR_ToggleButton1:Hide();
end


-- Otworzono okienko QuestLogFrame lub QuestMapDetailsScrollFrame lub QuestGuru lub Immersion
function QTR_QuestPrepare(zdarzenie)
   QTR_ToggleButton1:Show();        -- Show, bo mógł być ukryty przy pustym QuestLogu
   if (isQuestGuru()) then
      if (QTR_PS["other1"]=="0") then       -- jest aktywny QuestGuru, ale nie zezwolono na tłumaczenie
         QTR_ToggleButton3:Hide();
         return;
      else   
         QTR_ToggleButton3:Show();
         if (QuestGuru:IsVisible() and (curr_trans=="0")) then
            QTR_Translate_Off(1);
            local questTitle, level, questTag, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(GetQuestLogSelection());
            if (QTR_quest_EN.id==questID) then
               return;
            end
         end
      end   
   end
   if (isImmersion()) then
      if (QTR_PS["other2"]=="0") then       -- jest aktywny Immersion, ale nie zezwolono na tłumaczenie
         QTR_ToggleButton4:Hide();
         return
      else
         QTR_ToggleButton4:Show();
         if (ImmersionContentFrame:IsVisible() and (curr_trans=="0")) then
            QTR_Translate_Off(1);
            return;
         end
      end      
   end
   q_ID = QTR_GetQuestID();
   str_ID = tostring(q_ID);
   QTR_quest_EN.id = q_ID;
   QTR_quest_LG.id = q_ID;
   if (isStoryline()) then
      QTR_ToggleButton5:Hide();
      if (QTR_PS["other3"]=="1") then
         if (q_ID>0) then
            QTR_ToggleButton5:Show();
         end
      else        -- nie zezwolono na tłumaczenie
         return
     end      
   end
   if (QTR_PS["control"]=="1") then         -- zapisuj kontrolnie treść oryginalnych questów EN
      QTR_quest_EN.title = GetTitleText();
      if (QTR_quest_EN.title=="") then
         QTR_quest_EN.title=GetQuestLogTitle(GetQuestLogSelection());
      end
      QTR_CONTROL[QTR_quest_EN.id.." TITLE"]=QTR_quest_EN.title;
      if (zdarzenie=="QUEST_DETAIL") then
         QTR_quest_EN.details = GetQuestText();
         QTR_quest_EN.objectives = GetObjectiveText();
         QTR_CONTROL[QTR_quest_EN.id.." DESCRIPTION"]=QTR_quest_EN.details;
         QTR_CONTROL[QTR_quest_EN.id.." OBJECTIVE"]=QTR_quest_EN.objectives;
      end
      if (zdarzenie=="QUEST_PROGRESS") then
         QTR_quest_EN.progress = GetProgressText();
         QTR_CONTROL[QTR_quest_EN.id.." PROGRESS"]=QTR_quest_EN.progress;
      end
      if (zdarzenie=="QUEST_COMPLETE") then
         QTR_quest_EN.completion = GetRewardText();
         QTR_CONTROL[QTR_quest_EN.id.." COMPLETE"]=QTR_quest_EN.completion;
      end
      QTR_CONTROL[QTR_quest_EN.id.." PLAYER"]=QTR_name..'@'..QTR_race..'@'..QTR_class;  -- zapisz dane gracza
   end
   if ( QTR_PS["active"]=="1" ) then	-- tłumaczenia włączone
      QTR_ToggleButton0:Enable();
      QTR_ToggleButton1:Enable();
      QTR_ToggleButton2:Enable();
      if (isImmersion()) then
         if (q_ID==0) then
            return;
         end   
         QTR_ToggleButton4:Enable();
      end
      curr_trans = "1";
      if ( QTR_QuestData[str_ID] ) then   -- wyświetlaj tylko, gdy istnieje tłumaczenie
         if (QTR_onDebug) then
            print('Znalazł tłumaczenie dla ID: '..str_ID);   
         end   
         QTR_quest_LG.title = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Title"]);
         QTR_quest_EN.title = GetTitleText();
         if (QTR_quest_EN.title=="") then
            QTR_quest_EN.title=GetQuestLogTitle(GetQuestLogSelection());
         end
         QTR_quest_LG.details = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Description"]);
         QTR_quest_LG.objectives = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Objectives"]);
--         QTR_quest_EN.details = QuestLogQuestDescription:GetText();
--         QTR_quest_EN.objectives = QuestLogObjectivesText:GetText();
         if (zdarzenie=="QUEST_DETAIL") then
            QTR_quest_EN.details = GetQuestText();
            QTR_quest_EN.objectives = GetObjectiveText();
            QTR_quest_EN.itemchoose = QTR_MessOrig.itemchoose1;
            QTR_quest_LG.itemchoose = QTR_Messages.itemchoose1;
            QTR_quest_EN.itemreceive = QTR_MessOrig.itemreceiv1;
            QTR_quest_LG.itemreceive = QTR_Messages.itemreceiv1;
            if (strlen(QTR_quest_EN.details)>0 and strlen(QTR_quest_LG.details)==0) then
               QTR_MISSING[QTR_quest_EN.id.." DESCRIPTION"]=QTR_quest_EN.details;     -- save missing translation part
            end
            if (strlen(QTR_quest_EN.objectives)>0 and strlen(QTR_quest_LG.objectives)==0) then
               QTR_MISSING[QTR_quest_EN.id.." OBJECTIVE"]=QTR_quest_EN.objectives;    -- save missing translation part
            end
         else   
            if (QTR_quest_LG.details ~= QuestLogQuestDescription:GetText()) then
               QTR_quest_EN.details = QuestLogQuestDescription:GetText();
            end
            if (QTR_quest_LG.objectives ~= QuestLogObjectivesText:GetText()) then
               QTR_quest_EN.objectives = QuestLogObjectivesText:GetText();
            end
         end   
         if (zdarzenie=="QUEST_PROGRESS") then
            QTR_quest_EN.progress = GetProgressText();
            QTR_quest_LG.progress = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Progress"]);
            if (strlen(QTR_quest_EN.progress)>0 and strlen(QTR_quest_LG.progress)==0) then
               QTR_MISSING[QTR_quest_EN.id.." PROGRESS"]=QTR_quest_EN.progress;     -- save missing translation part
            end
            if (strlen(QTR_quest_LG.progress)==0) then      -- treść jest pusta, a otworzono okienko Progress
               QTR_quest_LG.progress = QTR_ExpandUnitInfo('Dobrze ci idzie, YOUR_NAME');
            end
         end
         if (zdarzenie=="QUEST_COMPLETE") then
            QTR_quest_EN.completion = GetRewardText();
            QTR_quest_LG.completion = QTR_ExpandUnitInfo(QTR_QuestData[str_ID]["Completion"]);
            QTR_quest_EN.itemchoose = QTR_MessOrig.itemchoose2;
            QTR_quest_LG.itemchoose = QTR_Messages.itemchoose2;
            QTR_quest_EN.itemreceive = QTR_MessOrig.itemreceiv2;
            QTR_quest_LG.itemreceive = QTR_Messages.itemreceiv2;
            if (strlen(QTR_quest_EN.completion)>0 and strlen(QTR_quest_LG.completion)==0) then
               QTR_MISSING[QTR_quest_EN.id.." COMPLETE"]=QTR_quest_EN.completion;     -- save missing translation part
            end
         end         
         QTR_ToggleButton0:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         QTR_ToggleButton1:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         QTR_ToggleButton2:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
            QTR_ToggleButton3:Enable();
         end
         if (isImmersion()) then
            QTR_ToggleButton4:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
            QTR_quest_EN.details = GetQuestText();
            QTR_quest_EN.progress = GetProgressText();
            QTR_quest_EN.completion = GetRewardText();
         end
         if (isStoryline() and Storyline_NPCFrame:IsVisible()) then
            QTR_ToggleButton5:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         end
         QTR_Translate_On(1);
      else	      -- nie ma przetłumaczonego takiego questu
         if (QTR_onDebug) then
            print('Nie znalazł tłumaczenia dla ID: '..str_ID);   
         end   
         QTR_ToggleButton0:Disable();
         QTR_ToggleButton1:Disable();
         QTR_ToggleButton2:Disable();
         if (isQuestGuru()) then
            QTR_ToggleButton3:Disable();
         end
         if (isImmersion()) then
            QTR_ToggleButton4:Disable();
         end
         if (isStoryline()) then
            QTR_ToggleButton5:Disable();
         end
         QTR_ToggleButton0:SetText("Quest ID="..str_ID);
         QTR_ToggleButton1:SetText("Quest ID="..str_ID);
         QTR_ToggleButton2:SetText("Quest ID="..str_ID);
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..str_ID);
         end
         if (isImmersion()) then
            if (q_ID==0) then
               if (ImmersionFrame.TitleButtons:IsVisible()) then
                  QTR_ToggleButton4:SetText("wybierz wpierw quest");
               end
            else
               QTR_ToggleButton4:SetText("Quest ID="..str_ID);
            end
         end
         if (isStoryline()) then
            QTR_ToggleButton5:SetText("Quest ID="..str_ID);
         end
         QTR_Translate_On(0);
         QTR_SaveQuest(zdarzenie);
      end -- jest przetłumaczony quest w bazie
   else	-- tłumaczenia wyłączone
      QTR_ToggleButton0:Disable();
      QTR_ToggleButton1:Disable();
      QTR_ToggleButton2:Disable();
--         if (isQuestGuru()) then
--            QTR_ToggleButton3:Disable();
--         end
--         if (isImmersion()) then
--            QTR_ToggleButton4:Disable();
--         end
      if ( QTR_QuestData[str_ID] ) then	-- ale jest tłumaczenie w bazie
         QTR_ToggleButton1:SetText("Quest ID="..str_ID.." (EN)");
         QTR_ToggleButton2:SetText("Quest ID="..str_ID.." (EN)");
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..str_ID.." (EN)");
         end
         if (isImmersion()) then
            QTR_ToggleButton4:SetText("Quest ID="..str_ID.." (EN)");
         end
         if (isStoryline()) then
            QTR_ToggleButton5:SetText("Quest ID="..str_ID.." (EN)");
         end
      else
         QTR_ToggleButton1:SetText("Quest ID="..str_ID);
         QTR_ToggleButton2:SetText("Quest ID="..str_ID);
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..str_ID);
         end
         if (isImmersion()) then
            QTR_ToggleButton4:SetText("Quest ID="..str_ID);
         end
         if (isStoryline()) then
            QTR_ToggleButton5:SetText("Quest ID="..str_ID);
         end
      end
   end	-- tłumaczenia są włączone
   if (QTR_PS["reklama"]=="1") then
      QTR_SendReklama();
   end
end


-- wyświetla tłumaczenie
function QTR_Translate_On(typ)
   if (QTR_onDebug) then
      print('Wyświetla tłumaczenie');   
   end   
   QuestInfoObjectivesHeader:SetFont(QTR_Font1, 18);
   QuestInfoObjectivesHeader:SetText(QTR_Messages.objectives); -- "Zadanie"

   QuestLogRewardTitleText:SetFont(QTR_Font1, 18);
   QuestLogRewardTitleText:SetText(QTR_Messages.rewards);      -- "Nagroda"
   QuestInfoRewardsFrame.Header:SetFont(QTR_Font1, 18);
   QuestInfoRewardsFrame.Header:SetText(QTR_Messages.rewards);  -- "Nagroda"
   
   QuestLogDescriptionTitle:SetFont(QTR_Font1, 18);
   QuestLogDescriptionTitle:SetText(QTR_Messages.details);     -- "Szczegóły"
   
   QuestProgressRequiredItemsText:SetFont(QTR_Font1, 18);
   QuestProgressRequiredItemsText:SetText(QTR_Messages.reqitems);
   
--   QuestInfoSpellObjectiveLearnLabel:SetFont(QTR_Font2, 13);
--   QuestInfoSpellObjectiveLearnLabel:SetText(QTR_Messages.learnspell);
--   QuestInfoXPFrame.ReceiveText:SetFont(QTR_Font2, 13);
--   QuestInfoXPFrame.ReceiveText:SetText(QTR_Messages.experience);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetFont(QTR_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetFont(QTR_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetText(QTR_Messages.itemchoose1);
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_Messages.itemreceiv1);
   if (typ==1) then			-- pełne przełączenie (jest tłumaczenie)
      QuestLogItemChooseText:SetFont(QTR_Font2, 13);
      QuestLogItemChooseText:SetText(QTR_Messages.itemchoose1);
      QuestLogItemReceiveText:SetFont(QTR_Font2, 13);
      QuestLogItemReceiveText:SetText(QTR_Messages.itemreceiv1);
      numer_ID = QTR_quest_LG.id;
      str_ID = tostring(numer_ID);
      if (numer_ID>0 and QTR_QuestData[str_ID]) then	-- przywróć przetłumaczoną wersję napisów
         if (QTR_onDebug) then
            print('tłum.ID='..str_ID);   
         end   
         if (QTR_PS["transtitle"]=="1") then    -- wyświetl przetłumaczony tytuł
            QuestLogQuestTitle:SetFont(QTR_Font1, 18);
            QuestLogQuestTitle:SetText(QTR_quest_LG.title);
            QuestInfoTitleHeader:SetFont(QTR_Font1, 18);
            QuestInfoTitleHeader:SetText(QTR_quest_LG.title);
            QuestProgressTitleText:SetFont(QTR_Font1, 18);
            QuestProgressTitleText:SetText(QTR_quest_LG.title);
         end
         QTR_ToggleButton0:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         QTR_ToggleButton1:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         QTR_ToggleButton2:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         if (isQuestGuru()) then
            QTR_ToggleButton3:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
         end
         if (isImmersion()) then
            QTR_ToggleButton4:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
            if (not QTR_wait(0.2,QTR_Immersion)) then    -- wywołaj podmienianie danych po 0.2 sek
               -- opóźnienie 0.2 sek
            end
         end
         if (isStoryline() and Storyline_NPCFrame:IsVisible()) then
            QTR_ToggleButton5:SetText("Quest ID="..QTR_quest_LG.id.." ("..QTR_lang..")");
            QTR_Storyline(1);
         end
         QuestLogQuestDescription:SetFont(QTR_Font2, 13);
         QuestLogQuestDescription:SetText(QTR_quest_LG.details);
         QuestInfoDescriptionText:SetFont(QTR_Font2, 13);
         QuestInfoDescriptionText:SetText(QTR_quest_LG.details);
         QuestInfoObjectivesText:SetFont(QTR_Font2, 13);
         QuestInfoObjectivesText:SetText(QTR_quest_LG.objectives);
         
         QuestLogObjectivesText:SetFont(QTR_Font2, 13);
         QuestLogObjectivesText:SetText(QTR_quest_LG.objectives);
         
         QuestProgressText:SetFont(QTR_Font2, 13);
         QuestProgressText:SetText(QTR_quest_LG.progress);
         QuestInfoRewardText:SetFont(QTR_Font2, 13);
         QuestInfoRewardText:SetText(QTR_quest_LG.completion);
         
         QuestInfoRewardsFrame.ItemChooseText:SetFont(QTR_Font2, 13);
         QuestInfoRewardsFrame.ItemChooseText:SetText(QTR_quest_LG.itemchoose);
         QuestInfoRewardsFrame.ItemReceiveText:SetFont(QTR_Font2, 13);
         QuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_quest_LG.itemreceive);
      end
   else
      if (curr_trans == "1") then
         QuestInfoRewardsFrame.ItemChooseText:SetText(QTR_Messages.itemchoose1);
         QuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_Messages.itemreceiv1);
         if ((ImmersionFrame ~= nil ) and (ImmersionFrame.TalkBox:IsVisible() )) then
            if (not QTR_wait(0.2,QTR_Immersion_Static)) then
               -- podmiana tekstu z opóźnieniem 0.2 sek
            end
         end
      end
   end
end


-- wyświetla oryginalny tekst
function QTR_Translate_Off(typ)
   QuestInfoTitleHeader:SetFont(Original_Font1, 18);
   QuestInfoTitleHeader:SetText(QTR_quest_EN.title);
--   QuestProgressTitleText:SetText(QTR_quest_EN.title);        
--   QuestProgressTitleText:SetFont(Original_Font1, 18);
   
   QuestLogQuestTitle:SetFont(Original_Font1, 18);
   QuestLogQuestTitle:SetText(QTR_quest_EN.title);
   
   QuestInfoObjectivesHeader:SetFont(Original_Font1, 18);      -- Quest Objectives
   QuestInfoObjectivesHeader:SetText(QTR_MessOrig.objectives);

   QuestLogRewardTitleText:SetFont(Original_Font1, 18);        -- Reward
   QuestLogRewardTitleText:SetText(QTR_MessOrig.rewards);
   QuestInfoRewardsFrame.Header:SetFont(Original_Font1, 18);   -- Reward
   QuestInfoRewardsFrame.Header:SetText(QTR_MessOrig.rewards);
   
   QuestLogDescriptionTitle:SetFont(Original_Font1, 18);       -- Description
   QuestLogDescriptionTitle:SetText(QTR_MessOrig.details);
   
   QuestProgressRequiredItemsText:SetFont(Original_Font1, 18);
   QuestProgressRequiredItemsText:SetText(QTR_MessOrig.reqitems);
   
--   MapQuestInfoRewardsFrame.ItemReceiveText:SetFont(Original_Font2, 11);
--   MapQuestInfoRewardsFrame.ItemChooseText:SetFont(Original_Font2, 11);
   QuestInfoSpellObjectiveLearnLabel:SetFont(Original_Font2, 13);
   QuestInfoSpellObjectiveLearnLabel:SetText(QTR_MessOrig.learnspell);
   QuestInfoXPFrame.ReceiveText:SetFont(Original_Font2, 13);
   QuestInfoXPFrame.ReceiveText:SetText(QTR_MessOrig.experience);
   if (typ==1) then			-- pełne przełączenie (jest tłumaczenie)
      QuestLogItemChooseText:SetFont(Original_Font2, 13);
      QuestLogItemChooseText:SetText(QTR_MessOrig.itemchoose1);
      QuestLogItemReceiveText:SetFont(Original_Font2, 13);
      QuestLogItemReceiveText:SetText(QTR_MessOrig.itemreceiv1);
--      MapQuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_MessOrig.itemreceiv1);
--      MapQuestInfoRewardsFrame.ItemChooseText:SetText(QTR_MessOrig.itemreceiv1);
      numer_ID = QTR_quest_EN.id;
      if (numer_ID>0 and QTR_QuestData[str_ID]) then	-- przywróć oryginalną wersję napisów
         QTR_ToggleButton0:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
         QTR_ToggleButton1:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
         QTR_ToggleButton2:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
         if (QuestGuru ~= nil ) then
            QTR_ToggleButton3:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
         end
         if (ImmersionFrame ~= nil ) then
            QTR_ToggleButton4:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
            QTR_Immersion_OFF();
            ImmersionFrame.TalkBox.TextFrame.Text:RepeatTexts();   --reload text
         end
         if (isStoryline()) then
            QTR_ToggleButton5:SetText("Quest ID="..QTR_quest_EN.id.." (EN)");
            QTR_Storyline_OFF(1);
         end
         QuestLogQuestDescription:SetFont(Original_Font2, 13);
         QuestLogQuestDescription:SetText(QTR_quest_EN.details);
         QuestInfoDescriptionText:SetFont(Original_Font2, 13);
         QuestInfoDescriptionText:SetText(QTR_quest_EN.details);
         QuestInfoObjectivesText:SetFont(Original_Font2, 13);
         QuestInfoObjectivesText:SetText(QTR_quest_EN.objectives);
         
         QuestLogObjectivesText:SetFont(Original_Font2, 13);
         QuestLogObjectivesText:SetText(QTR_quest_EN.objectives);
         
         QuestProgressText:SetFont(Original_Font2, 13);
         QuestProgressText:SetText(QTR_quest_EN.progress);
         QuestInfoRewardText:SetFont(Original_Font2, 13);
         QuestInfoRewardText:SetText(QTR_quest_EN.completion);
         
         QuestInfoRewardsFrame.ItemChooseText:SetFont(Original_Font2, 13);
         QuestInfoRewardsFrame.ItemChooseText:SetText(QTR_quest_EN.itemchoose);
         QuestInfoRewardsFrame.ItemReceiveText:SetFont(Original_Font2, 13);
         QuestInfoRewardsFrame.ItemReceiveText:SetText(QTR_quest_EN.itemreceive);
      end
   else   
      if (curr_trans == "0") then
         if ((ImmersionFrame ~= nil ) and (ImmersionFrame.TalkBox:IsVisible() )) then
            if (not QTR_wait(0.2,QTR_Immersion_OFF_Static)) then
               -- podmiana tekstu z opóźnieniem 0.2 sek
            end
         end
      end
   end
end


function QTR_delayed3()
   QTR_ToggleButton4:SetText("wybierz wpierw quest");
   QTR_ToggleButton4:Hide();
   if (not QTR_wait(1,QTR_delayed4)) then
   ---
   end
end


function QTR_delayed4()
   if (ImmersionFrame.TitleButtons:IsVisible()) then
      if (ImmersionFrame.TitleButtons.Buttons[1] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[1]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end
      if (ImmersionFrame.TitleButtons.Buttons[2] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[2]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end
      if (ImmersionFrame.TitleButtons.Buttons[3] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[3]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end   
      if (ImmersionFrame.TitleButtons.Buttons[4] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[4]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end
      if (ImmersionFrame.TitleButtons.Buttons[5] ~= nil ) then
         ImmersionFrame.TitleButtons.Buttons[5]:HookScript("OnClick", function() QTR_PrepareDelay(1) end);
      end
   end
   QTR_QuestPrepare('');
end;      


function QTR_PrepareDelay(czas)     -- wywoływane po kliknięciu na nazwę questu z listy NPC
   if (czas==1) then
      if (not QTR_wait(1,QTR_PrepareReload)) then
      ---
      end
   end
   if (czas==3) then
      if (not QTR_wait(3,QTR_PrepareReload)) then
      ---
      end
   end
end;      


function QTR_PrepareReload()
   QTR_QuestPrepare('');
end;      


function QTR_Prepare1sek()
   if (not QTR_wait(0.1,QTR_PrepareReload)) then
   ---
   end
end;      


function QTR_Immersion()   -- wywoływanie tłumaczenia z opóźnieniem 0.2 sek
  ImmersionContentFrame.ObjectivesText:SetFont(QTR_Font2, 14);
  ImmersionContentFrame.ObjectivesText:SetText(QTR_quest_LG.objectives);
  ImmersionFrame.TalkBox.NameFrame.Name:SetFont(QTR_Font1, 20);
  ImmersionFrame.TalkBox.NameFrame.Name:SetText(QTR_quest_LG.title);
  ImmersionFrame.TalkBox.TextFrame.Text:SetFont(QTR_Font2, 14);
  if (strlen(QTR_quest_EN.details)>0) then                                    -- mamy zdarzenie DETAILS
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_LG.details);
  elseif (strlen(QTR_quest_EN.completion)>0) then
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_LG.completion);
  else
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_LG.progress);
  end
  QTR_Immersion_Static();        -- inne statyczne dane
end


function QTR_Immersion_Static() 
  ImmersionContentFrame.ObjectivesHeader:SetFont(QTR_Font1, 18);
  ImmersionContentFrame.ObjectivesHeader:SetText(QTR_Messages.objectives);  -- "Zadanie"
  ImmersionContentFrame.RewardsFrame.Header:SetFont(QTR_Font1, 18);
  ImmersionContentFrame.RewardsFrame.Header:SetText(QTR_Messages.rewards);  -- "Nagroda"
  ImmersionContentFrame.RewardsFrame.ItemChooseText:SetFont(QTR_Font2, 13);
  ImmersionContentFrame.RewardsFrame.ItemChooseText:SetText(QTR_Messages.itemchoose1); -- "Możesz wybrać nagrodę:"
  ImmersionContentFrame.RewardsFrame.ItemReceiveText:SetFont(QTR_Font2, 13);
  ImmersionContentFrame.RewardsFrame.ItemReceiveText:SetText(QTR_Messages.itemreceiv1); -- "Otrzymasz w nagrodę:"
  ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText:SetFont(QTR_Font2, 13);
  ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText:SetText(QTR_Messages.experience);  -- "Doświadczenie"
  ImmersionFrame.TalkBox.Elements.Progress.ReqText:SetFont(QTR_Font1, 18);
  ImmersionFrame.TalkBox.Elements.Progress.ReqText:SetText(QTR_Messages.reqitems);  -- "Wymagane itemy:"
end


function QTR_Immersion_OFF()   -- wywoływanie oryginału
  ImmersionContentFrame.ObjectivesText:SetFont(Original_Font2, 14);
  ImmersionContentFrame.ObjectivesText:SetText(QTR_quest_EN.objectives);
  ImmersionFrame.TalkBox.NameFrame.Name:SetFont(Original_Font1, 20);
  ImmersionFrame.TalkBox.NameFrame.Name:SetText(QTR_quest_EN.title);
  ImmersionFrame.TalkBox.TextFrame.Text:SetFont(Original_Font2, 14);
  if (strlen(QTR_quest_EN.details)>0) then                                    -- przywróć oryginalny tekst
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_EN.details);
  elseif (strlen(QTR_quest_EN.progress)>0) then
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_EN.progress);
  else
     ImmersionFrame.TalkBox.TextFrame.Text:SetText(QTR_quest_EN.completion);
  end
  QTR_Immersion_OFF_Static();       -- inne statyczne dane
end


function QTR_Immersion_OFF_Static()
  ImmersionContentFrame.ObjectivesHeader:SetFont(Original_Font1, 18);
  ImmersionContentFrame.ObjectivesHeader:SetText(QTR_MessOrig.objectives);  -- "Zadanie"
  ImmersionContentFrame.RewardsFrame.Header:SetFont(Original_Font1, 18);
  ImmersionContentFrame.RewardsFrame.Header:SetText(QTR_MessOrig.rewards);  -- "Nagroda"
  ImmersionContentFrame.RewardsFrame.ItemChooseText:SetFont(Original_Font2, 13);
  ImmersionContentFrame.RewardsFrame.ItemChooseText:SetText(QTR_MessOrig.itemchoose1); -- "Możesz wybrać nagrodę:"
  ImmersionContentFrame.RewardsFrame.ItemReceiveText:SetFont(Original_Font2, 13);
  ImmersionContentFrame.RewardsFrame.ItemReceiveText:SetText(QTR_MessOrig.itemreceiv1); -- "Otrzymasz w nagrodę:"
  ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText:SetFont(Original_Font2, 13);
  ImmersionContentFrame.RewardsFrame.XPFrame.ReceiveText:SetText(QTR_MessOrig.experience);  -- "Doświadczenie"
  ImmersionFrame.TalkBox.Elements.Progress.ReqText:SetFont(Original_Font1, 18);
  ImmersionFrame.TalkBox.Elements.Progress.ReqText:SetText(QTR_MessOrig.reqitems);  -- "Wymagane itemy:"
end


function QTR_Storyline_Delay()
   QTR_Storyline(1);
end


function QTR_Storyline_Quest()
   if (QTR_PS["active"]=="1" and QTR_PS["other3"]=="1" and Storyline_NPCFrameTitle:IsVisible()) then
      QTR_QuestPrepare('');
   end
end


function QTR_Storyline_Hide()
   if (QTR_PS["active"]=="1" and QTR_PS["other3"]=="1") then
      QTR_ToggleButton5:Hide();
   end
end


function QTR_Storyline_Objectives()
   if (QTR_onDebug) then
      print("QTR_ST: objectives");
   end
   if (QTR_PS["active"]=="1" and QTR_PS["other3"]=="1" and QTR_quest_LG.id>0) then
      local string_ID= tostring(QTR_quest_LG.id);
      Storyline_NPCFrameObjectivesContent.Title:SetText('Zadanie');
      if (QTR_QuestData[string_ID] ) then
         Storyline_NPCFrameObjectivesContent.Objectives:SetText(QTR_ExpandUnitInfo(QTR_QuestData[string_ID]["Objectives"]));
         Storyline_NPCFrameObjectivesContent.Objectives:SetFont(QTR_Font2, 13);
      end   
   end
end


function QTR_Storyline_Rewards()
   if (QTR_onDebug) then
      print("QTR_ST: rewards");
   end
   if (QTR_PS["active"]=="1" and QTR_PS["other3"]=="1") then
      Storyline_NPCFrameRewards.Content.Title:SetText('Nagroda');
   end
end


function QTR_Storyline(nr)
   if (QTR_onDebug) then
      print('QTR_ST: Podmieniam quest '..QTR_quest_LG.id);
   end
   if (QTR_PS["transtitle"]=="1") then
      Storyline_NPCFrameTitle:SetText(QTR_quest_LG.title);
      Storyline_NPCFrameTitle:SetFont(QTR_Font2, 18);
   end
   local string_ID= tostring(QTR_quest_LG.id);
   local texts = { "" };
   if ((Storyline_NPCFrameChat.event ~= nil) and (QTR_QuestData[string_ID] ~= nil))then
      local event = Storyline_NPCFrameChat.event;
      if (event=="QUEST_DETAIL") then
     	   texts = { strsplit("\n", QTR_ExpandUnitInfo(QTR_QuestData[string_ID]["Description"])) };
      end   
      if (event=="QUEST_PROGRESS") then
     	   texts = { strsplit("\n", QTR_ExpandUnitInfo(QTR_QuestData[string_ID]["Progress"])) };
      end   
      if (event=="QUEST_COMPLETE") then
     	   texts = { strsplit("\n", QTR_ExpandUnitInfo(QTR_QuestData[string_ID]["Completion"])) };
      end   
   end
   local ileOry = #Storyline_NPCFrameChat.texts;
   local indeks = 0;
   for i=1,#texts do
      if texts[i]:len() > 0 then
         if (indeks<ileOry) then
            indeks=indeks+1;
            Storyline_NPCFrameChat.texts[indeks]=texts[i];
         end
      end
   end
   Storyline_NPCFrameChatText:SetFont(QTR_Font2, 16);
   if (nr==1) then      -- Reload text
      Storyline_NPCFrameObjectivesContent:Hide();
      Storyline_NPCFrame.chat.currentIndex = 0;
      Storyline_API.playNext(Storyline_NPCFrameModelsYou);  -- reload
   end
end


function QTR_Storyline_OFF(nr)
   if (QTR_onDebug) then
      print('QTR_SToff: Przywracam quest '..QTR_quest_EN.id);
   end
   if (QTR_PS["transtitle"]=="1") then
      Storyline_NPCFrameTitle:SetText(QTR_quest_EN.title);
      Storyline_NPCFrameTitle:SetFont(Original_Font2, 18);
   end
   local string_ID= tostring(QTR_quest_EN.id);
   local texts = { "" };
   if ((Storyline_NPCFrameChat.event ~= nil) and (QTR_QuestData[string_ID] ~= nil))then
      local event = Storyline_NPCFrameChat.event;
      if (event=="QUEST_DETAIL") then
     	   texts = { strsplit("\n", GetQuestText()) };
      end   
      if (event=="QUEST_PROGRESS") then
     	   texts = { strsplit("\n", GetProgressText()) };
      end   
      if (event=="QUEST_COMPLETE") then
     	   texts = { strsplit("\n", GetRewardText()) };
      end   
   end
   local ileOry = #Storyline_NPCFrameChat.texts;
   local indeks = 0;
   for i=1,#texts do
      if texts[i]:len() > 0 then
         if (indeks<ileOry) then
            indeks=indeks+1;
            Storyline_NPCFrameChat.texts[indeks]=texts[i];
         end
      end
   end
   Storyline_NPCFrameChatText:SetFont(Original_Font2, 16);
   if (nr==1) then      -- Reload text
      Storyline_NPCFrameObjectivesContent:Hide();
      Storyline_NPCFrame.chat.currentIndex = 0;
      Storyline_API.playNext(Storyline_NPCFrameModelsYou);  -- reload
   end
end


-- podmieniaj specjane znaki w tekście
function QTR_ExpandUnitInfo(msg)
   msg = string.gsub(msg, "NEW_LINE", "\n");
   msg = string.gsub(msg, "YOUR_NAME1", QTR_PC["name1"]);
   msg = string.gsub(msg, "YOUR_NAME2", QTR_PC["name2"]);
   msg = string.gsub(msg, "YOUR_NAME3", QTR_PC["name3"]);
   msg = string.gsub(msg, "YOUR_NAME4", QTR_PC["name4"]);
   msg = string.gsub(msg, "YOUR_NAME5", QTR_PC["name5"]);
   msg = string.gsub(msg, "YOUR_NAME6", QTR_PC["name6"]);
   msg = string.gsub(msg, "YOUR_NAME7", QTR_PC["name7"]);
   msg = string.gsub(msg, "YOUR_NAME", QTR_name);
   
-- jeszcze obsłużyć YOUR_GENDER(x;y)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local nr_poz = string.find(msg, "YOUR_GENDER");    -- gdy nie znalazł, jest: nil
   while (nr_poz and nr_poz>0) do
      nr_1 = nr_poz + 1;   
      while (string.sub(msg, nr_1, nr_1) ~= "(") do
         nr_1 = nr_1 + 1;
      end
      if (string.sub(msg, nr_1, nr_1) == "(") then
         nr_2 =  nr_1 + 1;
         while (string.sub(msg, nr_2, nr_2) ~= ";") do
            nr_2 = nr_2 + 1;
         end
         if (string.sub(msg, nr_2, nr_2) == ";") then
            nr_3 = nr_2 + 1;
            while (string.sub(msg, nr_3, nr_3) ~= ")") do
               nr_3 = nr_3 + 1;
            end
            if (string.sub(msg, nr_3, nr_3) == ")") then
               if (QTR_sex==3) then        -- forma żeńska
                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
               else                        -- forma męska
                  QTR_forma = string.sub(msg,nr_1+1,nr_2-1);
               end
               msg = string.sub(msg,1,nr_poz-1) .. QTR_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "YOUR_GENDER");
   end

-- jeszcze obsłużyć NPC_GENDER(x;y)
   local nr_1, nr_2, nr_3 = 0;
   local QTR_forma = "";
   local nr_poz = string.find(msg, "NPC_GENDER");    -- gdy nie znalazł, jest: nil
   while (nr_poz and nr_poz>0) do
      nr_1 = nr_poz + 1;   
      while (string.sub(msg, nr_1, nr_1) ~= "(") do
         nr_1 = nr_1 + 1;
      end
      if (string.sub(msg, nr_1, nr_1) == "(") then
         nr_2 =  nr_1 + 1;
         while (string.sub(msg, nr_2, nr_2) ~= ";") do
            nr_2 = nr_2 + 1;
         end
         if (string.sub(msg, nr_2, nr_2) == ";") then
            nr_3 = nr_2 + 1;
            while (string.sub(msg, nr_3, nr_3) ~= ")") do
               nr_3 = nr_3 + 1;
            end
            if (string.sub(msg, nr_3, nr_3) == ")") then
               if (QTR_sex==3) then        -- forma żeńska
                  QTR_forma = string.sub(msg,nr_2+1,nr_3-1);
               else                        -- forma męska
                  QTR_forma = string.sub(msg,nr_1+1,nr_2-1);
               end
               msg = string.sub(msg,1,nr_poz-1) .. QTR_forma .. string.sub(msg,nr_3+1);
            end   
         end
      end
      nr_poz = string.find(msg, "NPC_GENDER");
   end

   if (QTR_sex==3) then        -- płeć żeńska
      msg = string.gsub(msg, "YOUR_CLASS1", player_class.M2);          -- Mianownik (kto, co?)
      msg = string.gsub(msg, "YOUR_CLASS2", player_class.D2);          -- Dopełniacz (kogo, czego?)
      msg = string.gsub(msg, "YOUR_CLASS3", player_class.C2);          -- Celownik (komu, czemu?)
      msg = string.gsub(msg, "YOUR_CLASS4", player_class.B2);          -- Biernik (kogo, co?)
      msg = string.gsub(msg, "YOUR_CLASS5", player_class.N2);          -- Narzędnik (z kim, z czym?)
      msg = string.gsub(msg, "YOUR_CLASS6", player_class.K2);          -- Miejscownik (o kim, o czym?)
      msg = string.gsub(msg, "YOUR_CLASS7", player_class.W2);          -- Wołacz (o!)
      msg = string.gsub(msg, "YOUR_RACE1", player_race.M2);            -- Mianownik (kto, co?)
      msg = string.gsub(msg, "YOUR_RACE2", player_race.D2);            -- Dopełniacz (kogo, czego?)
      msg = string.gsub(msg, "YOUR_RACE3", player_race.C2);            -- Celownik (komu, czemu?)
      msg = string.gsub(msg, "YOUR_RACE4", player_race.B2);            -- Biernik (kogo, co?)
      msg = string.gsub(msg, "YOUR_RACE5", player_race.N2);            -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, "YOUR_RACE6", player_race.K2);            -- Miejscownik (o kim, o czym?)
      msg = string.gsub(msg, "YOUR_RACE7", player_race.W2);            -- Wołacz (o!)
      msg = string.gsub(msg, "YOUR_RACE YOUR_CLASS", "YOUR_RACE "..player_class.M2);     -- Mianownik (kto, co?)
      msg = string.gsub(msg, "ą YOUR_RACE", "ą "..player_race.N2);              -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, " jesteś YOUR_RACE", " jesteś "..player_race.N2);    -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, "YOUR_RACE", player_race.W2);                        -- Wołacz - pozostałe wystąpienia
      msg = string.gsub(msg, "ą YOUR_CLASS", "ą "..player_class.N2);            -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, "esteś YOUR_CLASS", "esteś "..player_class.N2);      -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, " z Ciebie YOUR_CLASS", " z Ciebie "..player_class.M2);    -- Mianownik (kto, co?)
      msg = string.gsub(msg, " kolejny YOUR_CLASS do ", " kolejny "..player_class.M2.." do ");   -- Mianownik (kto, co?)
      msg = string.gsub(msg, " taki YOUR_CLASS", " taki "..player_class.M2);      -- Mianownik (kto, co?)
      msg = string.gsub(msg, "ako YOUR_CLASS", "ako "..player_class.M2);          -- Mianownik (kto, co?)
      msg = string.gsub(msg, " co sprowadza YOUR_CLASS", " co sprowadza "..player_class.B2);     -- Biernik (kogo, co?)
      msg = string.gsub(msg, " będę miał YOUR_CLASS", " będę miał "..player_class.B2);  -- Biernik (kogo, co?)
      msg = string.gsub(msg, "YOUR_CLASS taki jak ", player_class.B2.." taki jak ");    -- Biernik (kogo, co?)
      msg = string.gsub(msg, " jak na YOUR_CLASS", " jak na "..player_class.B2);        -- Biernik (kogo, co?)
      msg = string.gsub(msg, "YOUR_CLASS", player_class.W2);                      -- Wołacz - pozostałe wystąpienia
   else                    -- płeć męska
      msg = string.gsub(msg, "YOUR_CLASS1", player_class.M1);          -- Mianownik (kto, co?)
      msg = string.gsub(msg, "YOUR_CLASS2", player_class.D1);          -- Dopełniacz (kogo, czego?)
      msg = string.gsub(msg, "YOUR_CLASS3", player_class.C1);          -- Celownik (komu, czemu?)
      msg = string.gsub(msg, "YOUR_CLASS4", player_class.B1);          -- Biernik (kogo, co?)
      msg = string.gsub(msg, "YOUR_CLASS5", player_class.N1);          -- Narzędnik (z kim, z czym?)
      msg = string.gsub(msg, "YOUR_CLASS6", player_class.K1);          -- Miejscownik (o kim, o czym?)
      msg = string.gsub(msg, "YOUR_CLASS7", player_class.W1);          -- Wołacz (o!)
      msg = string.gsub(msg, "YOUR_RACE1", player_race.M1);            -- Mianownik (kto, co?)
      msg = string.gsub(msg, "YOUR_RACE2", player_race.D1);            -- Dopełniacz (kogo, czego?)
      msg = string.gsub(msg, "YOUR_RACE3", player_race.C1);            -- Celownik (komu, czemu?)
      msg = string.gsub(msg, "YOUR_RACE4", player_race.B1);            -- Biernik (kogo, co?)
      msg = string.gsub(msg, "YOUR_RACE5", player_race.N1);            -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, "YOUR_RACE6", player_race.K1);            -- Miejscownik (o kim, o czym?)
      msg = string.gsub(msg, "YOUR_RACE7", player_race.W1);            -- Wołacz (o!)
      msg = string.gsub(msg, "YOUR_RACE YOUR_CLASS", "YOUR_RACE "..player_class.M1);     -- Mianownik (kto, co?)
      msg = string.gsub(msg, "ym YOUR_RACE", "ym "..player_race.N1);              -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, " jesteś YOUR_RACE", " jesteś "..player_race.N1);    -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, "YOUR_RACE", player_race.W1);                        -- Wołacz - pozostałe wystąpienia
      msg = string.gsub(msg, "ym YOUR_CLASS", "ym "..player_class.N1);            -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, "esteś YOUR_CLASS", "esteś "..player_class.N1);      -- Narzędnik (kim, czym?)
      msg = string.gsub(msg, " z Ciebie YOUR_CLASS", " z Ciebie "..player_class.M1);    -- Mianownik (kto, co?)
      msg = string.gsub(msg, " kolejny YOUR_CLASS do ", " kolejny "..player_class.M1.." do ");   -- Mianownik (kto, co?)
      msg = string.gsub(msg, " taki YOUR_CLASS", " taki "..player_class.M1);      -- Mianownik (kto, co?)
      msg = string.gsub(msg, "ako YOUR_CLASS", "ako "..player_class.M1);          -- Mianownik (kto, co?)
      msg = string.gsub(msg, " co sprowadza YOUR_CLASS", " co sprowadza "..player_class.B1);     -- Biernik (kogo, co?)
      msg = string.gsub(msg, " będę miał YOUR_CLASS", " będę miał "..player_class.B1);  -- Biernik (kogo, co?)
      msg = string.gsub(msg, "ego YOUR_CLASS", "ego "..player_class.B1);                -- Biernik (kogo, co?)
      msg = string.gsub(msg, "YOUR_CLASS taki jak ", player_class.B1.." taki jak ");    -- Biernik (kogo, co?)
      msg = string.gsub(msg, " jak na YOUR_CLASS", " jak na "..player_class.B1);        -- Biernik (kogo, co?)
      msg = string.gsub(msg, "YOUR_CLASS", player_class.W1);                      -- Wołacz - pozostałe wystąpienia
   end
   
   return msg;
end

