# Detect busybox
busybox_paths=(
    "/data/adb/magisk/busybox"
    "/data/adb/ksu/bin/busybox"
    "/data/adb/ap/bin/busybox"
)

busybox_path=""

for path in "${busybox_paths[@]}"; do
    if [ -f "$path" ]; then
        busybox_path="$path"
        break
    fi
done

# Check playcurl if installed
if [ -e /data/adb/modules/playcurl/curl ]; then 
    echo "Playcurl is installed"; else 
    echo "Playcurl is not installed"; 
fi

# Check if the user is root
current_user=$("$busybox_path" whoami)

if [ "$current_user" != "root" ]; then
    echo "You are not the root user. This script requires root privileges."
    exit 1
fi

# Check for zygisk
if [ "$busybox_path" = "/data/adb/ap/bin/busybox" ]; then
  if [ -d "/data/adb/modules/zygisksu" ]; then
    :
  else
    echo You need zygisk!
    rm "$0"
    exit 1
  fi
fi

if [ "$busybox_path" = "/data/adb/ksu/bin/busybox" ]; then
  if [ -d "/data/adb/modules/zygisksu" ]; then
    :
  else
    echo You need zygisk!
    rm "$0"
    exit 1
  fi
fi

# Remove from denylist google play services, google service framework
magisk_package_names=("com.google.android.gms" "com.google.android.gsf" )

if [ "$busybox_path" = "/data/adb/magisk/busybox" ]; then
    for magisk_package in "${magisk_package_names[@]}"; do
        magisk --denylist rm "${magisk_package}" > /dev/null 2>/dev/null
    done
fi
echo "" 

# Delete outdated pif.json
echo "[+] Deleting old pif.json"
file_paths=(
    "/data/adb/pif.json"
    "/data/adb/pif.json.old"
    "/data/adb/modules/playintegrityfix/pif.json"
    "/data/adb/modules/playintegrityfix/custom.pif.json"
)

for file_path in "${file_paths[@]}"; do
    if [ -f "$file_path" ]; then
        rm -f "$file_path" > /dev/null
    fi
done
echo

# Disable problematic packages, miui eu, EvoX, lineage, PixelOS, autopif
apk_names=("eu.xiaomi.module.inject" "com.goolag.pif" "com.lineageos.pif" "co.aospa.android.certifiedprops.overlay")
echo "[+] Check if inject apks are present"

for apk in "${apk_names[@]}"; do
    pm uninstall "$apk" > /dev/null 2>&1
    if ! pm list packages -d | "$busybox_path" grep "$apk" > /dev/null; then
        if pm disable "$apk" > /dev/null 2>&1; then
            echo "[+] The ${apk} apk is now disabled. YOU NEED TO REBOOT OR YOU WON'T BE ABLE TO PASS DEVICE INTEGRITY!"
        fi
    fi
done
echo

# Download pif.json
echo "[+] Downloading the pif.json"
/data/adb/modules/playcurl/curl -o /data/adb/modules/playintegrityfix/pif.json https://raw.githubusercontent.com/x1337cn/AutoPIF-Next/main/pif.json
echo 

# Kill gms processes and wallet
package_names=("com.google.android.gms" "com.google.android.gms.unstable" "com.google.android.apps.walletnfcrel")

echo "[+] Killing some apps"

for package in "${package_names[@]}"; do
    pkill -f "${package}" > /dev/null
done
echo

# Clear the cache of all apps
echo "[+] Clearing cache"
pm trim-caches 999G 
echo

# Check if the pif is present
if [ -f /data/adb/pif.json ] || [ -f /data/adb/modules/playintegrityfix/custom.pif.json ]; then
    echo "[+] Pif.json downloaded successfully"
else
    echo "[+] Pif.json is not present, something went wrong."
fi

# Check if the kernel name is banned, banned kernels names from https://xdaforums.com/t/module-play-integrity-fix-safetynet-fix.4607985/post-89308909 and telegram
get_kernel_name=$(uname -r)
banned_names=("aicp" "arter97" "blu_spark" "cm" "crdroid" "cyanogenmod" "deathly" "eas" "elementalx" "elite" "franco" "lineage" "lineageos" "noble" "optimus" "slimroms" "sultan")

for keyword in "${banned_names[@]}"; do
    if echo "$get_kernel_name" | "$busybox_path" grep -iq "$keyword"; then
        echo
        echo "[-] Your kernel name \"$keyword\" is banned. If you are passing device integrity you can ignore this mesage, otherwise that's probably the cause. "
    fi
done

echo ""
echo "Remember, wallet can take up to 24 hrs to work again!"
echo ""
echo "If you receive the device is not certified message on the Play Store and you are passing device integrity, go to Settings, then Apps, find the Play Store, and tap on Uninstall Updates."

# Auto delete the script
rm "$0" > /dev/null 2>/dev/null
