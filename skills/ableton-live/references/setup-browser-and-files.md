# Setup, Browser, Files and Sets

Distilled from the Ableton Live 12 Reference Manual. Keys are macOS (CMD, ALT/OPTION, SHIFT, CTRL).

## Contents

- Chapter 2: First Steps (Installation, Learning Tools, Settings)
- Chapter 4: Working with the Browser
- Chapter 5: Managing Files and Sets

## Chapter 2: First Steps (Installation, Learning Tools, Settings)

### Installation and Authorization
- Download the installer from your ableton.com User Account, install, then authorize.
- Each license has **two authorizations**: two computers, but only one in use at a time.
- Manage authorization, auto-updates, and usage data in **Settings > Licenses & Updates**.

### Learn View (built-in lessons)
- Video-plus-text lessons grouped in modules. New modules arrive online without a Live update.
- Opens by default on first launch. Close with the X (upper left); reopen via **Help** menu or **CMD+ALT+7**.
- Remembers the last page and video position until you quit Live.
- Filter lessons by topic; **Complete Lesson** adds a check mark. Go home with **< Lessons** or the Home button (upper right).
- **Picture-in-picture** (button right of the progress bar): resizable, ±15 s skip, and **stays on top of all apps**, so you can follow along while working. Opening it closes Learn View; **Learn View →** in the PiP window brings Live forward and reopens it.
- **Requires internet.** After a dropped connection, press **Reload**.

### Info View (context help and notes)
- Shows the name and function of whatever is under the mouse -- the quickest way to identify an unfamiliar control.
- Toggle with the **?** key or the button in the window's bottom-left corner.
- **Custom notes**: right-click a track, clip, device, etc. > **Edit Info Text**, then type in the Info View. Saved in the Set and shown on hover. Good for mix reminders or documenting racks.

### Other Resources
- Read the **Live Concepts** chapter first; the rest of the manual is deeper reference.
- Free browser sites **Learning Music** and **Learning Synths** teach music and synthesis basics.

### Settings (formerly "Preferences")
Open with **CMD+,** or **Live menu > Settings**.

- **Display & Input**
  - UI language; zoom for main, second, and Settings windows (Settings zoom applies on mouse release).
  - **Outline View in Focus** borders the focused view; scroll bar style; **Follow** behavior for Arrangement and clips; show/hide UI labels.
  - Keyboard: Tab moves focus, continuous Tab within a section, **arrow keys move clips**.
  - **Pen Tablet Mode**, permanent scrub areas, **pitch-locked drawing** for MIDI notes.
  - Restore dismissed "Don't Show Again" dialogs.
- **Theme & Colors**
  - Theme; light, dark, or follow macOS; warm/cool/neutral tone; high contrast.
  - Grid-line opacity, brightness, color intensity, hue.
  - Auto-assign track colors or one default color; **Reduced Automatic Colors** shrinks the palette. New clips get random colors or the track color.
- **Audio**
  - Interface inputs/outputs, sample rate, latency, and a calibration test section.
  - macOS: any CoreAudio device; other drivers via **Driver Type**.
  - **Use System Device** (output chooser) makes Live follow the output selected in macOS Sound settings -- handy when switching between headphones and an interface.
- **Link**: **Link** syncs tempo across devices on the local network; **Link Audio** streams audio between compatible devices over the network with no extra hardware or manual latency compensation.
- **Tempo & MIDI**: external sync via **Tempo Follower** or MIDI clock; resync hardware that drifts from Live's MIDI clock; MIDI note input/output; remote control of the UI.
- **File & Folder**
  - **Create Analysis Files** on audio import.
  - External **Sample Editor** for destructive edits.
  - **Temporary Folder**: recordings live here until the Set is saved.
  - **Max Application**: bundled or external Max. Max for Live ships with Suite and can also run in Standard.
  - **Decoding Cache** location for decoded compressed samples.
- **Library**: default locations for Packs and User Library; whether dependent files (samples) are **copied** when dragging clips, tracks, or presets to the browser; show/hide Cloud, Push, and Splice in Places.
- **Plug-Ins**: plug-in folder locations, which folders Live scans, and plug-in window behavior.
- **Record, Warp & Launch**: file type for new recordings, default Warp and Fade options, and clip/scene launch, selection, and recording defaults.

### Gotchas
- Unsaved recordings sit in the Temporary Folder, so save the Set to move them into the project.

## Chapter 4: Working with the Browser

The browser is where you find and load everything: Core Library, Packs, presets, samples, devices, plug-ins, and your own folders. It also reaches Splice, Ableton Cloud, and Push 3. Workflow: pick a sidebar label (Collections / Library / Places), then search or filter, then preview and load.

### Layout
- Parts: sidebar, Back/Forward buttons, search field, Filter toggle and Filter View menu, tag filters, Results bar (Clear / Add Label), content pane, and the Preview tab.
- Dragging the browser's bottom edge closes the Info View and the Clip/Device View. **View > Full-Height Browser** gives full height and keeps them open.
- Use the **Content Options** menu (or right-click a column header) to add columns, show extensions, and show Pack sizes. Click a header to sort. Drag a header to reorder.

### Search
- Terms are AND-matched: "electric bass" needs both words.
- **CMD+F** switches to the **All** label and focuses search.
- Type `#Tag` (for example `#Drums`) to search by tag, with auto-complete.
- The field's **x** clears only the text. **Clear** in the Results bar also clears tags.
- Keyboard loop: CMD+F, type, Down arrow into results, Up/Down to audition, Esc to reset.
- History: **CMD+[** goes back, **CMD+]** goes forward. History includes searches.
- **Add Label** saves the current search or filter as a custom Library label. You can rename it or change its icon via right-click, and factory labels can be renamed too.
- Trick: give items a custom tag, then save a search for that tag as a label. This makes a curated folder.

### Filters and tags
- **CMD+click** selects multiple tags within one group.
- Each label remembers its own visible groups and filter state. Choose groups in the Filter View menu, right-click a group to hide it, or use **Reset Filter Groups to Default**.
- Factory content is fully tagged. Third-party webshop Packs only use Sounds tags. Factory tags cannot be removed, but you can add tags to factory items.
- **Auto Tags:** Live analyzes user samples up to 60 s in the background and gives each a best-match tag. Toggle with **Enable Auto Tags** in the Filter View menu. In the Tag Editor you can remove an auto tag or convert it to a user tag.
- VST3 plug-ins are auto-tagged from their sub-category metadata.

**Tag Editor** (Filter View menu)
- Tick boxes to assign tags. **SHIFT+select** items to tag them in bulk.
- **Add Tag…** adds a tag to a group. **Add Group…** makes a custom group, which shows in the Filter View once one of its tags is used. Good for field recordings or vocal chops.
- Right-click a tag > **Add Subtag in…** to nest tags. Not possible in the Creator group.
- Default groups and tags cannot be edited.

**Quick Tags** (on by default)
- **Add…** with auto-complete assigns a tag. Type a new name and press Enter at "Create new tag…", then pick a parent tag or group.
- In a multi-selection, an asterisk marks tags that not all items share.

### Collections
- Seven color labels hold any mix of item types, folders included.
- Select items and press **1–7** to assign a color, or **0** to clear. Works on multi-selections. The pane shows at most 3 colors per item.
- Rename with **CMD+R**. To hide labels: hover the header > **Edit** > Show/Hide > **Done**. A hidden color shows again once you assign it.

### Library labels
- **All**: devices, then files.
- **Sounds**: instrument presets by sound type.
- **Drums**: drum devices, Drum Racks, hits, loops.
- **Instruments / Audio Effects / MIDI Effects**: organized by device, not by sound.
- Also **Modulators**, **Max for Live**, **Plug-Ins** (VST/AU), **Clips**, **Samples**, **Grooves**, **Templates**, and **Tunings** (.ascl/.scl).
- Hide labels with the **Edit** button next to the header.

### Places
**Packs**
- Sections: Core Library, installed Packs, Updates, Available Packs (owned, not installed).
- The download icon becomes a pause icon with yellow progress. Multi-select to batch download or pause. When done, click **Install**.
- Delete with the **Delete** key; the Pack returns to Available.
- Show Pack sizes in Content Options before downloading. Hide downloadable Packs in Library Settings.
- Pack Info: right-click > Show Pack Info, or **Help > Pack Overview**. The Core Library has none.

**Current Project**
- Shows the open Set's tracks, clips, devices, returns, and grooves.
- After two saves, a **Backup** folder keeps the last **10** saves, timestamped, so you can recover an overwritten Set. Unsaved Sets have none.
- Right-click > Show in Finder.

**User Folders**
- Drag a folder from Finder into Places, or use **Add Folder…**. Live indexes it without moving it.
- A moved or renamed folder, or a folder on an unplugged drive, shows grayed out. Fix it with **Locate Folder** or **Remove from Sidebar**.
- **Add specific content folders, not whole drives.** Large trees slow indexing and may re-index every launch.

Splice, Cloud, and Push labels can each be hidden in **Settings > Library**.

**Splice** (needs internet)
- You can browse and preview without an account. To load, save, or use Search with Sound, log in by matching a device code in your web browser.
- Filters: instrument, genre, key, tempo, one-shot/loop. Sort by Popular, Relevant, Recent, or Random. Free accounts are limited to the "Included" set of about 2,500 samples.
- Inside a category (Instruments / Genres / Cinematic FX), search only covers that category.
- **Search with Sound:** drag a clip onto the drop area, or click it with a time selection active. Returns 50 matching samples.
- Preview settings at the bottom of the pane:
  - Loops sync to Set tempo; switch off Timestretch under **1x BPM** for the original tempo.
  - One-shots loop; click **1 BAR** to stop looping.
  - Transpose to a key, sync to Live's scale, set loudness.
- Load by dragging onto a track or into Simpler/Sampler/Drum Rack/Impulse, or double-click / Enter in Session View. Loading licenses the sample.
- **Gotcha:** Splice clips are forced to **Complex** warp mode, whatever the default.
- Download location (Library Settings): User Library/Samples/Splice (default), Current Project/Samples/Splice, or a custom folder.

**Ableton Cloud**
- Up to 8 Sets from **Move/Note**. Activate with Cloud label > Sign In.
- Sync is one-way into Live. After editing a synced Set, use **File > Collect All and Save**.
- Its samples sit in User Library/ABL Assets. If they show as missing, connect the external drive that holds your User Library.

**Push 3 Standalone**
- Same Wi-Fi network. Click the Push label > **Connect**, then enter the 6-digit code Push shows.
- To refresh, switch labels and back. Unpair with right-click > Disconnect.
- Before sending a Set back to Push: use native devices only, freeze plug-in tracks, and collect samples.

### User Library
- macOS default: `~/Music/Ableton/User Library`. Change it under **Location of User Library** in Library Settings. Self-contained, so easy to back up or move.
- Folders: Clips (drag a clip in to save it), Defaults, Grooves, Presets, Samples, Templates (including the default Set), Chord Banks (Stacks MIDI Tool), and ABL Assets.
- With **Collect Files on Export = Always** (the default), referenced samples are saved with clips and presets.
- Audit with **File > Manage Files > Manage User Library**.

### Navigating and previewing
- Up/Down, mouse wheel, or CMD+ALT+drag scrolls. Left/Right opens and closes folders and switches panes. CMD while opening a folder keeps other folders open.
- With the **Preview** toggle on, selecting an item auditions it. Without it, press **SHIFT+Enter** or **Right arrow**.
- Click the waveform to scrub. You cannot scrub Warp-off clips or in Raw mode.
- **Raw off** (default): previews tempo-synced and looped, starting on the next bar. **Raw on**: original tempo, unlooped.
- Preview level: the **Preview/Cue Volume** knob on the Main track. For headphone cueing you need 4+ outputs (see Mixing chapter).

### Loading into a Set
- Drag onto a track. Drop in empty space right of Session tracks, or below Arrangement tracks, to create a new track.
- Double-click or **Enter** loads onto the selected track. A sample goes into **Simpler** on a MIDI track, or into a clip slot on an audio track.
- You can also drag in from Finder.

## Chapter 5: Managing Files and Sets

### Samples and analysis files
- Native formats: WAV, AIFF, AIFF-C, FLAC, OGG Vorbis, at any length, rate, or bit depth. MP3 and M4A (Mac) import too. Samples stream from disk, so too many large files at once can cause disk overload.
- Compressed files are decoded into the Decoding Cache, which cleans itself up. Settings > File & Folder sets Minimum Free Space and Maximum Cache Size, and **Cleanup** purges files the open Set doesn't use.
- **.asd** files sit next to the sample and hold warp/tempo analysis plus waveform data. A checkmark on a browser icon means one exists. Long samples stay grayed out and can't play until analysis finishes.
- Settings > File & Folder > Create Analysis Files = Off: Live reanalyzes on every load.
- **Save Default Clip** (button in the Clip View title bar) stores warp markers, gain, and pitch in the .asd. Future imports of that sample use them, which keeps warping consistent across projects. Clips already in Sets don't change.

### Export Audio/Video (CMD+SHIFT+R)
- **Rendered Track**:
  - Main: what you hear.
  - All Individual Tracks: equal-length stems for every track, including groups, returns, and Main.
  - Selected Tracks Only: select the tracks *before* opening the dialog.
  - A single track.
- MIDI tracks with no devices are skipped. MIDI tracks with effects but no instrument render as silence.
- Make an Arrangement time selection first to pre-fill Render Start/Length.
- **Gotcha:** the render captures what would actually play. Active Session clips override the Arrangement on their tracks.
- **Include Return and Main Effects**: prints the returns and Main FX into stems. Use it for remix and performance stems.
- **Render as Loop**: two passes that wrap the reverb/delay tail onto the start, giving a seamless loop at the same length.
- **Normalize** sets the peak to 0 dBFS. Also available: Convert to Mono, and Create Analysis File (writes an .asd).
- **Sample Rate**: rates below the Set's rate render at the Set's rate, then downsample with SoX (clean but slower).
- **PCM**: WAV/AIFF/FLAC, 16/24/32-bit.
- **Dither** (below 32-bit): Triangular is the default and safest choice. Rectangular adds less noise but more quantization error. POW-r 1-3 shape noise toward the high end.
  - Rule: dither only once. Send 32-bit undithered to mixing or mastering, and use POW-r only on the final master.
- **MP3**: CBR 320 only. It adds leading silence, so send WAVs when alignment matters.
- **Video**: Create Video requires video in the Arrangement and a PCM export. Choose an encoder and its settings.
- **Real-time rendering** happens automatically when External Audio Effect or External Instrument is in the path.
  - A 10 s wait lets hardware tails die out (edit, Restart, or Skip).
  - **Auto-Restart on drop-outs** re-renders after glitches. If it keeps restarting, close CPU-hungry apps.

### MIDI files
- Imports embed the data and keep no link to the file. Drag from the browser, or use Create > Import MIDI File…. It lands at the Insert Marker in Arrangement, or in the selected slot in Session.
- **File > Export MIDI Clip** writes a Standard MIDI File.

### Live Clips (.alc)
- Drag a clip into Current Project or a user folder in the browser, then name it and press Enter. It saves clip settings, envelopes, **and the track's devices**, while referencing audio rather than copying it.
- To bring back the device chain, drop the clip on an empty track or in the empty area with no tracks. On an occupied track you get the clip only, which is useful for laying a bassline onto an existing synth.
- Use Live Clips for multiple variations of one sample. An .asd stores just one set of defaults.

### Live Sets (.als)
- **Save Live Set As** switches you to the new file. **Save a Copy** leaves you on the current one.
- **Undo History**: View menu or CMD+OPTION+Z. Click an entry to jump there, and later steps gray out and can be reapplied. It's lost when you close the Set.
- Sets from older major versions must be re-saved with Save As.
- **Merge**: drag a Set from the browser onto a track title bar or the drop area to import all tracks (not returns), with clips, devices, and automation.
- Unfold a Set in the browser to pick out individual tracks, Groups, grooves, the **Devices** chain, or single Session clips. Any old Set becomes a sound library.
- **Session clips to a new Set**: multi-select clips (SHIFT or OPTION), then drag them to a browser folder.
- **Default Set**: File > Save Live Set As Default Set… The current Set becomes the starting state for every new Set, so use it for I/O routing, default EQ/compressor chains, and key/MIDI maps. Any template can also be made the default with **Set Default Live Set**.
- **Templates**: File > Save Live Set As Template… saves to User Library/Templates (shown under Templates in the browser). Templates open as `Untitled.als`.

### Projects
- Saving a Set outside an existing Project **creates a new Project folder automatically**. The current Project shows in the title bar.
- Save versions of one song into the same Project. They share `Samples/Recorded`, so samples are stored once.
- Save into an existing Project only when the Set is related to it.
- **Gotcha:** Save As to a new location makes a new Project that still references the old Project's samples. Collect All and Save afterward.
- Don't reshuffle files in Finder without relinking (see the end of this file).
- Presets save to the current Project by default. For reuse elsewhere, drag the device title bar to the User Library or another folder.

### File Manager
Open it with File > Manage Files or View > File Manager. Choose a scope: Manage Set, Manage Project, or Manage User Library. You can also right-click a Project folder in the browser and choose Manage Project. **Always finish with Collect and Save.**

- **View Files** (Manage Set) lists every reference and where it lives.
  - Drop a browser file onto an entry to replace that sample **everywhere** in the Set. Warp markers are kept if the new sample is the same length or longer.
  - **Hot-Swap** browses alternatives.
  - **Edit** opens the sample in the external editor set in Settings. The sample stays offline while Edit is engaged.
- **Missing files** show as a Status Bar warning and "Offline" clips that play silence. Click the warning to go straight to Locate.
  - Manual fix: drag the right file onto the missing entry. Live doesn't verify it.
  - Automatic Search > Go. Expand it to choose Search Folder, Search Project, Search Library, and Fully Rescan Folders. With several candidates, use Hot-Swap and audition while playing.
- **Collect All and Save** (File menu) copies external files into the Project's `Samples/` and `Presets/`. External means anything outside the Project folder: Packs, User Library, other Projects, loose folders.
  - Rule of thumb: skip Packs and the User Library if you won't move or uninstall them, since multisamples bloat Projects.
- **Collect Files on Export** (Settings > Library) controls what happens when you drag clips, presets, or tracks into the browser: Always (default), Ask, or Never. It also applies to Save Preset when the preset has samples.
- **Unused Files** (Manage Project or Manage User Library): Show opens them in the browser to preview or delete. **Gotcha:** "unused" means only within this Project, so other Projects may still need the file. Collect first.
- **Create Pack** (Manage Project > Packing) archives the Project and all its Sets as a losslessly compressed .alp, up to ~50% smaller. **External files aren't included, so collect first.** Restore by double-clicking the .alp, dragging it into Live, or using File > Install Pack….

### Relinking after reorganizing a Project
1. Move files within the Project folder.
2. In the browser, right-click the Project and choose Manage Project, then Locate under Missing Samples.
3. In Automatic Search, enable Search Project and Fully Rescan Folders, then click Go.
4. Click Collect and Save.
