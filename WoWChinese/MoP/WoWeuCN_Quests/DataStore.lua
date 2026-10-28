local ADDON, T = ...
local floor, char, byte, gsub, gmatch, sub, match = math.floor, string.char, string.byte, string.gsub, string.gmatch, string.sub, string.match
local tostring, tonumber, rawset, pairs, ipairs, setmetatable = tostring, tonumber, rawset, pairs, ipairs, setmetatable
local M = 4294967296
local SIG = {}
do
  local n = 0
  for b = 32, 126 do
    if b ~= 34 and b ~= 92 then SIG[n] = char(b); n = n + 1 end
  end
  for b = 128, 255 do SIG[n] = char(b); n = n + 1 end
end

local function lcg(x) return (69069 * x + 1) % M end

local function rng(seed)
  local x = seed % M
  return function(n) x = lcg(x); return floor(x / 65536) % n end
end

local function shuffle(list, count, r)
  for i = count - 1, 1, -1 do
    local j = r(i + 1)
    list[i], list[j] = list[j], list[i]
  end
  return list
end

local function perm(count, seed)
  local p = {}
  for i = 0, count - 1 do p[i] = i end
  return shuffle(p, count, rng(seed))
end

local K = 0xEA6E * 65536 + 0xF372

local function fileseed(salt)
  local h = 7
  for i = 1, #ADDON do h = (h * 31 + byte(ADDON, i)) % M end
  local x = lcg(salt % M)
  x = lcg((x + K) % M)
  return lcg((x + h) % M)
end

local stores = {}

local function prepare(s)
  local seed = fileseed(s.salt)
  local A = {}
  for i = 0, 220 do A[i] = SIG[i] end
  shuffle(A, 221, rng(seed))
  local inv = {}
  for i = 0, 220 do inv[A[i]] = i end
  local r = rng(seed + 2654435769)
  local hdr, h, c = s.hdr, {}, 17
  for i = 1, 267 do
    local a, b = inv[sub(hdr, 2 * i - 1, 2 * i - 1)] or 0, inv[sub(hdr, 2 * i, 2 * i)] or 16
    local v = (a * 16 + b - 16 - r(256)) % 256
    h[i] = v
    if i <= 265 then c = (c * 31 + v) % 65536 end
  end
  s.ready = true
  if h[1] ~= 1 or #hdr ~= 534 or h[266] * 256 + h[267] ~= c then
    s.bad = true
    return
  end
  s.bs = ((h[2] * 256 + h[3]) * 256 + h[4]) * 256 + h[5]
  s.s1, s.s2, s.s3 = char(h[6]), char(h[7]), char(h[8])
  s.ne = h[9]
  local tinv = {}
  for i = 0, 255 do tinv[i] = char(h[10 + i]) end
  s.tinv, s.A, s.E, s.seed = tinv, A, A[220], seed
  local ipp, pp = {}, perm(220, seed + 523456789)
  for i = 0, 219 do ipp[pp[i]] = i end
  local by = {}
  for _, ch in ipairs(s.chunks) do
    local b = 0
    for i = 1, 5 do
      b = b * 220 + ((ipp[inv[sub(ch, i, i)] or 0] or 0) - 37 * (i - 1)) % 220
    end
    by[b] = ch
  end
  s.by, s.chunks, s.cache, s.n = by, nil, {}, 0
  local e = s.E
  s.pat = s.ne > 0 and ((match(e, "%w") and e or ("%" .. e)) .. "?.") or "."
end

local function decode(s, b)
  local ch = s.by[b]
  if not ch then return nil end
  local A, tinv, map = s.A, s.tinv, {}
  local p = perm(220, lcg(lcg((s.seed + b * 40503 + 1013904223) % M)))
  for i = 0, 219 do map[A[p[i]]] = tinv[i] end
  if s.ne > 0 then
    local e = s.E
    for j = 0, s.ne - 1 do map[e .. A[p[j]]] = tinv[220 + j] end
  end
  local plain = gsub(sub(ch, 6), s.pat, map)
  local t, s1, s2 = {}, s.s1, s.s2
  for k, v in gmatch(plain, "([^" .. s2 .. "]*)" .. s2 .. "([^" .. s1 .. "]*)" .. s1) do t[k] = v end
  return t
end

local function G(kind, key)
  local s = stores[kind]
  if not s then return nil end
  if not s.ready then prepare(s) end
  if s.bad then return nil end
  local ks = tostring(key)
  local n = tonumber(match(ks, "(%d+)$"))
  if not n then return nil end
  local b = floor(n / s.bs)
  local t = s.cache[b]
  if not t then
    t = decode(s, b)
    if not t then return nil end
    if s.n >= 40 then s.cache, s.n = {}, 0 end
    s.cache[b], s.n = t, s.n + 1
  end
  return t[ks]
end

function T.S(kind, salt, hdr, chunks)
  stores[kind] = { salt = salt, hdr = hdr, chunks = chunks }
end

T.G = G

function T.R(kind, fields)
  local n = 0
  return setmetatable({}, { __index = function(t, k)
    local raw = G(kind, k)
    if raw == nil then return nil end
    local s3, rec, i = stores[kind].s3, {}, 1
    for part in gmatch(raw .. s3, "([^" .. s3 .. "]*)" .. s3) do
      rec[fields[i] or i] = part
      i = i + 1
    end
    if n >= 1024 then
      for key in pairs(t) do t[key] = nil end
      n = 0
    end
    rawset(t, k, rec)
    n = n + 1
    return rec
  end })
end

function T.V(kind)
  return setmetatable({}, { __index = function(_, k) return G(kind, k) end })
end
