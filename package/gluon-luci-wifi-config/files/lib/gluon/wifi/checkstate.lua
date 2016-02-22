#!/usr/bin/lua

uci = require('luci.model.uci').cursor()

if not uci:get_bool('gluon-timed-wifi', 'default', "enabled") then
  return
end


function match(expr, test)
  for elem in expr:gmatch("[^,]+") do
    local base
    local rep

    base, rep = elem:match("^([^/]+)/([0-9]+)$")
    if rep then
      elem = base
      rep = tonumber(rep, 10)
      if rep == 0 then
        rep = nil
      end
    end

    if elem == "*" and ( not rep or ( test % rep ) == 0 ) then
      return true
    end

    local low
    local high

    low, high = elem:match("^([0-9]+)-([0-9]+)$")
    if low then
      low = tonumber(low, 10)
      if test >= low and test <= tonumber(high, 10) and ( not rep or ( ( test - low ) % rep ) == 0 ) then
        return true
      end
    end

    elem = elem:match("^([0-9]+)$")
    if elem and test == tonumber(elem, 10) then
      return true
    end
  end

  return false
end

function evaluate(crons, curtime)
  for _, cron in ipairs(crons) do
    local matches = {curtime.min, curtime.hour, curtime.day, curtime.month, curtime.wday}

    local matched = true
    for expr in cron:gmatch("%S+") do
      local test = table.remove(matches, 1)
      if not test then
        matched = expr
        break
      end

      matched = match(expr, test)
      if not matched then
        break
      end
    end

    if matched then
      return ( matched == "off" or matched == "false" or matched == "no" or matched == "0" )
    end
  end

  return true
end


local curtime = os.date("*t")
local defaultcron = uci:get_list('gluon-timed-wifi', 'default', "cron")
local defaultstate = evaluate(defaultcron, curtime)

local changed = false
uci:foreach('wireless', 'wifi-device',
  function(s)
    local ifs = {'client_' .. s['.name'], 'adclient_' .. s['.name']}
    for _, name in ipairs(ifs) do
      if not uci:get('wireless', name, "ssid") then
        return
      end

      cronstate = defaultstate
      if uci:get('gluon-timed-wifi', name) then
        cronstate = evaluate(uci:get_list('gluon-timed-wifi', name, "cron"), curtime)
      end

      if uci:get_bool('wireless', name, "disabled") ~= cronstate then
        uci:set('wireless', name, "disabled", cronstate and '1' or '0')
        changed = true
      end
    end
  end
)

if changed then
  uci:save('wireless')
  uci:commit('wireless')

  os.execute('wifi reload')
end
