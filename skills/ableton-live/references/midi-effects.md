# MIDI Effect Reference

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Live 12 MIDI Effects: Operating Reference

- **Scale awareness:** every device with pitch controls has a **Use Current Scale** title-bar toggle. When on, pitch values are scale degrees that follow the clip's scale, and the device's own Root/Scale choosers are disabled.

### Arpeggiator
- **Use for:** rhythmic patterns from held notes (arps, strums).
- **Style:** standard patterns (Up, Down, Converge…), plus:
  - *Play Order* follows key-press order.
  - *Chord Trigger* repeats the whole chord.
  - *Random* is fully random. *Random Other* uses every note before repeating one. *Random Once* loops one random pattern until the input changes.
- **Rate:** ms or synced divisions. **Gate** = note length as % of Rate. Over 100% gives legato.
- **Distance + Steps:** transpose each repeat. +12 st with 2 steps plays C3, then C4, then C5. Keep it in key with Root/Scale or Use Current Scale.
- **Hold:** latches the pattern. Press more keys to add notes, and press a held note again to remove it, for build-ups.
- **Pattern Offset:** rotates the start note.
- **Groove:** adds swing. Its strength comes from the *Global Groove Amount*, not the device.
- **Retrigger:** Off, Note (restart on each new note), or Beat (restart every Interval).
- **Repeats:** default ∞. Use 1–2 for a guitar strum. With Beat retrigger it gives phrases with gaps.
- **Velocity:** ramps velocity to Target over Decay. Target 0 with a long Decay fades out. Its Retrigger restarts the ramp for rhythmic accents.

### CC Control
- **Use for:** sending automatable MIDI CCs to hardware.
- **Fixed knobs:** Mod Wheel, Pitch Bend, Pressure.
- **Custom A:** min/max button (default CC 64 sustain).
- **Custom B–M:** twelve dials you can rename and assign. Shown on Push; saved in presets.
- **Title bar:** 1–8/9–16 bank toggles. **Send** pushes all values, which resyncs hardware. **Learn** maps an incoming CC and also shows which CC a controller sends.
- **Gotcha:** existing clip automation for the same CC is *merged* with the device's output.

### Chord
- **Use for:** adding up to six pitches to each note (one-finger chords, octave/fifth stacks, generative harmony).
- **Shift 1–6:** ±36 st, any order. +4/+7 gives a major triad. You cannot use the same interval twice; a duplicate Shift is deactivated.
- **Learn:** hold a chord. The first key is the root, and the other keys fill the Shifts.
- **Per-Shift sliders:** *Velocity* is relative to the input (1–200%). *Chance* is the probability the note plays (0–100%).
- **Strum:** up to 400 ms between notes. Positive plays upward from the root, negative reverses.
  - **Tension** speeds the strum up or slows it down.
  - **Crescendo** ramps velocity up or down.
- **Context menu:** "Play Duplicate Notes When Strumming"; "Send Per Note Events to Generated Notes" (MPE). With scale awareness on, MPE bends follow the scale.

### Note Length
- **Use for:** forcing note lengths (staccato/legato), or triggering notes on key release.
- **Note On mode:** length = Length × Gate (200% doubles, 50% halves). Length is in ms or synced divisions.
- **Note Off mode:** each note starts where it would have ended. Extra controls:
  - **Release Velocity:** blends On and Off velocity. Use 0% if your keyboard has no release velocity.
  - **Decay Time:** velocity falls from Note On, so a longer hold gives a softer note.
  - **Key Scale:** a positive value makes notes below C3 longer and notes above shorter.
- **Latch:** holds each note until the next Note On, or (in Note Off mode) fires when all keys and the pedal are released.
  - **Gotcha:** Latch disables Gate and Length, and in Note Off mode also the three extra controls.

### Pitch
- **Use for:** transposing and range-limiting notes.
- **Pitch:** ±128 st or ±30 degrees.
- **Step Up/Down:** jumps by Step Width. Map them to keys or MIDI for live transposition.
- **Lowest + Range:** set the allowed note window. **Mode** handles notes outside it:
  - **Block** drops them (LED flashes).
  - **Fold** transposes them inside.
  - **Limit** clamps them to the edge note.

### Random
- **Use for:** generative pitch variation and round-robin alternation.
- **Chance:** acts like a dry/wet control for randomness.
- **Choices × Interval:** set the pitch pool. Choices 1/Interval 12 gives the note or its octave up. Choices 12/Interval 1 gives any semitone up to the octave.
- **Sign:** Add (up, default), Sub (down), Bi (both).
- **Mode Alt:** steps through the pool round-robin. Chance 100% always advances, and 0% always plays the original. Choices 2/Interval 2 alternates C3/D3 (bowing, L/R drum hits).
- **Use Current Scale:** keeps notes in key. Alt mode plus a scale makes a simple step sequencer.

### Scale
- **Use for:** forcing notes into a key or custom remaps.
- **Note Matrix:** columns are input notes and rows are output notes, with the root at the bottom left. Set the key with Base + Scale Name or Use Current Scale.
- **User scale:** drag squares to remap notes and click to delete them.
  - **Gotcha:** a deleted note is never output.
- **Fold (User only):** keeps notes within 6 st of the original (C3→A3 becomes A2).
- **Transpose:** ±36 st.
- **Lowest + Range:** limit remapping and transposition to one note window. Other notes pass through.

### Velocity
- **Use for:** taming, fixing, or randomizing velocities.
- **Curve:** maps the input window (Lowest + Range) to the output window (Out Low/Out Hi). Out Low 80 / Out Hi 127 makes soft playing loud.
- **Operation:** Note On velocity, release velocity, or both.
- **Mode:** handles inputs outside the input window.
  - **Clip** clamps them.
  - **Gate** drops the notes (LED flashes).
  - **Fixed** sets every note to Out Hi.
- **Random:** adds ± variation inside the output window. A grey band on the curve shows its range.
- **Drive:** a positive value pushes notes loud, a negative value pushes them soft.
- **Compand:** a positive value spreads notes to the extremes, a negative value squeezes them to the middle.
