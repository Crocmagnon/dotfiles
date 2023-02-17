function audio-plt-conf
pacmd set-card-profile bluez_card.F4_B6_88_D4_1E_5D handsfree_head_unit
pacmd set-default-source bluez_source.F4_B6_88_D4_1E_5D.handsfree_head_unit
pacmd set-default-sink bluez_sink.F4_B6_88_D4_1E_5D.handsfree_head_unit
end
