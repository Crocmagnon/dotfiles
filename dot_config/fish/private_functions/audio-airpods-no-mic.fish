function audio-airpods-no-mic
pacmd set-card-profile bluez_card.10_CF_0F_EF_EE_EF a2dp_sink
pacmd set-default-source alsa_input.pci-0000_00_1f.3.analog-stereo
pacmd set-default-sink bluez_sink.10_CF_0F_EF_EE_EF.a2dp_sink
end
