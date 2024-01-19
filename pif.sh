#!/bin/bash

get_value() {
  value="$(grep "$1" "${fields_file}" | sed 's/.*value="\([^"]*\)".*/\1/' | sed 's/" \/>//')"
  echo "${value:-null}"
}

# Create the json file
create_json() {
  cat <<EOF >"${service_file}"
{
  "PRODUCT": "$(get_value PRODUCT)",
  "DEVICE": "$(get_value DEVICE)",
  "MANUFACTURER": "$(get_value MANUFACTURER)",
  "BRAND": "$(get_value BRAND)",
  "MODEL": "$(get_value MODEL)",
  "FINGERPRINT": "$(get_value FINGERPRINT)",
  "SECURITY_PATCH": "$(get_value SECURITY_PATCH)",
  "FIRST_API_LEVEL": "$(get_value FIRST_API_LEVEL)"
}
EOF
}

# RSS Feed URL
url="https://sourceforge.net/projects/xiaomi-eu-multilang-miui-roms/rss?path=/xiaomi.eu/Xiaomi.eu-app"

tmp_dir="$(mktemp -d)"
apk_file="${tmp_dir}/xiaomi.apk"
extracted_apk="${tmp_dir}/Extractedapk"
service_file="pif.json"
fields_file="${extracted_apk}/res/xml/inject_fields.xml"

trap 'rm -rf "${tmp_dir}"' EXIT

# Fetch RSS feed and extract the last link
lastLink=$(curl --silent --show-error "${url}" | grep -oP '<link>\K[^<]+' | head -2 | tail -1)

# Output the last link
curl --silent --show-error --location --output "${apk_file}" "${lastLink}"

apktool d "${apk_file}" -o "${extracted_apk}" -f

create_json

cat "${service_file}"
