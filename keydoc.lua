-- Document key bindings

local awful     = require("awful")
local table     = table
local ipairs    = ipairs
local pairs     = pairs
local math      = math
local string    = string
local type      = type
local modkey    = "Mod4"
local beautiful = require("beautiful")
local naughty   = require("naughty")
local capi      = {
   root = root,
   client = client
}

module("keydoc")

local doc = { }
local currentgroup = "Misc"
local orig = awful.key.new

-- Replacement for awful.key.new
local function new(mod, key, press, release, docstring, hide)
   -- Usually, there is no use of release, let's just use it for doc
   -- if it's a string.
   if press and release and docstring and type(release) == "string" then
      hide = docstring
      docstring = release
      release = nil
   elseif press and release and not docstring and type(release) == "string" then
      docstring = release
      release = nil
   end
   hide = hide or false
   local k = orig(mod, key, press, release)
   -- Remember documentation for this key (we take the first one)
   if k and #k > 0 and docstring and hide == false then
      doc[k[1]] = { help = docstring,
		    group = currentgroup }
   end

   return k
end
awful.key.new = new		-- monkey patch

-- Turn a key to a string
local function key2str(key)
   local sym = key.key or key.keysym
   local translate = {
      ["#14"] = "#",
      [" "] = "Space",
   }
   sym = translate[sym] or sym
   if not key.modifiers or #key.modifiers == 0 then return sym end
   local result = ""
   local translate = {
      [modkey] = "⊞",
      Shift    = "⇧",
      Control  = "Ctrl",
   }
   for _, mod in pairs(key.modifiers) do
      mod = translate[mod] or mod
      result = result .. mod .. " + "
   end
   if sym == '1' or sym == '2' or sym == '3' or sym == '4' or sym == '5' or sym == '6' or sym == '7' or sym == '8' or sym == '9' or sym == '0' then
      sym = "number"
   end
   if sym == 'equal' or sym == 'plus' then
       sym = "plus/equal"
   end
   return result .. sym
end

-- Unicode "aware" length function (well, UTF8 aware)
-- See: http://lua-users.org/wiki/LuaUnicode
local function unilen(str)
   local _, count = string.gsub(str, "[^\128-\193]", "")
   return count
end

-- Start a new group
function group(name)
   currentgroup = name
   return {}
end

local function markup(keys)
   local result = {}

   -- Compute longest key combination
   local longest = 0
   for _, key in ipairs(keys) do
      if doc[key] then
	 longest = math.max(longest, unilen(key2str(key)))
      end
   end

   local curgroup = nil
   for _, key in ipairs(keys) do
      if doc[key] then
	 local help, group = doc[key].help, doc[key].group
	 local skey = key2str(key)
	 result[group] = (result[group] or "") ..
	    '<span font="Monospace 10" color="' .. beautiful.fg_focus .. '"> ' ..
	    string.format("%" .. (longest - unilen(skey)) .. "s  ", "") .. skey ..
	    '</span>  <span color="' .. beautiful.fg_normal .. '">' .. -- if
   -- beautiful.fg_widget_value is not specified in your theme.lua, try changing it to "#E0E0D1"
   -- and include the quotes, because it is a string.
	    help .. '</span>\n'
      end
   end

   return result
end

-- Customize version of standard function pairs that sort keys
-- (from Michal Kottman on Stackoverflow)
function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys 
  if order then
    table.sort(keys, function(a,b) return order(t, a, b) end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

-- Display help in a naughty notification
local nid = nil
function display()
   local strings = markup(awful.util.table.join(
      capi.root.keys(),
      capi.client.focus and capi.client.focus:keys() or {}))

   local result = ""
   for group, res in spairs(strings) do
      if #result > 0 then result = result .. "\n" end
      result = result ..
	 '<span weight="bold" color="' .. beautiful.fg_important .. '">' ..
	 group .. "</span>\n" .. res
   end
   nid = naughty.notify({ text = result,
			  replaces_id = nid,
			  timeout = 30 }).id
end 
