# kids-video-jellyfin

Put a YouTube video on your kid's iPad through a Jellyfin server on your Mac,
optionally with the background music removed.

- `scripts/kidsvideo.sh` does the work (download, optional music removal, rescan).
- `AGENTS.md` is the spec for AI agents that run this for you.

## Setup (once, ~15 min)
```sh
brew install --cask jellyfin
brew install yt-dlp ffmpeg
open -a Jellyfin
```
1. Open http://localhost:8096 and finish the wizard (admin account).
2. Add a library: type **Home Videos**, folder `~/Movies/Kids`.
3. On the iPad install the free **Jellyfin** app and connect to
   `http://<your-mac-ip>:8096` (`ipconfig getifaddr en0`). Same Wi-Fi, VPN off.
4. Make a separate Jellyfin user per child with a parental rating limit.

## Use
```sh
export JELLYFIN_USER=admin JELLYFIN_PASSWORD='...'   # optional, for auto-rescan
scripts/kidsvideo.sh "https://www.youtube.com/watch?v=..."
scripts/kidsvideo.sh --no-music "https://www.youtube.com/watch?v=..."
```

## Music removal: what to expect
Uses [Demucs](https://github.com/facebookresearch/demucs) to keep only the
voice track. It runs on CPU (the Apple GPU backend crashes). On one
Apple-silicon Mac it ran at about 0.4x realtime (54 min video, about 21 min).
Results are not perfect: sound effects and sung parts can disappear or sound
muddy. Listen before you delete the original.

## Status
Developed on one Mac (macOS 15, Apple silicon). The script was run end to end
with `--no-music` on a 19-second public video: it downloaded, removed the
music, and produced an H.264 + AAC MP4 of the same length. Not tested through
the script: the Jellyfin rescan step (the same API calls were run by hand and
worked), plain mode without `--no-music`, and Intel Macs or Linux.
Issues and PRs welcome.

Use only for videos you are allowed to keep for personal use.

## License
MIT
