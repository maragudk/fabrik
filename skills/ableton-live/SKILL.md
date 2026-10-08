---
name: ableton-live
description: Guide for making music in Ableton Live 12 on macOS. Use this skill whenever the user asks how to do something in Ableton Live or "in Live", wants help with a Live Set, project, or session, asks which stock Live device or instrument to use for a sound (Operator, Wavetable, Drift, Meld, Simpler, Sampler, Roar, Echo, Hybrid Reverb, Auto Filter, Drum Rack, Racks, Macros...), needs warping, Session vs Arrangement, clip launching, Follow Actions, MIDI editing, MIDI Tools, scale awareness, grooves, automation, clip envelopes, routing, sidechain, resampling, comping, stem separation, bouncing, freezing, exporting, Push 1/2, Link, MIDI sync, CPU or latency troubleshooting, or keyboard shortcuts. Trigger even when the user doesn't say "Ableton" -- words like "Live Set", ".als", "clip slot", "scene", "Drum Rack", "Simpler", "warp marker", "Session View", "Arrangement View", "Max for Live", or "Push" are enough. Also use it when the user is producing electronic music and asks for a workflow or sound-design recipe that will be executed in Live.
license: MIT
---

# Ableton Live 12

## Overview

This skill distills the Ableton Live 12 Reference Manual into an operating reference for helping a producer get things done in Live on macOS. SKILL.md holds the mental model, a router to the detailed references, the recipes people ask for most, and the gotchas that waste the most time. The `references/` directory holds chapter-level detail: exact menu locations, every parameter that matters, and per-device notes.

Keys are written for macOS: CMD, ALT (Option), SHIFT, CTRL.

## When to use this skill

Use it for any "how do I X in Live", "which device for Y", "why does Z not work", or "give me a workflow for W" question, and when writing instructions a producer will follow inside Live. For a pure music-theory or mixing-theory question with no Live-specific execution, you don't need it.

## How to answer well

1. **Name the exact UI location and the shortcut.** "Clip View > Audio Utilities > Warp" beats "turn on warping". Include the macOS shortcut when one exists; the full table is in `references/keyboard-shortcuts.md`.
2. **Say which view the user must be in.** Many commands and keys are context-dependent (CMD+E splits clips in Arrangement, chops notes in the MIDI editor, and adds a stop button in Session). State where focus must be.
3. **Prefer stock devices and name them.** When recommending a sound or effect, name the Live device, the mode or algorithm, and the two or three controls that matter. Device details live in `references/audio-effects.md`, `references/midi-effects.md`, and `references/instruments.md`.
4. **Flag edition and version limits.** Sampler, Max for Live, some MIDI Tools and devices are Suite (or Standard plus add-on) only. Stem separation arrived in Live 12.3. Say so when it matters.
5. **Give the gotcha with the instruction.** Most Live frustrations are a hidden state: a gray automation LED, a track still on a Session clip, a mapped MIDI note that no longer plays, an unwarped clip that can't loop. The gotcha lists below are the checklist.

## Where to look

| Question is about | Read |
|---|---|
| Settings, Learn/Info View, the browser, tags, Collections, Packs, Splice, Cloud, User Library, projects, Collect All and Save, missing files, export dialog, templates and default Set | `references/setup-browser-and-files.md` |
| The Session/Arrangement mental model, Control Bar, arrangement editing, locators, loop brace, fades, linked tracks, scenes, scene tempo, Clip View panels, clip properties, Launch Modes, Legato, Follow Actions | `references/views-and-clips.md` |
| Warp markers and modes, tempo leader, tap tempo, Bounce to Audio, comping and take lanes, stem separation, video | `references/warping-bounce-comping-stems.md` |
| MIDI Note Editor, velocity and probability, Pitch and Time Utilities, MIDI Tools (Transform and Generate), MPE editing, audio-to-MIDI, Groove Pool, tuning systems | `references/midi-editing-and-tools.md` |
| In/Out section, monitoring, external audio and MIDI, resampling, track-to-track routing recipes, mixer, groups, returns, cue, crossfader, track delay, arming, Session and Arrangement recording, overdub, Capture MIDI, step recording, count-in | `references/routing-mixing-recording.md` |
| Recording, drawing, editing and deleting automation, automation shapes, lanes, Re-Enable, tempo automation, clip envelopes, modulation vs automation, unlinked envelopes as LFOs | `references/automation-and-envelopes.md` |
| Device View, chain order, presets, hot-swap, A/B compare, defaults, delay compensation, VST/AU setup, Configure Mode, plug-in sidechain, Racks, zones, Drum Racks, Macros, Macro Variations | `references/devices-plugins-racks.md` |
| Any stock audio effect, Amp to Vocoder | `references/audio-effects.md` |
| Arpeggiator, CC Control, Chord, Note Length, Pitch, Random, Scale, Velocity | `references/midi-effects.md` |
| Analog, Collision, Drift, Drum Sampler, Electric, External Instrument, Impulse, Meld, Operator, Sampler, Simpler, Tension, Wavetable | `references/instruments.md` |
| What Max for Live is, editing devices, the Drum Synths, LFO/Shaper/Envelope Follower modulators, MPE Control, Note Echo | `references/max-for-live.md` |
| MIDI and Key Map Mode, control surfaces, takeover modes, Push 1 and Push 2 operation | `references/controllers.md` |
| Link, Link Audio, Tempo Follower, MIDI Clock and Timecode, CPU meter, buffer size, Freeze, what is and isn't audio-neutral, MIDI timing | `references/sync-performance-and-audio-facts.md` |
| Keyboard navigation, accessibility, the full shortcut tables | `references/keyboard-shortcuts.md` |

## The mental model

- A **Live Set** (`.als`) is the document and lives in a **Project** folder that also holds recorded and processed samples. Audio is referenced, not embedded, so **File > Collect All and Save** before moving or archiving a project.
- **Tracks** host clips and a device chain. **Clips** hold the music: an audio clip references a sample plus non-destructive playback settings; a MIDI clip holds notes and needs an instrument to make sound.
- **Session View** is a grid of launchable clips (columns are tracks, rows are **scenes**). **Arrangement View** is the linear timeline. Both share the same tracks, mixer and devices. Tab switches between them.
- **One clip per track at a time.** Launching a Session clip takes that track away from the Arrangement until you press **Back to Arrangement**. This is the single most common "my song disappeared" cause.
- Device chains run **MIDI effects > instrument > audio effects**, left to right. The engine is 32-bit float, so nothing clips between devices; only the physical outputs, the Main track and exported files can clip.
- **Returns** hold shared effects fed by sends. **Group tracks** are submix buses. The **In/Out section** is the patchbay for everything else.
- **Automation** sets absolute values (red). **Modulation** from clip envelopes offsets relative to the current value (blue). Both can act on one parameter.
- Live 12 is **scale-aware**: set a scale on a clip or in the Control Bar and the MIDI editor, MIDI Tools and devices with "Use Current Scale" work in scale degrees.

## Recipes people ask for most

### Make a loop follow the tempo
Double-click the clip, open **Audio Utilities**, turn **Warp** on. Live auto-warps; if it reads double or half tempo, press **x2** or **÷2**. Pick the Warp Mode for the material: **Beats** for drums, **Tones** for mono pitched sources, **Texture** for pads and noise, **Re-Pitch** for turntable-style speed changes, **Complex Pro** for full mixes. An audio clip must be warped before it can loop.

### Fix a badly cut loop or a full song
Put the insert marker on the first downbeat, right-click > **Set 1.1.1 Here**, then **Warp From Here**. For hard material work left to right, pinning each correct section with a warp marker (CMD+I) before moving on. Turn the metronome on while checking.

### Sidechain compression from the kick
On the bass track, add **Compressor**, open the sidechain panel (toggle in the title bar), set **Audio From** to the kick track, choose **Post FX**, and pull the threshold down. The sidechain signal is never heard. For a pumping effect with no trigger, use **Auto Pan-Tremolo** with Invert on instead.

### Resample the master
Set an audio track's **Input Type** to **Resampling**, arm it, record. The recording track's own output is excluded. Keep the Main meter out of the red.

### Print a track to audio
**Bounce Track in Place** (track title bar) replaces the track and bounces both views; this replaced Freeze and Flatten in Live 12. **CMD+B** bounces the selection to a new track and mutes the source. Both print devices but copy the mixer settings rather than printing them. **Freeze** (CMD+ALT+SHIFT+F) is the reversible version for saving CPU.

### Record MIDI into a one-bar loop
Set Global Quantization to 1 Bar, double-click an empty slot to create a clip, arm the track, press **Session Record**. Each pass overdubs. Forgot to record? Press **Capture MIDI**: Live always listens on armed and monitored MIDI tracks and will also detect the tempo in an empty Set.

### Build a drum pattern fast
Drop a kit into a **Drum Rack**. In the clip, press **F** to fold to used rows. Use the **Rhythm** generator (Transform/Generate tabs) for one pad, deselect, pick another pad, generate again. Add swing from the **Groove Pool**, humanize with **Velocity Deviation** and the **Chance** lane.

### Make a part evolve without editing notes
Session clip > **Envelopes** tab > **Unlink** the envelope, give it an odd length (3.2.1 against a 1-bar loop), loop it. An unlinked looped envelope is a tempo-synced LFO on any device or mixer parameter.

### Layer two synths on one MIDI part
Set the second track's **MIDI From** to the first track (Post FX). Or group both instruments into an **Instrument Rack**, where every chain receives the same input and Macros control both.

### Split a sample into playable slices
Right-click the clip > **Slice to New MIDI Track** (128 slices max), or load it into **Simpler** in **Slicing** mode. Edit transients before slicing; notes split at the transient markers.

### Extract vocals or drums from a mix
Right-click the clip or browser file > **Separate Stems to New Audio Tracks**. **High Quality** runs separate passes and is better; crop the clip first (CMD+SHIFT+J) to save time. Expect some bleed between stems.

### Turn a performance into a song
Perform in Session with **Arrangement Record** on. Live records clip launches, mixer and device moves and tempo changes into the Arrangement. Press **Back to Arrangement** afterwards. **Capture and Insert Scene** (CMD+SHIFT+I) saves a good combination while jamming.

### Share a project
**File > Collect All and Save**, then **Manage Project > Create Pack** for a compressed `.alp`. External files are not included unless collected.

## Which device?

| Want | Reach for | Notes |
|---|---|---|
| Fast analog bass, lead, pad, low CPU, MPE | **Drift** | Shark Tooth and Saturated shapes; Type II filter for Moog-ish lows |
| Evolving pads, supersaws, growls, custom wavetables | **Wavetable** | drag any WAV onto the display; Position is the control to modulate |
| Bells, e-pianos, FM basses, synth drums | **Operator** | integer ratios are harmonic; the noise LFO makes hats and snares |
| Strange, scale-aware, texture and swarm sounds | **Meld** | two macro-oscillator engines, each with its own matrix |
| Vintage polys, brass, PWM | **Analog** | two filters with flexible routing; more CPU than Drift |
| Mallets, bells, physical hits | **Collision** | Resonator type plus Material and Decay set the character |
| Strings, pianos, plucked or bowed physical models | **Tension** | many settings go silent or very loud; start from presets |
| One sample, chopping, loops in tempo | **Simpler** | Classic / One-Shot / Slicing; warp works inside it |
| Multisampled instruments, round robin, deep modulation | **Sampler** | Suite; Distribute Ranges Around Root Key maps samples fast |
| Drum kits | **Drum Rack** with **Drum Sampler** pads | choke groups, 6 return chains, Save as Default Pad |
| Compression | **Compressor** (general), **Glue Compressor** (bus glue), **Multiband Dynamics** (mastering, de-ess, upward expansion) | keep bus gain reduction under about 6 dB |
| Saturation and distortion | **Saturator** (simple), **Roar** (routed, modulated, feedback), **Pedal** (guitar), **Drum Buss** (drum group) | Roar's Tone with Color Compensation keeps bass punch |
| Delay | **Echo** (main creative delay), **Delay** (simple stereo), **Spectral Time** (freezes), **Grain Delay** (granular) | Echo sleeps about 8 s after silence unless Noise and Gate are on |
| Reverb | **Hybrid Reverb** (convolution plus algorithms), **Reverb** (cheap classic) | Prism algorithm with tiny Decay and Size gives gated 80s snares |
| Filter sweeps, auto-wah, rhythmic filtering | **Auto Filter** | LFO, envelope follower, sidechain; Morph and Vowel types |
| Pitch correction, harmonies, formant shift | **Auto Shift** | MIDI mode only sounds while notes play |
| Stutters | **Beat Repeat** | Insert mode is the classic stutter |
| Width, mono bass, gain staging | **Utility** | Bass Mono with Audition; Mute before a reverb keeps the tail |
| Loudness ceiling | **Limiter** last on Main, Main fader at or below 0 dB | True Peak mode for release masters |
| Vocoder, talking synths | **Vocoder** on the modulator track | External carrier from the synth track Post FX |

## Live 12 features worth knowing

- **Scale Mode** and **Use Current Scale** across the editor, MIDI Tools and devices (Arpeggiator, Chord, Pitch, Random, Scale, Auto Shift, Meld, Resonators, Spectral Resonator).
- **MIDI Tools**: Transformations (Arpeggiate, Chop, Connect, Ornament, Quantize, Recombine, Span, Strum, Time Warp, Velocity Shaper, Glissando and LFO for MPE) and Generators (Rhythm, Seed, Shape, Stacks, Euclidean). CMD+Enter applies the current tool. Custom tools are Max for Live devices.
- **Tuning systems**: load `.scl` or `.ascl` files; Drum Racks bypass tuning; MPE plug-ins need a 48-semitone bend range.
- **Browser**: Sound Similarity search (CMD+SHIFT+F), Similar Sample Swapping in Drum Racks and Simpler, Auto Tags, custom labels from saved searches.
- **Linked tracks** for phase-locked multitrack editing and comping.
- **Bounce to Audio** replaces Freeze and Flatten; **Stem Separation** (12.3); **Link Audio** streams audio between Link peers.
- Devices new in Live 12: Meld, Roar, Drum Sampler, Auto Shift. Racks gained 16 Macros, Macro randomization and Macro Variations.
- Clip View is now **panels on the left, editor on the right**; Settings replaced Preferences (CMD+,); the Master track is now the **Main** track.

## Gotchas that cost the most time

- **Song went silent or won't play the timeline**: a track is still on a Session clip. Press **Back to Arrangement**.
- **Automation stopped working**: the parameter was touched; the LED is gray. Press **Re-Enable Automation** in the Control Bar, or relaunch the Session clip.
- **A/B compare and automation**: switching device state disables automation, and switching back doesn't restore it. Re-enable per parameter.
- **Mapped MIDI notes don't play**: a note or CC mapped in MIDI Map Mode never reaches tracks. Watch the Control Bar MIDI indicators.
- **Letter shortcuts stopped working**: the computer MIDI keyboard (M) is on. Add SHIFT or turn it off.
- **Tab doesn't switch views**: "Use Tab Key to Move Focus" is on in Settings > Display & Input.
- **Clip won't loop**: audio clips must be warped to loop.
- **Reverse, Consolidate and Crop write new files** and turn a video clip into audio.
- **Consolidate renders pre-effects**; use Export or Bounce for a render with effects.
- **Exported stems silently include active Session clips** on their tracks. Stop clips or Back to Arrangement before exporting.
- **Dither once**, only on the final master. Send 32-bit float to mixing or mastering.
- **Complex and Complex Pro warp are never audio-neutral** and are the heaviest on CPU. Freeze or bounce tracks that use them.
- **Group deletion deletes its contents**. Ungroup first.
- **Track Delay is unavailable** when Delay Compensation is off. Keep compensation on; put tempo-synced effects early in a chain.
- **Record Quantization during a loop overdub** applies immediately and can't be undone separately.
- **Session freezes capture only two loop cycles**, and freeze can't run on Group, return or Main tracks. Bounce the group instead.
- **Collect All and Save** is also needed after Save As to a new location, and after editing a Cloud-synced Set.
- **Deleting automation returns the parameter to its default**, not its last value.
- **Impulse applies parameter changes on the next note**, so automate Simpler instead for in-note sweeps.
- **Live Clips** (`.alc`) only restore their device chain when dropped on an empty track or the empty area.
- **Splice samples force Complex warp mode** regardless of your default.
- **Exclusive Arm and Solo** are on by default; hold CMD to add tracks.

## Essential shortcuts

| Action | Shortcut |
|---|---|
| Session / Arrangement | Tab |
| Clip View / Device View | CMD+ALT+3 / CMD+ALT+4 |
| Browser | CMD+ALT+B |
| Play / Stop, continue from stop point | Space, SHIFT+Space |
| Record Arrangement / Record Session | F9 / CMD+SHIFT+F9 |
| Back to Arrangement | F10 |
| New audio / MIDI / return track | CMD+T / CMD+SHIFT+T / CMD+ALT+T |
| Group tracks or devices, ungroup | CMD+G, CMD+SHIFT+G |
| Rename, then next | CMD+R, Tab |
| Draw Mode | B |
| Automation Mode | A |
| Fold MIDI editor rows | F |
| Highlight Scale | K |
| Split / Consolidate / Crop | CMD+E / CMD+J / CMD+SHIFT+J |
| Loop selection | CMD+L |
| Quantize / settings | CMD+U / CMD+SHIFT+U |
| Insert warp marker | CMD+I |
| Bounce to new track | CMD+B |
| Freeze | CMD+ALT+SHIFT+F |
| Hot-swap | Q |
| MIDI Map / Key Map | CMD+M / CMD+K |
| Global quantization 1/16, 1/8, 1/4, 1 bar, off | CMD+6, 7, 8, 9, 0 |
| Grid finer / coarser / triplet / snap toggle | CMD+1 / CMD+2 / CMD+3 / CMD+4 |
| Zoom to selection / back | Z / X |
| Export audio | CMD+SHIFT+R |
| Settings | CMD+, |
| Apply current MIDI Tool | CMD+Enter |
| Similarity search | CMD+SHIFT+F |

Hold CMD while dragging to bypass the grid; hold SHIFT for fine control; ALT-drag copies clips and notes.
