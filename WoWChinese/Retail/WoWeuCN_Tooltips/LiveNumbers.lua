-- Addon: WoWeuCN-Tooltips
-- Author: qqytqqyt
--
-- Live numbers for the translated spell and item tooltips.
--
-- The Chinese text is a snapshot of the zhCN client at scan time: scaling values were rendered for the
-- scanning character (no stats, so "造成3点火焰伤害") and items in their base variant. Before a
-- translation is added to a tooltip, this module copies the numbers of the tooltip that is actually on
-- screen into it, so damage, healing, absorbs and item effects read what the player really gets.
--
-- Translations move numbers around, so the copy is never positional:
--   1. The stored lines are aligned with the tooltip's own lines (left and right text of every row, in
--      order). Lines pair up by the count and kind of their numbers, by equal values, by line colour and,
--      for the spell header lines, by matching the client's own templates (SPELL_CAST_TIME_SEC and the
--      like), which works in every client language.
--   2. Inside a pair, static numbers that are equal on both sides anchor each other (durations,
--      percentages, counts). The remaining numbers are paired within their kind - percentages, grey
--      scaling values, plain values - in reading order. Two or more scaling values whose order the
--      translation swapped are caught by the scaling check: the values of one spell scale by about the
--      same factor, so the pairing with the consistent ratios wins. A scaling value next to a static a
--      talent changed is told apart by size. Scaling values are the grey ones and those in front of a
--      damage, healing, health or mana unit.
--   3. A kind whose counts differ (a talent added a clause, a patch rewrote the description) keeps the
--      stored numbers: a stale number is better than a wrong one.
-- Live numbers are read in the client's format (LARGE_NUMBER_SEPERATOR / DECIMAL_SEPERATOR) and written
-- the way the zhCN client writes them ("1,234.5"). The grey wrap of a stored scaling value marks a
-- placeholder; a slot that received its live number is written in the colour of its surroundings.

local GREY = "7f7f7f"
local SPACES = { " ", "\194\160", "\226\128\175" } -- space, no-break space, narrow no-break space
local SIDES = { "Left", "Right" }

-- Header lines of a spell tooltip: the Chinese suffix names the line, the client templates say what the
-- same line looks like in the client's language (side is the fallback when a client lacks the templates)
local HEADERS = {
  { suffixes = { "施法时间" }, side = "L", templates = { "SPELL_CAST_TIME_SEC", "SPELL_CAST_TIME_MIN" } },
  { suffixes = { "冷却时间" }, side = "R", templates = { "SPELL_RECAST_TIME_SEC", "SPELL_RECAST_TIME_MIN", "SPELL_RECAST_TIME_HOURS", "SPELL_RECAST_TIME_DAYS" } },
  { suffixes = { "充能时间" }, side = "R", templates = { "SPELL_RECAST_TIME_CHARGES_SEC", "SPELL_RECAST_TIME_CHARGES_MIN", "SPELL_RECAST_TIME_CHARGES_HOURS", "SPELL_RECAST_TIME_CHARGES_DAYS" } },
  { suffixes = { "码射程", "码距离" }, side = "R", templates = { "SPELL_RANGE", "SPELL_RANGE_DUAL" } },
}

-- Tooltip lines that never have a stored counterpart and only confuse the alignment
local EXCLUDED_TEMPLATES = { "SPELL_TIME_REMAINING_SEC", "SPELL_TIME_REMAINING_MIN", "SPELL_TIME_REMAINING_HOURS", "SPELL_TIME_REMAINING_DAYS" }
local EXCLUDED_PREFIXES = { "SELL_PRICE" }

-- The English templates, used when WoWeuCN_Interface has replaced the client's with Chinese ones
local ENGLISH_TEMPLATES = {
  SPELL_CAST_TIME_SEC = "%.2g sec cast",
  SPELL_CAST_TIME_MIN = "%.2g min cast",
  SPELL_RECAST_TIME_SEC = "%.2g sec cooldown",
  SPELL_RECAST_TIME_MIN = "%.2g min cooldown",
  SPELL_RECAST_TIME_HOURS = "%.2g hour cooldown",
  SPELL_RECAST_TIME_DAYS = "%.2g day cooldown",
  SPELL_RECAST_TIME_CHARGES_SEC = "%.2g sec recharge",
  SPELL_RECAST_TIME_CHARGES_MIN = "%.2g min recharge",
  SPELL_RECAST_TIME_CHARGES_HOURS = "%.2g hour recharge",
  SPELL_RECAST_TIME_CHARGES_DAYS = "%.2g day recharge",
  SPELL_RANGE = "%s yd range",
  SPELL_RANGE_DUAL = "%1$s: %2$s yd range",
  SPELL_TIME_REMAINING_SEC = "%d |4second:seconds; remaining",
  SPELL_TIME_REMAINING_MIN = "%d |4minute:minutes; remaining",
  SPELL_TIME_REMAINING_HOURS = "%d |4hour:hours; remaining",
  SPELL_TIME_REMAINING_DAYS = "%d |4day:days; remaining",
  SELL_PRICE = "Sell Price",
}

-- A client string, unless it is Chinese: WoWeuCN_Interface replaces the Lua globals, but the tooltip
-- itself is still rendered in the client's language, so the English text is the better guess then
local function ClientString(name)
  local text = _G[name]
  if type(text) ~= "string" or text:find("[\228-\233]") then
    return ENGLISH_TEMPLATES[name]
  end
  return text
end

local function IsSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

local function IsDigitAt(text, pos)
  local c = text:byte(pos)
  return c ~= nil and c >= 48 and c <= 57
end

-- Length of the separator at pos, or nil; a blank separator accepts every blank the client uses
local function SeparatorAt(text, pos, sep)
  if sep == nil or sep == "" then
    return nil
  end
  if text:sub(pos, pos + #sep - 1) == sep then
    return #sep
  end
  if sep == SPACES[1] or sep == SPACES[2] or sep == SPACES[3] then
    for _, alt in ipairs(SPACES) do
      if text:sub(pos, pos + #alt - 1) == alt then
        return #alt
      end
    end
  end
  return nil
end

local function ClientSeparators()
  local group, decimal = LARGE_NUMBER_SEPERATOR, DECIMAL_SEPERATOR
  if type(group) ~= "string" or group == "" then
    group = ","
  end
  if type(decimal) ~= "string" or decimal == "" then
    decimal = "."
  end
  return group, decimal
end

-- The numbers of a text: { s, e = byte range, int, dec = digit strings, value, grouped, percent, grey }.
-- Escape sequences are skipped, so colour codes, textures and link data never count as numbers. A number
-- is grey - a scaling value - when a grey colour code sits right in front of it and a reset right behind
-- it ("|cff7f7f7f1,234|r"), the shape the scanner data and the client's spell links give such values;
-- the numbers of a line that is grey as a whole are ordinary numbers.
local function Tokenize(text, group, decimal)
  local tokens = {}
  local pos, len = 1, #text
  local colour, codeEnd
  while pos <= len do
    local c = text:byte(pos)
    if c == 124 then -- "|"
      local n = text:byte(pos + 1)
      if n == 99 or n == 67 then -- |cffrrggbb or |cnNAME: (the client also writes |C)
        local hex = text:match("^%x%x%x%x%x%x%x%x", pos + 2)
        if hex then
          colour = hex:lower():sub(-6) -- rrggbb, whatever the alpha
          pos = pos + 10
        else
          local named = text:match("^n[^:|]*:", pos + 2)
          colour = named
          pos = pos + 2 + (named and #named or 0)
        end
        codeEnd = pos
      elseif n == 114 or n == 82 then -- |r or |R
        colour = nil
        pos = pos + 2
      elseif n == 84 or n == 65 or n == 72 then -- |T...|t  |A...|a  |H...|h
        local closer = (n == 84 and "|t") or (n == 65 and "|a") or "|h"
        local _, e = text:find(closer, pos + 2, true)
        pos = e and (e + 1) or (len + 1)
      else -- ||, |n, the closing |h
        pos = pos + 2
      end
    elseif c >= 48 and c <= 57 then
      local s, e = pos, pos
      while IsDigitAt(text, e + 1) do
        e = e + 1
      end
      local grouped = false
      while true do -- a group separator followed by exactly three digits
        local sl = SeparatorAt(text, e + 1, group)
        if not sl then
          break
        end
        local p = e + 1 + sl
        if IsDigitAt(text, p) and IsDigitAt(text, p + 1) and IsDigitAt(text, p + 2) and not IsDigitAt(text, p + 3) then
          e = p + 2
          grouped = true
        else
          break
        end
      end
      local int = text:sub(s, e):gsub("%D", "")
      local dec = ""
      local dl = SeparatorAt(text, e + 1, decimal)
      if dl and IsDigitAt(text, e + 1 + dl) then
        local d = e + 1 + dl
        while IsDigitAt(text, d + 1) do
          d = d + 1
        end
        dec = text:sub(e + 1 + dl, d)
        e = d
      end
      local after = e + 1
      while true do -- "50 %" in some languages
        local sl
        for _, alt in ipairs(SPACES) do
          if text:sub(after, after + #alt - 1) == alt then
            sl = #alt
            break
          end
        end
        if not sl then
          break
        end
        after = after + sl
      end
      tokens[#tokens + 1] = {
        s = s,
        e = e,
        int = int,
        dec = dec,
        grouped = grouped,
        value = tonumber(int .. "." .. (dec == "" and "0" or dec)),
        percent = text:byte(after) == 37,
        grey = colour == GREY and codeEnd == s and text:sub(e + 1, e + 2):lower() == "|r",
      }
      pos = e + 1
    else
      pos = pos + 1
    end
  end
  return tokens
end

-- A live number written the zhCN way; grouping follows the live text, which groups where Blizzard does
local function FormatNumber(token)
  local int = token.int
  if token.grouped then
    int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if int:sub(1, 1) == "," then
      int = int:sub(2)
    end
  end
  if token.dec ~= "" then
    return int .. "." .. token.dec
  end
  return int
end

-- Lua patterns matching a text rendered from a client format string such as "%.2g sec cast"; the
-- |4one:many; plural markers expand to one pattern per form. The patterns are cached per template text.
local templateCache = {}
local function TemplatePatterns(name)
  local template = ClientString(name)
  if template == nil then
    return nil
  end
  local cached = templateCache[template]
  if cached ~= nil then
    return cached
  end
  local texts = { template }
  while true do
    local expanded, changed = {}, false
    for _, t in ipairs(texts) do
      local s, e, forms = t:find("|4([^;]*);")
      if s then
        changed = true
        for form in (forms .. ":"):gmatch("([^:]*):") do
          expanded[#expanded + 1] = t:sub(1, s - 1) .. form .. t:sub(e + 1)
        end
      else
        expanded[#expanded + 1] = t
      end
    end
    texts = expanded
    if not changed then
      break
    end
  end
  local patterns = {}
  for _, t in ipairs(texts) do
    local p = t:gsub("%%%%", "\1") -- a literal percent sign
    p = p:gsub("%%%d*%$?[%-%+ #0]*%d*%.?%d*[a-zA-Z]", "\2") -- a format specifier
    p = p:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") -- pattern magic characters
    p = p:gsub("\1", "%%%%")
    p = p:gsub("\2", "(.-)")
    patterns[#patterns + 1] = "^" .. p .. "$"
  end
  templateCache[template] = patterns
  return patterns
end

-- Whether a text was rendered from one of the named templates: true/false, nil when none is known
local function MatchesTemplate(text, names)
  local known = false
  for _, name in ipairs(names) do
    local patterns = TemplatePatterns(name)
    if patterns then
      known = true
      for _, pattern in ipairs(patterns) do
        if text:find(pattern) then
          return true
        end
      end
    end
  end
  if known then
    return false
  end
  return nil
end

local function IsExcluded(text)
  if MatchesTemplate(text, EXCLUDED_TEMPLATES) then
    return true
  end
  for _, name in ipairs(EXCLUDED_PREFIXES) do
    local prefix = ClientString(name)
    if prefix ~= nil and prefix ~= "" and text:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

-- The colour of a stored line is the colour code the data wraps it in; white lines have none
local function StoredColour(text)
  local r, g, b = text:match("^|c%x%x(%x%x)(%x%x)(%x%x)")
  if r then
    return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
  end
  return 1, 1, 1
end

local function IsWhite(line)
  return line.r > 0.9 and line.g > 0.9 and line.b > 0.9
end

local function SameColour(a, b)
  return math.abs(a.r - b.r) <= 0.06 and math.abs(a.g - b.g) <= 0.06 and math.abs(a.b - b.b) <= 0.06
end

-- Whether the stored text right after a number names a scaling quantity ("点冰霜伤害", "点治疗", "点生命值",
-- "点法力值"). The data marks such numbers grey, but only for the damage schools it knows; a number in
-- front of a unit scales with the character all the same.
local SCALING_UNITS = { "伤害", "治疗", "生命值", "法力值" }
local function ScalesByUnit(text, e)
  local pos = e + 1
  while text:byte(pos) == 124 do -- escape codes between the number and its unit
    local n = text:byte(pos + 1)
    if n == 99 or n == 67 then
      pos = pos + 10
    elseif n == 114 or n == 82 then
      pos = pos + 2
    else
      break
    end
  end
  if text:sub(pos, pos + 2) ~= "点" then
    return false
  end
  pos = pos + 3
  for _, unit in ipairs(SCALING_UNITS) do
    local s = text:find(unit, pos, true)
    if s and s - pos <= 12 then
      local between = text:sub(pos, s - 1)
      if not between:find("[%z\1-\127]") and not between:find("，", 1, true) and not between:find("。", 1, true) then
        return true
      end
    end
  end
  return false
end

local function StoredLine(text, kind)
  local line = { text = text, tokens = Tokenize(text, ",", ".") }
  for _, token in ipairs(line.tokens) do
    token.scaling = token.grey or ScalesByUnit(text, token.e)
  end
  line.r, line.g, line.b = StoredColour(text)
  if kind == "spell" then
    if text:find("|cffffd100", 1, true) then
      -- the description: the gold line, even when it opens with a differently coloured name
      line.side = "L"
      line.r, line.g, line.b = 1, 0.82, 0
    else
      for _, header in ipairs(HEADERS) do
        for _, suffix in ipairs(header.suffixes) do
          if #text > #suffix and text:sub(-#suffix) == suffix then
            line.header = header
            line.side = header.side
          end
        end
      end
    end
  end
  return line
end

-- The non-empty texts of the tooltip in region order (left, right, left, right, ...). A secret text
-- (12.x hides some combat values) is left out: it could not be read, so it cannot be aligned either.
-- An unnamed tooltip is taken for GameTooltip, as the rest of the addon does.
local function ReadTooltip(tooltip, group, decimal)
  if not tooltip.NumLines then
    return nil
  end
  local name = (tooltip.GetName and tooltip:GetName()) or "GameTooltip"
  local lines = {}
  for i = 1, tooltip:NumLines() do
    for _, side in ipairs(SIDES) do
      local region = _G[name .. "Text" .. side .. i]
      local text = region and region:GetText()
      if text ~= nil and not IsSecret(text) then
        if text ~= "" and text ~= " " and not IsExcluded(text) then
          local r, g, b = region:GetTextColor()
          if IsSecret(r) or IsSecret(g) or IsSecret(b) then
            r, g, b = nil, nil, nil
          end
          lines[#lines + 1] = {
            text = text,
            tokens = Tokenize(text, group, decimal),
            r = r or 1, g = g or 1, b = b or 1,
            side = side:sub(1, 1),
          }
        end
      end
    end
  end
  return lines
end

-- Static numbers of the stored line found in the live line, ignoring order; a scaling stored number
-- says nothing about which line it belongs to, however many live numbers happen to equal it
local function CommonValues(a, b)
  local used, count = {}, 0
  for _, ta in ipairs(a) do
    for j, tb in ipairs(b) do
      if not ta.scaling and not used[j] and ta.value == tb.value and ta.percent == tb.percent then
        used[j] = true
        count = count + 1
        break
      end
    end
  end
  return count
end

local function PercentCount(tokens)
  local count = 0
  for _, token in ipairs(tokens) do
    if token.percent then
      count = count + 1
    end
  end
  return count
end

-- How well a stored line and a live line go together; 0 means they never pair
local function PairScore(stored, live)
  local info = { header = false, colour = false, common = 0 }
  if stored.header then
    local matched = MatchesTemplate(live.text, stored.header.templates)
    if matched == false then
      return 0, info
    end
    info.header = matched == true
  end
  if stored.side and live.side and stored.side ~= live.side then
    return 0, info
  end
  local na, nb = #stored.tokens, #live.tokens
  local score
  if na == 0 and nb == 0 then
    score = 1
  elseif na == 0 or nb == 0 then
    return 0, info
  elseif na ~= nb then
    info.common = CommonValues(stored.tokens, live.tokens)
    score = 0.5 + 0.5 * info.common
  else
    info.common = CommonValues(stored.tokens, live.tokens)
    score = 2 + info.common - 0.5 * math.abs(PercentCount(stored.tokens) - PercentCount(live.tokens))
  end
  if info.header then
    score = score + 2
  end
  info.colour = SameColour(stored, live)
  if info.colour then
    score = score + (IsWhite(stored) and 0.5 or 1)
  elseif not IsWhite(live) then
    score = score - 0.5
  end
  if score <= 0 then
    return 0, info
  end
  return score, info
end

-- Pairs two sequences in order, maximising the sum of score(i, j) over the pairs (0 = never pair); an
-- element pairs with the earliest partner that achieves the maximum. Returns pairs[i] = j.
local function AlignSequences(n, m, score)
  local best, scores = {}, {}
  for i = 0, n do
    best[i] = {}
    for j = 0, m do
      best[i][j] = 0
    end
  end
  for i = 1, n do
    scores[i] = {}
    for j = 1, m do
      local s = score(i, j)
      scores[i][j] = s
      local v = best[i - 1][j]
      if best[i][j - 1] > v then
        v = best[i][j - 1]
      end
      if s > 0 and best[i - 1][j - 1] + s > v then
        v = best[i - 1][j - 1] + s
      end
      best[i][j] = v
    end
  end
  local pairs_ = {}
  local i, j = n, m
  while i > 0 and j > 0 do
    local s = scores[i][j]
    if best[i][j] == best[i][j - 1] then
      j = j - 1
    elseif best[i][j] == best[i - 1][j] then
      i = i - 1
    elseif s > 0 and best[i][j] == best[i - 1][j - 1] + s then
      pairs_[i] = j
      i, j = i - 1, j - 1
    else
      i = i - 1
    end
  end
  return pairs_
end

-- Pairs the stored lines with the live lines. Returns pairs[storedIndex] = liveIndex and
-- infos[storedIndex] = the pair's info.
local function Align(stored, live)
  local scores, infos = {}, {}
  for i = 1, #stored do
    scores[i], infos[i] = {}, {}
    for j = 1, #live do
      scores[i][j], infos[i][j] = PairScore(stored[i], live[j])
    end
  end
  local pairs_ = AlignSequences(#stored, #live, function(i, j) return scores[i][j] end)
  local pairInfos = {}
  for i, j in pairs(pairs_) do
    pairInfos[i] = infos[i][j]
  end
  return pairs_, pairInfos
end

-- Whether a pair carries enough evidence to copy numbers across. With a different number of numbers on
-- the two sides (a talent added a clause) the lines must be tied together by their colour (the gold
-- description, a green item effect) or by an equal number.
local function Confident(stored, live, info)
  local n = #stored.tokens
  if n == 0 or #live.tokens == 0 then
    return false
  end
  if n ~= #live.tokens then
    return (info.colour and not IsWhite(stored)) or (info.common > 0 and (info.colour or IsWhite(live)))
  end
  if info.header or info.common > 0 then
    return true
  end
  if n >= 2 then
    return info.colour or IsWhite(live)
  end
  if stored.side and live.side and stored.side == live.side then
    return true
  end
  return info.colour and not IsWhite(stored)
end

local function KindKey(token, useGrey)
  local key = token.percent and "p" or "n"
  if useGrey then
    key = key .. (token.grey and "g" or "w")
  end
  return key
end

-- Numbers equal in value and kind on both sides, matched in order (longest common subsequence). A
-- scaling stored number never anchors: the stale "18 to 20" of a damage range would otherwise latch
-- onto the live "20 to 25" by its 20 and swap the bounds.
local function Anchors(stored, live, useGrey)
  local n, m = #stored, #live
  local L = {}
  for i = 0, n do
    L[i] = {}
    for j = 0, m do
      L[i][j] = 0
    end
  end
  local function same(i, j)
    return not stored[i].scaling and stored[i].value == live[j].value and KindKey(stored[i], useGrey) == KindKey(live[j], useGrey)
  end
  for i = 1, n do
    for j = 1, m do
      if same(i, j) then
        L[i][j] = L[i - 1][j - 1] + 1
      elseif L[i - 1][j] >= L[i][j - 1] then
        L[i][j] = L[i - 1][j]
      else
        L[i][j] = L[i][j - 1]
      end
    end
  end
  local storedUsed, liveUsed, anchorOf = {}, {}, {}
  local i, j = n, m
  while i > 0 and j > 0 do
    if same(i, j) and L[i][j] == L[i - 1][j - 1] + 1 then
      storedUsed[i], liveUsed[j], anchorOf[i] = true, true, j
      i, j = i - 1, j - 1
    elseif L[i - 1][j] >= L[i][j - 1] then
      i = i - 1
    else
      j = j - 1
    end
  end
  return storedUsed, liveUsed, anchorOf
end

local function Ranked(list)
  local order = {}
  for i = 1, #list do
    order[i] = i
  end
  table.sort(order, function(x, y)
    if list[x].value ~= list[y].value then
      return list[x].value < list[y].value
    end
    return x < y
  end)
  return order
end

-- Spread of the scaling factors of a pairing (log ratio live/stored); nil when a value is zero
local function Spread(stored, live, order)
  local lo, hi = math.huge, -math.huge
  for i = 1, #stored do
    local a, b = stored[i].value, live[order[i]].value
    if a <= 0 or b <= 0 then
      return nil
    end
    local ratio = math.log(b / a)
    if ratio < lo then
      lo = ratio
    end
    if ratio > hi then
      hi = ratio
    end
  end
  return hi - lo
end

-- Calls fn with every permutation of 1..k, the identity first
local function EachPermutation(k, fn)
  local perm, used = {}, {}
  local function step(depth)
    if depth > k then
      fn(perm)
      return
    end
    for v = 1, k do
      if not used[v] then
        used[v] = true
        perm[depth] = v
        step(depth + 1)
        used[v] = false
      end
    end
  end
  step(1)
end

-- Pairs leftover numbers of one kind (same count on both sides). Reading order is the default, and the
-- only choice when none of the stored numbers scales (statics a talent changed) or when a value is zero.
-- Scaling values only: the translation may have swapped them, which shows as inconsistent scaling
-- factors, so the pairing by rank wins when its factors agree clearly better. Scaling values mixed with
-- changed statics (a talent lowered a cost next to the damage value) are told apart by size: the scaling
-- value takes the live number that grew, the static the one that stayed close, and several scaling
-- values must still agree on their factor. Ties keep the reading order.
local function PairLeftovers(stored, live)
  local k = #stored
  local order = {}
  for i = 1, k do
    order[i] = i
  end
  if k < 2 or k > 5 then
    return order
  end
  local scaling = 0
  for i = 1, k do
    if stored[i].scaling then
      scaling = scaling + 1
    end
    if stored[i].value <= 0 or live[i].value <= 0 then
      return order
    end
  end
  if scaling == 0 then
    return order
  end
  if scaling == k then
    local storedRank, liveRank = Ranked(stored), Ranked(live)
    local ranked = {}
    for r = 1, k do
      ranked[storedRank[r]] = liveRank[r]
    end
    local byOrder, byRank = Spread(stored, live, order), Spread(stored, live, ranked)
    if byRank + 0.35 < byOrder then
      return ranked
    end
    return order
  end
  local function Score(perm)
    local s, lo, hi = 0, math.huge, -math.huge
    for i = 1, k do
      local ratio = math.log(live[perm[i]].value / stored[i].value)
      if stored[i].scaling then
        s = s + ratio
        if ratio < lo then
          lo = ratio
        end
        if ratio > hi then
          hi = ratio
        end
      else
        s = s - math.abs(ratio)
      end
    end
    if scaling > 1 then
      s = s - (hi - lo)
    end
    return s
  end
  local best, bestScore = order, Score(order)
  EachPermutation(k, function(perm)
    local s = Score(perm)
    if s > bestScore + 0.35 then
      best, bestScore = { unpack(perm) }, s
    end
  end)
  return best
end

-- The edit that puts a live number in place of a stored token. Grey marks a placeholder, so a filled
-- slot loses its grey wrap "|r|cff7f7f7f N |r" together with the colour code re-opened right after it
-- when that colour was already in effect in front of the wrap.
local function Replacement(text, token, number)
  if not token.grey then
    return { s = token.s, e = token.e, text = number }
  end
  local s, e = token.s - 10, token.e + 2
  if text:sub(s - 2, s - 1):lower() == "|r" then
    s = s - 2
  end
  local after = text:match("^|[cC]%x%x%x%x%x%x%x%x", e + 1)
  if after then
    local prefix = text:sub(1, s - 1)
    local codeStart = prefix:match(".*()|[cC]%x%x%x%x%x%x%x%x")
    if codeStart and prefix:sub(codeStart, codeStart + 9):lower() == after:lower()
        and not prefix:sub(codeStart + 10):lower():find("|r", 1, true) then
      e = e + 10
    end
  end
  return { s = s, e = e, text = number }
end

-- Pairs the leftover tokens of one kind (equal counts on both sides) and records the edits
local function PairGroup(text, storedList, liveList, replacements)
  local order = PairLeftovers(storedList, liveList)
  for i, token in ipairs(storedList) do
    local number = FormatNumber(liveList[order[i]])
    if token.grey or number ~= text:sub(token.s, token.e) then
      replacements[#replacements + 1] = Replacement(text, token, number)
    end
  end
end

-- Where the sentences of a text end: line breaks, full-width terminators, and ASCII terminators that
-- are followed by a blank, an escape sequence or the end (so "5.2 sec" stays whole)
local function SentenceEnds(text)
  local ends = {}
  local pos, len = 1, #text
  while pos <= len do
    local c = text:byte(pos)
    if c == 10 or c == 13 then
      ends[#ends + 1] = pos
    elseif c == 124 and text:byte(pos + 1) == 110 then -- |n
      ends[#ends + 1] = pos + 1
      pos = pos + 1
    elseif c == 46 or c == 33 or c == 63 or c == 59 then -- . ! ? ;
      local n = text:byte(pos + 1)
      if n == nil or n == 32 or n == 10 or n == 13 or n == 124 then
        ends[#ends + 1] = pos
      end
    elseif c == 227 and text:byte(pos + 1) == 128 and text:byte(pos + 2) == 130 then -- 。
      ends[#ends + 1] = pos + 2
      pos = pos + 2
    elseif c == 239 and text:byte(pos + 1) == 188 then
      local t = text:byte(pos + 2)
      if t == 129 or t == 159 or t == 155 then -- ！ ？ ；
        ends[#ends + 1] = pos + 2
        pos = pos + 2
      end
    end
    pos = pos + 1
  end
  return ends
end

-- The sentence index of every token, and the number of sentences
local function SentenceOf(text, tokens)
  local ends = SentenceEnds(text)
  local sentence, k, index = {}, 1, 1
  for i, token in ipairs(tokens) do
    while ends[k] and ends[k] < token.s do
      k = k + 1
      index = index + 1
    end
    sentence[i] = index
  end
  return sentence, #ends + 1
end

-- Kinds whose counts differ on the whole line (a talent added a clause with numbers of its own) are
-- paired sentence by sentence. Sentences align like lines do, by the anchors they share and by the
-- counts of their leftover numbers per kind, so the talent's sentence drops out and the sentence with
-- the damage value still finds its partner. A sentence pair whose counts still differ keeps its numbers.
local function PairBySentence(stored, live, storedUsed, liveUsed, anchorOf, useGrey, kinds, replacements)
  local function Sentences(line, used)
    local sentenceOf, count = SentenceOf(line.text, line.tokens)
    local sentences = {}
    for s = 1, count do
      sentences[s] = { anchors = {}, leftovers = {}, count = 0 }
    end
    for i, token in ipairs(line.tokens) do
      local sentence = sentences[sentenceOf[i]]
      if used[i] then
        sentence.anchors[i] = true
      else
        local key = KindKey(token, useGrey)
        if kinds[key] then
          sentence.leftovers[key] = sentence.leftovers[key] or {}
          table.insert(sentence.leftovers[key], token)
          sentence.count = sentence.count + 1
        end
      end
    end
    return sentences
  end
  local A, B = Sentences(stored, storedUsed), Sentences(live, liveUsed)

  local function score(a, b)
    local sa, sb = A[a], B[b]
    local shared = 0
    for i in pairs(sa.anchors) do
      if anchorOf[i] and sb.anchors[anchorOf[i]] then
        shared = shared + 1
      end
    end
    if sa.count == 0 and sb.count == 0 then
      return 1 + 2 * shared
    end
    if sa.count == 0 or sb.count == 0 then
      return 2 * shared
    end
    local equal, unequal = 0, 0
    for key, list in pairs(sa.leftovers) do
      local other = sb.leftovers[key]
      if other and #other == #list then
        equal = equal + 1
      else
        unequal = unequal + 1
      end
    end
    for key in pairs(sb.leftovers) do
      if not sa.leftovers[key] then
        unequal = unequal + 1
      end
    end
    local s = 2 * shared
    if unequal == 0 then
      s = s + 2
    elseif equal > 0 then
      s = s + 1
    else
      s = s + 0.5
    end
    return s
  end

  local pairs_ = AlignSequences(#A, #B, score)
  for a, b in pairs(pairs_) do
    for key, list in pairs(A[a].leftovers) do
      local other = B[b].leftovers[key]
      if other and #other == #list then
        PairGroup(stored.text, list, other, replacements)
      end
    end
  end
end

-- The stored text with the live numbers copied in
local function Substitute(stored, live)
  local storedTokens, liveTokens = stored.tokens, live.tokens
  local storedGrey, liveGrey = 0, 0
  for _, token in ipairs(storedTokens) do
    if token.grey then
      storedGrey = storedGrey + 1
    end
  end
  for _, token in ipairs(liveTokens) do
    if token.grey then
      liveGrey = liveGrey + 1
    end
  end
  local useGrey = storedGrey > 0 and storedGrey == liveGrey

  local storedUsed, liveUsed, anchorOf = Anchors(storedTokens, liveTokens, useGrey)
  local groups = {}
  for i, token in ipairs(storedTokens) do
    if not storedUsed[i] then
      local key = KindKey(token, useGrey)
      groups[key] = groups[key] or { stored = {}, live = {} }
      table.insert(groups[key].stored, token)
    end
  end
  for j, token in ipairs(liveTokens) do
    if not liveUsed[j] then
      local key = KindKey(token, useGrey)
      groups[key] = groups[key] or { stored = {}, live = {} }
      table.insert(groups[key].live, token)
    end
  end

  local text = stored.text
  local replacements = {}
  local unequal
  for key, group in pairs(groups) do
    if #group.stored > 0 and #group.stored == #group.live then
      PairGroup(text, group.stored, group.live, replacements)
    elseif #group.stored > 0 and #group.live > 0 then
      unequal = unequal or {}
      unequal[key] = true
    end
  end
  if unequal then
    PairBySentence(stored, live, storedUsed, liveUsed, anchorOf, useGrey, unequal, replacements)
  end
  if #replacements == 0 then
    return text
  end
  table.sort(replacements, function(a, b) return a.s > b.s end)
  for _, r in ipairs(replacements) do
    text = text:sub(1, r.s - 1) .. r.text .. text:sub(r.e + 1)
  end
  return text
end

-- Returns the translated lines (plain text, spell compression already expanded) with the numbers of the
-- tooltip copied in; kind is "spell" or "item". Lines that cannot be paired safely come back unchanged.
function WoWeuCN_Tooltips_LiveNumbers(tooltip, lines, kind)
  if WoWeuCN_Tooltips_N_PS == nil or WoWeuCN_Tooltips_N_PS["livenumbers"] == "0" then
    return lines
  end
  if tooltip == nil or lines == nil or #lines == 0 then
    return lines
  end

  local stored, any = {}, false
  for i, text in ipairs(lines) do
    stored[i] = StoredLine(text, kind)
    if #stored[i].tokens > 0 then
      any = true
    end
  end
  if not any then
    return lines
  end

  local group, decimal = ClientSeparators()
  local live = ReadTooltip(tooltip, group, decimal)
  if live == nil or #live == 0 then
    return lines
  end

  local pairs_, infos = Align(stored, live)
  local result = {}
  for i, text in ipairs(lines) do
    local j = pairs_[i]
    if j and Confident(stored[i], live[j], infos[i]) then
      result[i] = Substitute(stored[i], live[j])
    else
      result[i] = text
    end
  end
  return result
end
