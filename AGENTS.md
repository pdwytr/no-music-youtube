# Agent spec: no-music-youtube

Goal: given a YouTube URL, make that video playable on a kid's iPad through a
Jellyfin server on the user's Mac, optionally with the background music removed.

This file is written for AI coding agents (Claude Code, Hermes, Codex, etc.).
Humans: see README.md.

## Tell the user up front
This runs on their own Mac, not the cloud: the Mac must stay on and awake, have
roughly 10 GB free disk (about 2.3 GB temporary per hour of video during music
removal, about 0.6 GB per finished hour), be on the same Wi-Fi as the iPad, and
the VPN must be off. Details and measurements are in README.md.

## Inputs
| Input | Required | Notes |
|---|---|---|
| YouTube URL | yes | Strip `&t=` is unnecessary; always pass `--no-playlist`. |
| remove music | no | Ask only if not stated. |
| Jellyfin admin credentials | for rescan only | Never invent them. Never ask the user to paste a password into chat; have them set env vars or sign in themselves. |

## Preconditions (check, don't assume)
1. macOS with Homebrew. `brew install yt-dlp ffmpeg`
2. Jellyfin server: `brew install --cask jellyfin`, then `open -a Jellyfin`.
   Check: `curl -s localhost:8096/System/Info/Public` returns JSON.
3. `StartupWizardCompleted` is `true` in that JSON. If `false`, the user has
   not finished first-run setup; nothing will show on the iPad until they do.
4. A library of type **Home Videos** (not Movies: Movies tries to match
   YouTube titles to films) pointing at the Kids folder (default `~/Movies/Kids`).
5. iPad on the same Wi-Fi as the Mac, VPN off. Address: `http://<mac-ip>:8096`
   (`ipconfig getifaddr en0`).

## Procedure
Run `scripts/kidsvideo.sh [--no-music] URL`. It does:
1. Download H.264/AAC MP4 with yt-dlp (iPad direct-plays it).
2. If `--no-music`: extract audio, run Demucs `--two-stems=vocals`, remux the
   vocals stem onto the untouched video stream (`-c:v copy`).
3. Move the result into the library and trigger a Jellyfin rescan.

Long videos take a long time. Run in the background and report when it exits;
do not poll in a loop.

## Verified facts and pitfalls
- Demucs `-d mps` fails ("Output channels > 65536 not supported at the MPS
  device"). Use `-d cpu`.
- Measured on one Apple-silicon Mac: 2 min of audio took 47 s on CPU (~0.4x
  realtime); a 54 min video took about 21 min. Your hardware will differ;
  time a short clip first and quote that, not a guess.
- Demucs "vocals" keeps speech but can remove or muddy sound effects and any
  sung parts. You cannot audition audio as an agent: say so and ask the user
  to listen to a few minutes.
- Keep the original until the user confirms the cleaned version. Deleting is
  irreversible; confirm what "swap"/"replace" means if it is ambiguous.
- If the user cancels a download: kill yt-dlp and delete its `*.part` files.
- Jellyfin API calls need a client identity header, e.g.
  `Authorization: MediaBrowser Client="x", Device="y", DeviceId="z", Version="1"`;
  without it `/Users/AuthenticateByName` returns a 400/500.
- If the browser setup wizard errors ("There was an error processing the
  request"), the server may still be healthy: check the Jellyfin log in
  `~/Library/Application Support/jellyfin/log/` before changing anything.
  Resetting a user's password or moving the data directory is destructive:
  say what you are about to do and get a yes first.
- Kid safety: create a separate Jellyfin user per child with a parental
  rating limit; do not hand the admin login to the iPad.

## Out of scope
Downloading content you have no right to keep, DRM'd streams, remote
(outside-the-home) access.

## Verification an agent should report
Back claims with output, not prose: file exists (`ls -lh`), duration matches
the source (`ffprobe`), audio stream present, and Jellyfin lists the item
(`/Items?Recursive=true&IncludeItemTypes=Video`). Say plainly what was not
tested (e.g. playback on the iPad).
