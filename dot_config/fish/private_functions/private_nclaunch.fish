# Defined interactively
function nclaunch
    echo "checking for nextcloud"
    if [ (ps aux | grep /Applications/nextcloud.app/Contents/MacOS/nextcloud | wc -l) -eq "1" ]
        echo "Launching Nextcloud"
        open -a Nextcloud
    end
end
