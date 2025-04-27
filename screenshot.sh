#!/bin/bash

set -e
set -o pipefail

usage() {
  echo "Error: $*" >&2
  echo "Usage: $0 <url> [-w width] [-h height] [-p output]" >&2
  echo "  example: $0 https://sitemaps.org -w 1280 -h 630 -p /var/www/sitemaps.org/public/opengraph/" >&2
  exit 1
}

take_screenshot() {
  url=$1

  # File name ("/" renamed to "index")
  name="$(echo $url | sed 's@https\?://[^/]\+/@@')"
  if [ "$(basename "$name")" == "" ]; then
    name="$(dirname "$name" | sed -e 's@^/@@' -e 's@^\.$@@')index.png"
  else
    name="$name.png"
  fi

  # Create target directory structure based on the URL path
  mkdir -p "$(dirname "$name")"

  # Take screenshot
  echo -n "$url => "
  curl -s \
    "http://127.0.0.1:8020/screenshot?blockAds=true&timeout=20000" \
    -H 'Cache-Control: no-cache'\
    -H 'Content-Type: application/json' \
    -d '{
    "url": "'"$url"'",
    "options": {
      "fullPage": true,
      "type": "png"
    },
    "viewport": {
      "width": '$w',
      "height": '$h'
    }
  }' \
    --output "$name"

  # Crop screenshot and make sure it is a valid image
  $magick "$name" -crop ${w}x${h}+0+0 "$name"
  file "$name"
  file "$name" | grep -q "PNG image data, $w x $h, 8-bit/color RGB, non-interlaced"
}

try_again() {
  url=$1
  echo "Failed to take screenshot for: $url, try again"
  sleep 2
  take_screenshot "$url" || echo "Failed to take screenshot for $url twice, give up" >&2
}

list_urls() {
  curl -s "$base/sitemap.xml" \
    | grep -oP "<loc>\Khttps?://[^/]+/[^<]*"
}

# -----------------------------------------------------------------------------

wd="$(dirname "$(realpath "$0")")"
magick=$(which magick >/dev/null && echo magick || echo convert)

while getopts "w:h:p:" o; do
  case "${o}" in
    w) w=$OPTARG;;
    h) h=$OPTARG;;
    p) data=$OPTARG;;
    *) usage "Invalid option '$o'"
  esac
done
shift $((OPTIND-1))

# CLI args
base=$1
if [ "$base" == "" ]; then
  usage "Missing base URL"
fi
base="$(echo "$base" | sed 's@/$@@')"
w=${w:-1280}
h=${h:-630}
data=${data:-"$wd/data"}

# Start operations
cd "$wd"
docker compose pull
docker compose up -d

mkdir -p "$data"
cd "$data"
list_urls \
  | while read url; do
  take_screenshot $url || try_again $url
  done

