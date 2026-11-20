# no-music-youtube

Put a YouTube video on your kid's iPad through a Jellyfin server on your Mac,
optionally with the background music removed.

- `scripts/kidsvideo.sh` does the work (download, optional music removal, rescan).
- `AGENTS.md` is the spec for AI agents that run this for you.

## What you need (read this first)
**This runs on YOUR computer, not in the cloud.** There is no hosted service.
Nothing here works unless these are true:

1. **A Mac that stays on and awake.** The Mac *is* the server. If it sleeps,
   shuts down, or loses Wi-Fi, the iPad can't play anything. Turn off sleep
   (System Settings, Battery or Lock Screen) or keep it plugged in with the
   lid open. Music removal also needs the Mac awake for its whole run.
2. **Free disk space on that Mac.** Videos are stored locally. Measured
   for one 54-minute video:
   - Final video: about 0.6 GB. 20 videos of that size is roughly
     12 GB.
   - Temporary files during music removal: about 2.3 GB at the peak (a 0.55 GB
     source, a 0.56 GB audio copy, 1.1 GB of separated audio). They are deleted
     when the script finishes.
   - Tools: Jellyfin app about 0.35 GB, Demucs and its Python packages about
     0.85 GB, plus the Demucs model that downloads on first use (size not
     measured here).
   - Rule of thumb: keep **10 GB free** to start, more for a bigger library.
3. **Home Wi-Fi.** The iPad and the Mac must be on the same network. A VPN on
   the Mac can block the iPad from reaching it; turn the VPN off.
4. **Internet** for the download and the one-time installs. After that,
   playing videos at home needs no internet.
5. **Homebrew** (https://brew.sh) to install the tools below.
6. **Patience for music removal.** See the timing table further down. Your
   Mac does the work, so it will be busy and warm.

What this does **not** do: it does not work when you are away from home (that
needs extra setup not covered here), and nothing is backed up. If the Mac's
disk dies, the videos are gone.

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

## How long does it take?
Measured on a MacBook Pro 14/16" (M1 Pro, 10 cores, 16 GB RAM, macOS 15), CPU
mode, 2021-class hardware:

| Video length | Music removal time | Basis |
|---|---|---|
| 2 min | 47 s | measured |
| 54 min | about 21 min | measured |
| 1 hour | about 25 min | extrapolated at ~0.4x realtime |
| 2 hours | about 50 min | extrapolated at ~0.4x realtime |

Download is quick on a normal connection (a 554 MB, 54 min video took roughly
1 to 2 minutes here). Remuxing the finished audio onto the video takes seconds
because the video is copied, not re-encoded. The one-time Demucs install is a
few minutes and a large download.

Other machines: expect slower on older Intel Macs or machines with 8 GB RAM,
and faster on newer Apple-silicon chips. These are guesses; only the M1 Pro
numbers above were measured. Time a 2-minute clip on yours and scale it.

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
