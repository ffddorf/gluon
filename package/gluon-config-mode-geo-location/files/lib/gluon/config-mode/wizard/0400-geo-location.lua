local cbi = require "luci.cbi"
local i18n = require "luci.i18n"
local uci = luci.model.uci.cursor()

local M = {}

function M.section(form)
  local s = form:section(cbi.SimpleSection, nil, i18n.translate(
    'If you want information for your node to be displayed on the map, '
      .. 'you can enter its coordinates here. Specifying the altitude '
      .. 'is optional and should only be done if a proper value is known. '
      .. 'It is also optional to display a count of connected clients on '
      .. 'the map.'))


  local o

  o = s:option(cbi.Flag, "_location", i18n.translate("Show node on the map"))
  o.default = uci:get_first("gluon-node-info", "location", "share_location", o.disabled)
  o.rmempty = false

  o = s:option(cbi.Value, "_latitude", i18n.translate("Latitude"))
  o.default = uci:get_first("gluon-node-info", "location", "latitude")
  o:depends("_location", "1")
  o.rmempty = false
  o.datatype = "float"
  o.description = i18n.translatef("e.g. %s", "52.623")

  o = s:option(cbi.Value, "_longitude", i18n.translate("Longitude"))
  o.default = uci:get_first("gluon-node-info", "location", "longitude")
  o:depends("_location", "1")
  o.rmempty = false
  o.datatype = "float"
  o.description = i18n.translatef("e.g. %s", "10.076")

  o = s:option(cbi.Value, "_altitude", i18n.translate("Altitude"))
  o.default = uci:get_first("gluon-node-info", "location", "altitude")
  o:depends("_location", "1")
  o.rmempty = true
  o.datatype = "float"
  o.description = i18n.translatef("e.g. %s", "40.00")

  o = s:option(cbi.Flag, "_show_counts", i18n.translate("Show client count on the map"))
  o.default = uci:get_first("gluon-node-info", "system", "show_counts", o.enabled)
  o.rmempty = false

end

function M.handle(data)
  local sname = uci:get_first("gluon-node-info", "location")

  uci:set("gluon-node-info", sname, "share_location", data._location)
  if data._location and data._latitude ~= nil and data._longitude ~= nil then
    uci:set("gluon-node-info", sname, "latitude", data._latitude)
    uci:set("gluon-node-info", sname, "longitude", data._longitude)
    if data._altitude ~= nil then
      uci:set("gluon-node-info", sname, "altitude", data._altitude)
    else
      uci:delete("gluon-node-info", sname, "altitude")
    end
  end

  sname = uci:get_first("gluon-node-info", "system")
  uci:set("gluon-node-info", sname, "show_counts", data._show_counts)

  uci:save("gluon-node-info")
  uci:commit("gluon-node-info")
end

return M
