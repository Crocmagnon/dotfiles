function audio-plt-no-mic
pacmd set-card-profile bluez_card.F4_B6_88_D4_1E_5D a2dp_sink
pacmd set-default-source alsa_input.pci-0000_00_1f.3.analog-stereo
pacmd set-default-sink bluez_sink.F4_B6_88_D4_1E_5D.a2dp_sink
end
