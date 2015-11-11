need_string('regdom')

for _, config in ipairs({'wifi24', 'wifi5'}) do
   need_string(config .. '.ssid')
   need_number(config .. '.channel')
   need_string(config .. '.htmode')
   need_string(config .. '.mesh_ssid')
   need_string_match(config .. '.mesh_bssid', '^%x[02468aAcCeE]:%x%x:%x%x:%x%x:%x%x:%x%x$')
   need_number(config .. '.mesh_mcast_rate')
   need_number(config .. '.mesh_vlan', false)
   need_boolean(config .. '.client_disabled', false)
   need_boolean(config .. '.mesh_disabled', false)
   if need_string(config .. '.mesh_enc', false) then
      need_string(config .. '.mesh_psk')
   end

   need_boolean(config .. '.stamesh_disabled', false)
   if need_string(config .. '.stamesh_ssid', false) then
      if not need_string(config .. '.stamesh_enc', false) then
         need_string(config .. '.mesh_enc')
      end
      if not need_string(config .. '.stamesh_psk', false) then
         need_string(config .. '.mesh_psk')
      end
   end
end

need_boolean('mesh_on_wan', false)
need_boolean('mesh_on_lan', false)
