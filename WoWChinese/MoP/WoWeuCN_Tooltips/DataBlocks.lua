-- Addon: WoWeuCN
-- Author: qqytqqyt
--
-- The translation data, kept as plain text in blocks.
--
-- A data file opens a store and hands over its blocks:
--   local B = Data.Blocks("Quest", 80, "Title", "Objectives")   kind, ids per block, field names
--   B(0, [=[ ... ]=])                                           block 0 holds the ids 0 to 79
-- A block is plain text, one line per id: the id, a tab, the text. A store with field names has
-- the fields after the id, a tab between them. Inside a field \\ \n \r \t stand for a backslash,
-- a line feed, a carriage return and a tab, and \s for a space at the very end of a line; empty
-- fields at the end of a line are left out.
--
-- A block stays one string until one of its ids is asked for. Its lines are then read into a
-- table, which is kept for a while. So the data takes about the size of its files in memory,
-- and nothing is read at login.

local _, Data = ...

local floor, find, gmatch, gsub, match = math.floor, string.find, string.gmatch, string.gsub, string.match
local tostring, tonumber, setmetatable, rawset, pairs = tostring, tonumber, setmetatable, rawset, pairs

-- read blocks kept per store, and records kept per record table, before they are dropped again
local KEPT_BLOCKS = 32
local KEPT_RECORDS = 1024

local stores = {}
local escapes = { ["\\"] = "\\", n = "\n", r = "\r", t = "\t", s = " " }

local function Plain(text)
  if (find(text, "\\", 1, true)) then
    return (gsub(text, "\\(.)", escapes))
  end
  return text
end

-- the lines of a block: key -> the rest of its line
local function ReadBlock(text)
  local lines = {}
  for key, rest in gmatch(text, "([^\t\n]+)\t?([^\n]*)\n") do
    lines[key] = rest
  end
  return lines
end

-- the rest of the line of a key; nil when the store has nothing for it.
-- The block of a key is found by the number it ends with ("25", or the 4522 of "17x4522").
local function Line(kind, key)
  local store = stores[kind]
  if (store == nil) then
    return nil
  end

  local name = tostring(key)
  local id = tonumber(match(name, "(%d+)$"))
  if (id == nil) then
    return nil
  end

  local number = floor(id / store.size)
  local lines = store.read[number]
  if (lines == nil) then
    local text = store.blocks[number]
    if (text == nil) then
      return nil
    end
    if (store.kept >= KEPT_BLOCKS) then
      store.read, store.kept = {}, 0
    end
    lines = ReadBlock(text)
    store.read[number], store.kept = lines, store.kept + 1
  end

  return lines[name]
end

-- Opens the store of a kind; returns the function its data file hands the blocks to.
function Data.Blocks(kind, size, ...)
  local store = { size = size, fields = { ... }, blocks = {}, read = {}, kept = 0 }
  stores[kind] = store
  return function(number, text)
    store.blocks[number] = text
  end
end

-- The text of a key, in a store of one text per key.
function Data.Get(kind, key)
  local text = Line(kind, key)
  if (text == nil) then
    return nil
  end
  return Plain(text)
end

-- A table that gives the text of any key asked from it.
function Data.Values(kind)
  return setmetatable({}, { __index = function(_, key)
    return Data.Get(kind, key)
  end })
end

-- A table that gives the record of any key asked from it: a table of the store's fields by name.
function Data.Records(kind)
  local kept = 0
  return setmetatable({}, { __index = function(records, key)
    local text = Line(kind, key)
    if (text == nil) then
      return nil
    end

    local fields, record, i = stores[kind].fields, {}, 1
    for field in gmatch(text .. "\t", "([^\t]*)\t") do
      record[fields[i] or i] = Plain(field)
      i = i + 1
    end
    for left = i, #fields do
      record[fields[left]] = ""
    end

    if (kept >= KEPT_RECORDS) then
      for known in pairs(records) do
        records[known] = nil
      end
      kept = 0
    end
    rawset(records, key, record)
    kept = kept + 1
    return record
  end })
end
