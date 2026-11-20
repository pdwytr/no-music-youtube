---
name: no-music-youtube
description: Use when given a YouTube link for a kid's iPad. Download, optionally strip music, add to Jellyfin.
---

# no-music-youtube

Turn a YouTube link into a video the kid's iPad can play from a Jellyfin
server on this Mac, optionally with the background music removed.

Full spec: `AGENTS.md` in https://github.com/pdwytr/no-music-youtube
Script: `scripts/kidsvideo.sh` in the same repo.

## Flow
1. Get the URL. Ask once, only if unstated: "Remove the music?"
2. Check preconditions: `curl -s localhost:8096/System/Info/Public` returns
   JSON with `"StartupWizardCompleted":true`; the Kids library folder exists
   (default `~/Movies/Kids`); the VPN is off; the Mac has free disk (about
   2.3 GB temporary per hour of video for music removal).
3. Run `kidsvideo.sh [--no-music] URL` in the background for anything long and
   stop polling: Hermes notifies when it exits. Tell the user the expected
   time first (measured on an M1 Pro: about 0.4x the video length, so a
   54-minute video took about 21 minutes; quote a 2-minute test on other
   hardware, not a guess).
4. Verify with output: file exists, `ffprobe` duration matches the source,
   audio stream present, Jellyfin lists the item.
5. Report: file name, length, what was NOT tested (iPad playback, how the
   music removal sounds).

## Rules
- Always `yt-dlp --no-playlist`; a link with `&list=` must not pull a playlist.
- Demucs must use `-d cpu`; the Apple GPU backend crashes.
- Music removal can remove sound effects and sung parts. You cannot listen:
  say so and ask the user to check a few minutes.
- Keep the original until the user confirms. Deleting is irreversible.
- Never invent, guess, or ask for Jellyfin passwords in chat. Credentials come
  from the `JELLYFIN_USER` / `JELLYFIN_PASSWORD` environment variables; if
  they are missing, skip the rescan and tell the user.
- Resetting a Jellyfin user or moving its data directory is destructive:
  say what you will do and get a yes first.
- If the user cancels: kill yt-dlp and delete its `*.part` files.
- Only for videos the user may keep for personal use.
