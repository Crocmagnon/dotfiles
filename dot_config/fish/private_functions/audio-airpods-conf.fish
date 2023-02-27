function audio-airpods-conf
pacmd set-card-profile bluez_card.10_CF_0F_EF_EE_EF handsfree_head_unit
pacmd set-default-source bluez_source.10_CF_0F_EF_EE_EF.handsfree_head_unit
pacmd set-default-sink bluez_sink.10_CF_0F_EF_EE_EF.handsfree_head_unit
pacmd set-source-volume bluez_source.10_CF_0F_EF_EE_EF.handsfree_head_unit 65535
end
