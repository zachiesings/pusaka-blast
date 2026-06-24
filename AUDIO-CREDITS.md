# Audio Credits & Licensing — Pusaka Blast

All in-app audio is **rendered originals** produced by `tool/render_audio.py` in
CI (`.github/workflows/audio.yml`). No copyrighted recordings are used.

## Instrument sound source — SoundFont
- **FluidR3_GM** by Frank Wen.
- Obtained via the Debian package **`fluid-soundfont-gm`** (Debian *main* →
  DFSG-free). The license permits redistribution and the use of rendered audio in
  applications, including commercial ones.
- Path on the runner: `/usr/share/sounds/sf2/FluidR3_GM.sf2`.

## SFX + BGM
- SFX (`tap`, `move`, `place`, `clear`, `combo`, `gong`, `gameover`) are rendered
  from GM voices (marimba/glockenspiel/piano) with reverb + normalisation so they
  punch through.
- `bgm_home` / `bgm_game` are **original, humanized** loops (bass + soft chords +
  vibraphone sparkle + light percussion) in a warm keraton groove — composed
  programmatically with velocity + micro-timing humanization. Nothing is copied
  from any existing song.

## ⚠️ General-MIDI fallback
| Sound | GM program used | Note |
|---|---|---|
| **gong** | **Tubular Bells (14)** | closest GM voice to a gong strike — FALLBACK |

All other SFX/BGM voices are ordinary GM instruments used as generic synths, not
imitating any specific protected instrument.
