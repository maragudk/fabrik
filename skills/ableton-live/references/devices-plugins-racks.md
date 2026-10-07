# Working with Devices, Plug-Ins and Racks

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Chapter 23: Working with Instruments and Effects
- Chapter 24: Using Plug-Ins
- Chapter 25: Instrument, Drum and Effect Racks

## Chapter 23: Working with Instruments and Effects

Covers device basics, presets, hot-swap, defaults, and delay compensation. Racks and Macros follow below; per-device sidechain details are in the audio-effects reference.

### Device types and chain order
- **MIDI effects** go on MIDI tracks before the instrument. **Instruments** go on MIDI tracks (MIDI in, audio out). **Audio effects** go on audio, return, and Main tracks, or after the instrument on a MIDI track.
- A MIDI track can hold all three: MIDI effects, then the instrument, then audio effects. Signal flows left to right, and order changes the sound.
- To share one effect across tracks, put it on a return track.

### Device View
- Double-click a track title bar to show its devices. **CMD+OPT+3** shows/hides Clip View. **CMD+OPT+4** shows/hides Device View.
- **Stack both views**: use the toggles next to the Clip/Device View selectors (bottom right). You can then edit notes and tweak devices without switching.
- **Fold a device**: double-click its title bar, or choose Fold from the context menu.
- **Expanded views**: an arrow toggle next to the Activator opens a larger panel above the device (Roar's Gain Stage/Mod Matrix, EQ Eight's display). A triangle icon expands sections inside the device (Phaser-Flanger's LFO).

### Adding, moving, removing
- **Add**: double-click a device or preset in the browser. It goes to the selected track, or to a new track if none is selected. You can also select it and press Return, or drag it onto a track or into the Device View. Double-clicking more devices appends them to the chain.
- Dropping a sample into an empty MIDI track's Device View creates a Simpler with that sample loaded.
- **Reorder**: drag a device by its title bar. **Move to another track**: drag it onto that track in Session or Arrangement.
- **Delete**: select the device, then press Delete. CMD+X/C/V/D work on devices. A pasted device goes in front of the selection. To paste at the end, click the empty space after the last device or press the right arrow first.
- You can edit the chain during playback without dropouts.
- **Play live input through effects**: arm the track (Monitor: Auto). MIDI tracks auto-arm when you insert an instrument.

### Meters and headroom
- Use each device's in/out meters to find the device that drops or kills the signal.
- **No clipping between devices** (headroom inside a chain is practically unlimited). Clipping happens only at a physical output or when audio is written to a file, so control the level at the end of the chain.

### Title bar
- **Activator**: an off device passes the signal unprocessed and uses no CPU, like a temporary delete. For heavy devices, use Freeze Track.
- Extra toggles on some devices: scale awareness (follows the clip's scale) and Learn (Chord).
- **Context menu**: right-click the title bar or click Show Options. It has Cut/Copy/Rename plus device-specific options (e.g. Auto Filter's Mono Sidechain).

### A/B comparison
- Each built-in device has two parameter states. Use them to compare small EQ or compression changes.
- On load, A = B. When you edit, only A changes, so B stays as the "before" reference.
- **P** switches state (or Compare: Switch to A/B in the Edit menu or context menu). "(B)" shows in the title bar when B is active. **Compare: Copy A to B** (or B to A) copies the values.
- **Not available for Racks, Max for Live devices, or plug-ins.**
- **Gotchas**: Automation belongs to one state. Switching state disables it, and switching back does not turn it on again. Right-click the parameter and choose **Re-Enable Automation** each time. Copying the device, duplicating it, or saving it as a preset keeps only the active state.

### Presets
- In the browser, each device is a folder. Loading the folder loads the default (factory or your custom default). The items inside are presets.
- **Keyboard**: up/down arrows move, left/right arrows fold folders, Return loads.
- To replace a preset, drag a new one onto the existing device.
- **Save**: click the Save Preset button in the title bar. The browser selects the new preset in User Library > Presets. Rename it, then press Return to save or Esc to cancel. Info View text is saved too. You can also drag a device by its title bar into any Places folder.

### Hot-swapping
- **Q** (or the Hot-Swap button) links the device to the browser. If no device is selected, Q targets the first audio effect (audio track) or the instrument (MIDI track).
- Arrow through presets, then press Return or double-click to load. You can swap to a different device of the same category (not audio effect to MIDI effect). Load the parent folder to reset to the default.
- **Tip**: add `-EnableHotSwapOnSelection` to Options.txt to load each preset as soon as you select it.
- **Samples**: use the Hot-Swap Sample button on Drum Rack pads, Drum Sampler, Impulse, and Simpler (shows on hover, bottom right of the sample area), or in Sampler (top left of the expanded Zone Editor). The browser opens at the sample's folder.
- **Exit**: Q, Esc, the X in the Hot-Swap bar or title bar, or go to another view.

### Defaults (User Library > Defaults)
Defaults apply automatically. Delete one to get factory settings back.
- **Device**: context menu > **Save as Default Preset** (works for native devices and Racks). If you drag the device into Defaults instead, it must keep its original name (e.g. "Simpler"). An instrument default includes its loaded sample.
- **Plug-in**: set the parameters in Configure Mode, then **Save as Default Configuration**. VST and AU are separate. **Gotcha**: this saves only which parameters are shown, not their values. To keep the values, wrap the plug-in in a Rack and save the Rack as the default.
- **Tracks**: track context menu > **Save as Default Audio/MIDI Track**. This saves devices, routing, volume, pan, and sends. If you drag the track in, it must be named "Default Audio Track" or "Default MIDI Track".
- **Sample dropping**: drag a configured empty Simpler/Sampler into Dropping Samples > On Device View or On Drum Rack. You can also use a pad's context menu > Save as Default Pad.
- **Slicing**: build a Drum Rack with one chain (empty Simpler/Sampler, plus effects and Macros), then drag it into Slicing. You pick it in the Slice to New MIDI Track dialog.
- **Audio to MIDI**: drag a Rack into Drums, Harmony, or Melody to MIDI. An Instrument Rack is recommended for Harmony and Melody. Drums needs a top-level Drum Rack, not one nested inside an Instrument Rack.
- The most recently added item in a folder is the active one.
- **Per Project**: make a Defaults folder (with the same subfolders) inside the Current Project, then drag items into it. These override global defaults for that Project. Save-as-Default commands only write to the User Library. For plug-ins, save normally, then drag the folder with Default.appc into the Project's Defaults/Plug-In Configurations/VSTs or Audio Units. This moves the file, so save again if you also want a global copy.

### Delay compensation
- On by default and keeps all tracks, returns included, in sync. Toggle it in **Options > Delay Compensation**. Leave it on.
- **Options > Reduced Latency When Monitoring**: input-monitored tracks get the lowest latency but may drift from others, such as returns. Turn it on while tracking and off when you need tight sync.
- **Gotcha**: tempo-synced devices placed after latency-inducing devices can sound late. Put synced effects early in the chain.
- If very high plug-in latency makes Live sluggish, try Track Delay first. Track Delay is unavailable when compensation is off, so turn compensation off only as a last resort. Compensation can also increase CPU load.

## Chapter 24: Using Plug-Ins

### Formats and placement
- On macOS, Live supports VST2, VST3, AU2 and AU3 (AU3 since Live 11.2). AU is macOS only.
- Plug-in instruments go only on MIDI tracks. Plug-in effects go on audio tracks or after an instrument.

### Activating plug-in sources (first launch)
- The browser's **Plug-Ins** label is empty until you activate sources. Click **Activate** there, or go to **Settings > Plug-Ins > Plug-In Sources** (CMD+,).
- **AU:** turn on **Use Audio Units**.
- **VST:**
  - **Use VST Plug-Ins in System Folders** covers `/Library/Audio/Plug-Ins/VST`, in both the home and the local Library.
  - **VST Plug-In Custom Folder > Browse** adds your own folder, and its toggle switches it on or off.
- Subfolders are scanned. For plug-ins stored elsewhere, put a macOS **alias** of their folder inside a scanned VST folder.

### Browser
- Instruments have a keyboard icon.
- Plug-in presets appear in the browser **only for AU**. Some AU factory presets appear only after the device is on a track with **Hot-Swap** on.

### Rescanning and crash troubleshooting
- Live does not see installs or removals made while it is running. Click **Settings > Plug-Ins > Rescan** to pick them up.
- **ALT+click Rescan** deletes the plug-in database and runs a clean scan.
- **Hold ALT while Live launches**, until the splash screen closes, to skip the plug-in scan.
- **Crash during a scan:** on relaunch, Live names the plug-in and offers to rescan or disable it. If it crashes twice, Live disables it, and it stays hidden until you reinstall it.

### Device panel and plug-in windows
- A plug-in with 64 or fewer parameters gets an automatic Live panel of sliders. One with more opens with an empty panel that you fill in Configure Mode.
- The **Unfold** button in the title bar shows or hides the panel. The **X-Y field** controls two parameters at once.
- **Show/Hide Plug-In Window** opens the plug-in's own GUI. It stays in sync with the Live panel.
- **CMD+ALT+P** (**View > Show/Hide Plug-In Windows**) toggles the open windows. It only works for windows already opened, or when Auto-Open is on.
- Options in **Settings > Plug-Ins**:
  - **Auto-Open Plug-In Windows**: the GUI opens when you load the plug-in.
  - **Multiple Plug-In Windows**: keeps several windows open. With it off, **CMD+click** to keep earlier windows open.
  - **Auto-Hide Plug-In Windows**: shows only the selected track's windows.

### Configure Mode: exposing parameters for automation and mapping
- Click **Configure** in the device header, then click a control in the plug-in GUI to add it. Some plug-ins register a control only after its value changes.
- Drag entries to reorder them. Press **Delete** to remove one; Live warns you if it has automation, envelopes or mappings.
- Gotchas:
  - Parameters that a plug-in does not publish can never be added.
  - For plug-ins with no GUI, entries can be reordered but not deleted.
- The configuration is saved per instance, in the Set. To reuse it, save the plug-in inside a **Rack** in the User Library, or save the configuration as the device **default**.
- Shortcuts that skip Configure Mode:
  - **Touch a control in the GUI.** It appears temporarily in the automation, clip-envelope and X-Y choosers. Edit its automation or envelope, or select it in a chooser, to keep it.
  - **Record automation.** Moving GUI controls while recording writes automation and adds those parameters when recording stops.
  - **Map while in a mapping mode.** In MIDI, key or Macro mapping mode, touching a GUI control adds it and selects it, ready to map.

### Sidechain
- Plug-ins that support sidechaining show controls on the device's left side. The choosers pick any internal routing point as the trigger.
- **Gain** sets only the level that drives the trigger. The sidechain signal is never heard in the mix.
- **Mix:** 100% means only the sidechain triggers the plug-in. 0% effectively bypasses it.
- **Mute** plays only the plug-in output.

### Multi-output and multi-input plug-ins
- Select the plug-in in other tracks' input/output routing choosers.

### VST presets and banks
- Each VST **instance** owns a fixed-size bank, which you pick from with the chooser under the title bar. Edits go straight into the selected preset. They are not shared across instances or Sets.
- To rename a preset, select the title bar, choose **Edit > Rename Plug-In Preset** and press Enter.
- The **Load/Save Preset or Bank** buttons import and export files. When saving, choose the **VST Preset** or **VST Bank** format.

### Audio Units specifics
- Mode choosers, such as reverb quality, are only in the plug-in's own window.
- Some AU presets are read-only and cannot be moved in the browser.
- They are stored as `.aupreset` files in `~/Library/Audio/Presets/<Manufacturer>/<Plug-in>`.

## Chapter 25: Instrument, Drum and Effect Racks

### What Racks are for
- Racks add parallel chains and up to 16 Macros to a device chain. Use them for layered synths, parallel processing, splits and velocity layers, live preset switching, or to hide a complex chain behind a few knobs. Wrapping a single device in a Rack still pays off: Macros can link several of its parameters.
- Instrument and Effect Racks feed the **same input to every chain** and sum the outputs. A Drum Rack chain receives **only its assigned note**.
- A Rack acts as one device. Racks nest to any depth (brackets inside brackets).

### Types and rules
- **MIDI Effect Rack**: MIDI effects, MIDI tracks only.
- **Audio Effect Rack**: audio effects. Audio tracks, or MIDI tracks after the instrument.
- **Instrument Rack**: devices must run MIDI effects → instrument → audio effects.
- **Drum Rack**: same order, plus up to **6 return chains**.

### Creating and organizing
- Drag a generic Rack preset from the browser onto a track, or select device title bars and right-click > **Group** (CMD+G) / **Group to Drum Rack**. Grouping again, or grouping chains, makes a nested Rack.
- **Ungroup**: select the Rack's own title bar > Edit/context menu (CMD+SHIFT+G).
- Select the Rack's title bar, not a device's, to move, copy, delete or rename (CMD+R) the whole Rack. To fold it, double-click the title bar or hide all its views.
- Right-click the Device View selector for a tree of all devices on the track and jump straight to one.

### Chain List
- Drop presets, devices or chains below the list to add chains. Chains drag freely between Racks and tracks. Hover over a track while dragging to open its Device View.
- The selected chain is the one shown in the Devices view. **Up/Down arrows** flip through chains. Multi-select works for copying and regrouping.
- Each chain has an activator, Solo, Hot-Swap, Volume and Pan (no Volume/Pan in MIDI Racks). The context menu sets color and info text. Chains can be saved as presets.
- **Auto Select** highlights the chains that are processing right now, which helps debug zones.

### Zones (Instrument/Effect Racks)
- A note must pass key, then velocity, then chain select zone to reach a chain. Show the editors with **Key / Vel / Chain** above the Chain List. Audio Effect Racks have only Chain Select. Drum Racks have no zones.
- Drag the lower bar to move or resize a zone. The thin top bar sets **fade ranges**.
- **Key**: keyboard splits. **Velocity** (1-127): velocity layers. Their fades scale note velocity, which crossfades layers.
- **Chain Select** (0-127, draggable **Chain selector**): only chains whose zone covers the selector value sound.
  - It filters notes only. To also gate CCs, enable **Chain Selector Filters MIDI Ctrl** (Chain Select ruler context menu).
  - In audio-output Racks, fades scale chain **output volume**. **Gotcha:** leaving a zone that has a fade mutes the chain, tails included. Without a fade, reverb and delay tails ring out.
- **Preset bank**: new zones are length 1 at value 0. Put chains at 0, 1, 2, 3 and MIDI-map the Chain selector to an encoder to switch setups.
- **Morphing**: lengthen the zones so their fades overlap, keeping one exclusive value per chain. Wider fades give smoother transitions.

### Drum Racks
- **Receive**: the note that triggers the chain (number, name, GM drum). **Play**: the note sent on to the devices. **Choke**: 16 groups that cut each other off (closed hat chokes open hat). With **All Notes** Receive, Play and Choke are disabled. **Preview** test-fires the chain.
- **Sends** are post-fader and appear only once returns exist. Return **Audio To** goes to the Rack output or straight to the Set's return tracks.

#### Pad View
- 128 pads, one per note. Arrow keys scroll by 16, **CMD+arrow** by one row.
- Sample on an empty pad → new chain with Simpler. Effect on the same pad → placed after the Simpler. A new sample replaces only Simpler and sample; effects stay.
- Several samples dropped → mapped chromatically upward. **CMD-drag** → layered on one pad in a nested Instrument Rack.
- Pad onto pad **swaps note mappings**, so existing clips play the swapped sounds. **CMD-drag** a pad onto another to layer both in a nested Instrument Rack.
- In Hot-Swap mode, **D** switches the target between the Drum Rack and the last selected pad.
- A pad is a **note**: it covers every chain at any depth that receives that note. A **"Multi"** pad's mute, solo, preview and delete act on all its chains. Hot-Swap and rename are disabled.
- Natively supported pad controllers (Settings > Link, Tempo & MIDI) follow the visible pad bank.

### Macro Controls
- 8 shown by default, 16 max. The +/- view buttons set the visible count, which is saved in the Set.
- **Map**: click the Rack's **Map** button, click a parameter, click a Macro's Map button, repeat, then click Map again to exit.
- **Min/Max** in the Mapping Browser set the range. Min above Max inverts it, as does right-click > **Invert Range**. You can edit mappings only in Map mode.
- Mapped parameters are locked to the Macro, but clip envelopes still modulate them.
- A Macro with one target takes that parameter's name and units. With several targets it shows "Macro N" and 0-127, unless all targets share unit type and range. Rename and recolor from the Edit or context menu.

#### Randomize
- **Rand** in the Rack title bar randomizes all mapped Macros.
- Right-click a Macro > **Exclude Macro from Randomization** to protect it. Volume Macros in Instrument Rack presets are excluded by default.

#### Macro Variations
- Variations are snapshots of all Macro values, for sound-design states, mix A/B, or builds and drops. Open them with the Show/Hide Macro Variations selector.
- **New** stores a snapshot ("Variation 1"...). **Launch** (right) recalls it, **Overwrite** (left) replaces it. Rename, duplicate or delete from the Edit or context menu.
- Right-click a Macro > **Exclude Macro From Variations** to keep it from changing.

### Mixing with Racks
- Multi-chain Instrument and Drum Racks unfold into the **Session mixer** via the track title-bar button. Chains appear as strips without clip slots and stay in sync with the chain list.
- A mixer change on multi-selected chains applies to all of them, but **only in the Session mixer**, not the chain list.

### Extracting chains
- Drag chains out of the chain list or the mixer into other tracks or Racks. Drum returns dragged to the mixer become return tracks.
- **Drum chain from the mixer** → new track with its devices **and its MIDI notes** (e.g., split the snare out of a drum loop). Dragging from the **chain list** moves only the devices.
