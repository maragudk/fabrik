# Sync, CPU and Audio Resources, Audio and MIDI Fact Sheets

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Chapters 37-40: Sync (Link, Tempo Follower, MIDI), Computer Audio Resources, Audio Fact Sheet, MIDI Fact Sheet

### 37. Synchronizing with Link, Tempo Follower, and MIDI

**Which method**
- Link: Link-enabled apps, Push, or other Live instances on one network. Use it first when available.
- Tempo Follower: follow a live drummer or turntables. MIDI Clock/Timecode: hardware without Link.
- Link can run alongside Tempo Follower or MIDI sync. The Link session then takes the external tempo.

**Link** (Settings > Link tab)
- Enable with the Link toggle in the Control Bar, which shows the peer count. "Show Link Toggle: Hide" removes the toggle.
- Start Stop Sync shares transport, but only with peers that also enable it. Use stable Wi-Fi or a wired network.
- The first peer sets the tempo. Any peer can change it, and the last change wins. Link tempo **overrides tempo automation**. Start waits for global launch quantization (a progress bar shows in Arrangement Position).
- Gotcha: no recording count-in while Link is on.

**Link Audio** (new: stream audio between peers)
- Every peer needs Link plus the "Audio" option on. The Name field sets how others see you.
- To receive, set the audio track's Input Type to the peer and Input Channel to its track. Monitor In, or Auto when armed, and arm to record.
- Live and Push send and receive. Some third-party apps only send.
- The Latency slider sets buffering of incoming audio. Turn on Sync to Incoming Audio (delays Live to align) on **only one** participant.

**Tempo Follower** (Settings > Tempo & MIDI)
- Set Input Channel (Ext. In), for example a drum overhead or a DJ mixer record out. Turn on "Show Tempo Follower Toggle", then press **Follow** in the Control Bar. It does not run while hidden.
- It excludes External Sync (receiving clock), but Live can still send clock.

**MIDI sync**
- Clock: tempo plus song position. Live can be leader or follower. Timecode (SMPTE): position only, so Live can only follow and you set the tempo by hand.
- Leader: in Tempo & MIDI Settings, turn on Sync for the output port. The lower LED by EXT flashes.
- Follower: turn on Sync for the input port, then **EXT** in the Control Bar (or Options > External Sync). The upper LED flashes on valid sync. Song position pointers move the playhead, and they wrap inside the loop when Loop is on.
- Timecode (per port): Frame Rate ("SMPTE All" auto-detects) and Offset (maps to Arrangement start).
- **Sync Delay** (per port) compensates for transmission delay. Play percussive patterns on both devices and adjust by ear.

### 38. Computer Audio Resources and Strategies

**CPU meter**
- It shows buffer processing time as a percentage of buffer playback time. Above 100% means dropouts and clicks. It counts audio only, not the UI.
- The right-click menu has Average (default), Current (peak), and Meter Text Shows. CPU overload warnings are **off by default**: turn on "Warn on Current CPU Overload".
- Other apps can cause spikes, because the OS sets thread priority. Thermal throttling also hurts.

**Reducing load**
- Turn off unused I/O channels (Settings > Audio > Input/Output Config). Live does not do this automatically.
- Idle effects sleep, which lowers the *average* load but not the peak. **Stress test before a gig**: play every track with all devices active, and keep Current well below 100%.
- Performance Impact meters per track: turn on via the Mixer Config menu (bottom right) or View > Mixer Controls.
- Disk load scales with streamed channels. Bounce stacked layers in a Group to one file, or use clip RAM Mode. "Disk" in the Overload indicator means the disk can't keep up.

**Freeze**
- Edit menu, context menu, or **Cmd-Option-Shift-F**. It renders 32-bit files to Project/Samples/Processed/Freeze.
- Freeze needs clips, so Group, return, and Main tracks can't freeze. Bounce a Group instead. External Instrument/Effect tracks freeze in real time.
- While frozen, you can still launch, mix, cut/copy/trim/consolidate, edit mixer automation, record Session to Arrangement, and drag frozen MIDI clips onto audio tracks. Device and clip settings are locked.
- Gotchas: move Arrangement tails (crosshatched) together with their clip. Session freezes contain only **two loop cycles**.
- Bounce Track in Place commits the track for good. Freezing also lets machines without a plug-in, or with less CPU, play the Set.

### 39. Audio Fact Sheet

**Neutral (bit-identical)**
- Undithered export at the hardware sample rate, to the same or a higher bit depth.
- Unstretched playback at the Set's sample rate, with no transpose.
- Beats/Tones/Texture/Re-Pitch warp when clip tempo equals Set tempo. A tempo change is not permanent.
- Single-point summing (64-bit). Other processing is 32-bit, so many summing stages add tiny degradation.
- External recording when Live's bit depth is at or above the converter's. Internal recording at 32-bit.
- Bypassed effects, which are removed from the path. Lookahead delay is kept for PDC.
- Routing and clip splitting.

**Non-neutral**
- Complex/Complex Pro warp, even at the original tempo. It is also CPU-heavy, so use it only when other modes fail.
- Sample-rate conversion and transposition. Convert files offline to the project rate first. Export SRC uses SoX.
- Gain changes and volume automation (per-sample, very low distortion). Grooves at any tempo.
- Dither: apply it **once**, at final mastering. Otherwise **always render 32-bit**.
- Recording below the converter's bit depth, or internal recording below 32-bit.
- Consolidate: normalizes the file, compensates with clip gain, writes at the project rate and bit depth.
- Clip fades: "Create Fades on Clip Edges" (Settings > Record, Warp & Launch, up to 4 ms), Session Clip Fade, Arrangement fades.
- Panning: constant power, **+3 dB hard left or right**. Narrow with Utility Width before extreme pans.
- Freeze: Session tails are cut at 2 cycles, and tails stop abruptly on stop. Session freezes capture parameters at 1.1.1. Frozen clips play warped in Beats mode, and random parameters become fixed.

**Maximum fidelity**
- Fix the sample rate before you start. Record at the highest rate and bit depth you can. Don't mix sample rates in a Set.
- On clips that must stay untouched, turn Warp and Fades off and leave Transpose/Detune at zero. This disables stretching and sync.

### 40. MIDI Fact Sheet

**Concepts**
- Latency (constant) is easy to adapt to. Jitter (random) feels "loose". Live **adds latency to avoid jitter** and records what you hear.
- Drivers timestamp incoming MIDI, so notes record correctly even during audio dropouts.
- With track monitoring on, Live adds latency based on the buffer size so recordings match what you heard.

**Outside Live's control**
- Hardware ignores timestamps. DIN MIDI is serial, so chords are sent note by note. Old synths scan their keyboards slowly.
- Driver quality varies, and errors add up across a chain. In Ableton's tests most jitter was within ±1 ms, with worst cases of ±10–11 ms at large buffers (1152 on macOS).

**Practical rules**
- Use the lowest stable buffer size (Settings > Audio).
- Use a good MIDI interface with current drivers.
- **Turn off track monitoring** when you hear a hardware synth directly or record MIDI from a drum machine. Turn it on only when you play through Live, for example with External Instrument or plug-ins.
