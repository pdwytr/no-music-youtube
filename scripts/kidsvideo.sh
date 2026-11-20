#!/usr/bin/env bash
# kidsvideo.sh - download a YouTube video, optionally strip the music, and
# add it to a Jellyfin "Home Videos" library.
#
# Usage:
#   kidsvideo.sh [--no-music] [--lib DIR] URL
#
# Environment (only needed to trigger a Jellyfin rescan; Jellyfin also
# picks up new files on its own schedule):
#   JELLYFIN_URL       default http://localhost:8096
#   JELLYFIN_USER      admin username
#   JELLYFIN_PASSWORD  admin password
#   DEMUCS_VENV        default $HOME/.kidsvideo/demucs-env
#   KIDS_LIBRARY       default $HOME/Movies/Kids
#
# Only download videos you have the right to keep for personal use.
set -euo pipefail

NO_MUSIC=0
LIB="${KIDS_LIBRARY:-$HOME/Movies/Kids}"
URL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --no-music) NO_MUSIC=1 ;;
    --lib) LIB="$2"; shift ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) URL="$1" ;;
  esac
  shift
done

[ -n "$URL" ] || { echo "usage: $0 [--no-music] [--lib DIR] URL" >&2; exit 2; }
for c in yt-dlp ffmpeg ffprobe curl python3; do
  command -v "$c" >/dev/null || { echo "missing dependency: $c (brew install yt-dlp ffmpeg)" >&2; exit 1; }
done

mkdir -p "$LIB"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Downloading"
# --no-playlist: a link with &list= must not pull a whole playlist.
# H.264 + AAC in MP4 so an iPad plays it without transcoding.
yt-dlp --no-playlist \
  -f "bv*[vcodec^=avc1][height<=1080]+ba[ext=m4a]/b[ext=mp4]/b" \
  --merge-output-format mp4 \
  -o "$WORK/%(title)s [%(id)s].%(ext)s" "$URL"

SRC="$(ls "$WORK"/*.mp4 | head -n1)"
BASE="$(basename "$SRC")"

if [ "$NO_MUSIC" = 1 ]; then
  VENV="${DEMUCS_VENV:-$HOME/.kidsvideo/demucs-env}"
  if [ ! -x "$VENV/bin/python" ]; then
    echo "==> Installing Demucs into $VENV (one-time, large download)"
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install -q demucs torch torchaudio soundfile
  fi
  echo "==> Removing music (CPU, roughly 0.4x realtime on an Apple-silicon Mac)"
  ffmpeg -y -v error -i "$SRC" -vn -ac 2 -ar 44100 "$WORK/audio.wav"
  # -d cpu: the MPS (Apple GPU) backend crashes on this model.
  "$VENV/bin/python" -m demucs --two-stems=vocals -n htdemucs -d cpu \
    "$WORK/audio.wav" -o "$WORK/out"
  OUT="$WORK/final.mp4"
  ffmpeg -y -v error -i "$SRC" -i "$WORK/out/htdemucs/audio/vocals.wav" \
    -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -movflags +faststart "$OUT"
  DEST="$LIB/${BASE%.mp4} - No Music.mp4"
  mv "$OUT" "$DEST"
else
  DEST="$LIB/$BASE"
  mv "$SRC" "$DEST"
fi
echo "==> Saved: $DEST"

if [ -n "${JELLYFIN_USER:-}" ] && [ -n "${JELLYFIN_PASSWORD:-}" ]; then
  JF="${JELLYFIN_URL:-http://localhost:8096}"
  AUTH='Authorization: MediaBrowser Client="kidsvideo", Device="script", DeviceId="kidsvideo1", Version="1.0"'
  BODY="$(python3 -c 'import json,os;print(json.dumps({"Username":os.environ["JELLYFIN_USER"],"Pw":os.environ["JELLYFIN_PASSWORD"]}))')"
  TOKEN="$(curl -fsS -H "$AUTH" -H 'Content-Type: application/json' \
    -X POST "$JF/Users/AuthenticateByName" -d "$BODY" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["AccessToken"])')"
  curl -fsS -X POST -H "Authorization: MediaBrowser Token=\"$TOKEN\"" "$JF/Library/Refresh"
  echo "==> Jellyfin rescan started"
else
  echo "==> JELLYFIN_USER/JELLYFIN_PASSWORD not set; skipping rescan"
fi
