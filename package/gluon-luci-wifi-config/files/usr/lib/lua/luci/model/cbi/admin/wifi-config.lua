local uci = luci.model.uci.cursor()
local fs = require 'nixio.fs'
local iwinfo = require 'iwinfo'


local function find_phy_by_path(path)
  for phy in fs.glob("/sys/devices/" .. path .. "/ieee80211/phy*") do
    return phy:match("([^/]+)$")
  end
end

local function find_phy_by_macaddr(macaddr)
  local addr = macaddr:lower()
  for file in fs.glob("/sys/class/ieee80211/*/macaddress") do
    if luci.util.trim(fs.readfile(file)) == addr then
      return file:match("([^/]+)/macaddress$")
    end
  end
end

local function txpower_list(phy)
  local list = iwinfo.nl80211.txpwrlist(phy) or { }
  local off  = tonumber(iwinfo.nl80211.txpower_offset(phy)) or 0
  local new  = { }
  local prev = -1
  local _, val
  for _, val in ipairs(list) do
    local dbm = val.dbm + off
    local mw  = math.floor(10 ^ (dbm / 10))
    if mw ~= prev then
      prev = mw
      table.insert(new, {
                     display_dbm = dbm,
                     display_mw  = mw,
                     driver_dbm  = val.dbm,
      })
    end
  end
  return new
end


local f = SimpleForm("wifi", translate("WLAN"))
f.template = "admin/expertmode"

local s = f:section(SimpleSection, nil, translate(
                "You can enable or disable your node's client and mesh network "
                  .. "SSIDs here. Please don't disable the mesh network without "
                  .. "a good reason, so other nodes can mesh with yours.<br /><br />"
                  .. "It is also possible to configure the WLAN adapters transmission power "
                  .. "here. Please note that the transmission power values include the antenna gain "
                  .. "where available, but there are many devices for which the gain is unavailable or inaccurate."
))

local radios = {}
local macfilter = 'disable'
local maclist = ''

-- look for wifi interfaces and add them to the array
uci:foreach('wireless', 'wifi-device',
  function(s)
    table.insert(radios, s['.name'])
  end
)

-- add a client and mesh checkbox for each interface
for _, radio in ipairs(radios) do
  local config = uci:get_all('wireless', radio)
  local p

  if config.hwmode == '11g' or config.hwmode == '11ng' then
    p = f:section(SimpleSection, translate("2.4GHz WLAN"))
  elseif config.hwmode == '11a' or config.hwmode == '11na' then
    p = f:section(SimpleSection, translate("5GHz WLAN"))
  end

  if p then
    local o

    --box for the client network
    o = p:option(Flag, radio .. '_client_enabled', translate("Enable client network"))
    o.default = uci:get_bool('wireless', 'client_' .. radio, "disabled") and o.disabled or o.enabled
    o.rmempty = false

    --box for additional client network only if enabled
    if uci:get('wireless', 'adclient_' .. radio) then
      o = p:option(Flag, radio .. '_adclient_enabled', translate("Enable additional client network"))
      o.default = uci:get_bool('wireless', 'adclient_' .. radio, "disabled") and o.disabled or o.enabled
      o.rmempty = false

      --SSID of the client network
      o = p:option(Value, radio .. '_adclient_ssid', translate("SSID of additional client network"))
      o.default = uci:get('wireless', 'adclient_' .. radio, 'ssid')
      o:depends(radio .. '_adclient_enabled', "1")
      o.rmempty = false
      o.datatype = "string"
      o.description = translate("e.g. freifunk.net")
    end

    --box for the mesh network
    o = p:option(Flag, radio .. '_mesh_enabled', translate("Enable mesh network"))
    o.default = uci:get_bool('wireless', 'mesh_' .. radio, "disabled") and o.disabled or o.enabled
    o.rmempty = false

    --box for the STA mesh network
    if uci:get('wireless', 'stamesh_' .. radio) then
      o = p:option(Flag, radio .. '_stamesh_enabled', translate("Enable STA mesh network"))
      o.default = uci:get_bool('wireless', 'stamesh_' .. radio, "disabled") and o.disabled or o.enabled
      o.rmempty = false
    end

    local phy

    if config.path then
      phy = find_phy_by_path(config.path)
    elseif config.macaddr then
      phy = find_phy_by_path(config.macaddr)
    end

    if phy then
      local txpowers = txpower_list(phy)

      if #txpowers > 1 then
        local tp = p:option(ListValue, radio .. '_txpower', translate("Transmission power"))
        tp.rmempty = true
        tp.default = uci:get('wireless', radio, 'txpower') or 'default'

        tp:value('default', translate("(default)"))

        table.sort(txpowers, function(a, b) return a.driver_dbm > b.driver_dbm end)

        for _, entry in ipairs(txpowers) do
          tp:value(entry.driver_dbm, "%i dBm (%i mW)" % {entry.display_dbm, entry.display_mw})
        end
      end
    end

    macfilter = uci:get('wireless', 'client_' .. radio, "macfilter")
    maclist = uci:get('wireless', 'client_' .. radio, "maclist")
  end

end

local d = f:section(SimpleSection, nil, translate(
                    "You can set up a list of clients which are not allowed to connect to "
                 .. "your access point to use one its client networks. Please only use this "
                 .. "feature to limit usage of your HotSpot if you absolutely understand "
                 .. "what it does!"
))

o = d:option(Flag, '_filter_macs', translate("Disallow connection for specific clients"))
o.default = macfilter == "deny" and o.enabled or o.disabled
o.rmempty = false

o = d:option(Value, '_filter_list', translate("MAC addresses to disallow connection"))
o.default = maclist
o:depends('_filter_macs', "1")
o.rmempty = false
o.datatype = "string"
o.description = translate("list of MAC-addresses separated by space")

--when the save-button is pushed
function f.handle(self, state, data)
  if state == FORM_VALID then

    for _, radio in ipairs(radios) do

      local clientdisabled = 0
      if data[radio .. '_client_enabled'] == '0' then
        clientdisabled = 1
      end
      uci:set('wireless', 'client_' .. radio, "disabled", clientdisabled)

      if data['_filter_macs'] == '1' then
        uci:set('wireless', 'client_' .. radio, "macfilter", "deny")
        uci:set('wireless', 'client_' .. radio, "maclist", data['_filter_list'])
      else
        uci:set('wireless', 'client_' .. radio, "macfilter", "disable")
      end

      if uci:get('wireless', 'adclient_' .. radio) then
        if data[radio .. '_adclient_enabled'] == '0' then
          uci:set('wireless', 'adclient_' .. radio, "disabled", 1)
        else
          uci:set('wireless', 'adclient_' .. radio, "disabled", 0)
          uci:set('wireless', 'adclient_' .. radio, "ssid", data[radio .. '_adclient_ssid'])
        end

        if data['_filter_macs'] == '1' then
          uci:set('wireless', 'adclient_' .. radio, "macfilter", "deny")
          uci:set('wireless', 'adclient_' .. radio, "maclist", data['_filter_list'])
        else
          uci:set('wireless', 'adclient_' .. radio, "macfilter", "disable")
        end
      end

      local meshdisabled = 0
      if data[radio .. '_mesh_enabled'] == '0' then
        meshdisabled = 1
      end
      uci:set('wireless', 'mesh_' .. radio, "disabled", meshdisabled)

      if uci:get('wireless', 'stamesh_' .. radio) then
        local stameshdisabled = 0
        if data[radio .. '_stamesh_enabled'] == '0' then
          stameshdisabled = 1
        end
        uci:set('wireless', 'stamesh_' .. radio, "disabled", stameshdisabled)
      end

      if data[radio .. '_txpower'] then
        if data[radio .. '_txpower'] == 'default' then
          uci:delete('wireless', radio, 'txpower')
        else
          uci:set('wireless', radio, 'txpower', data[radio .. '_txpower'])
        end
      end

    end

    uci:save('wireless')
    uci:commit('wireless')
  end
end

return f
