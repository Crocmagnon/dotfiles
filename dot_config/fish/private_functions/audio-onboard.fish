function audio-onboard
pacmd set-default-sink "alsa_output.pci-0000_00_1f.3.analog-stereo"
pacmd set-default-source "alsa_input.pci-0000_00_1f.3.analog-stereo"
end
