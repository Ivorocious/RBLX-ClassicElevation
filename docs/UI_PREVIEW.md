# UI preview in Studio Edit mode

Use **UI Labs** (free community plugin) to see every game screen without pressing Play. It draws the game's real screen modules with sample data, redraws when Rojo syncs a change, and can show a screen full size over the place.

## Set up (once)

1. Install UI Labs from the Creator Store: [UI-Labs (asset 14293316215)](https://create.roblox.com/store/asset/14293316215/UI-Labs). In Studio you can also search "UI Labs" in the Toolbox under Plugins. The official source and docs are at [github.com/PepeElToro41/ui-labs](https://github.com/PepeElToro41/ui-labs) and [ui-labs.luau.page](https://ui-labs.luau.page/).
2. Connect Rojo (`./tools/start_rojo.ps1`). The stories live in `src/ServerStorage/UIStories` and sync to `ServerStorage.UIStories`.

## Use

- Open UI Labs from the Plugins tab. The **Obby Tournament** storybook lists the stories in five folders: Animations, Arrival, Lobby, Race and Event.
- Pick a story. The **Controls** panel changes its sample data live, for example racer count, your place, a long course name, the lobby state or which shop tab is open.
- Every story has **Sky** (backdrop on or off), **Motion** (off shows each moment on its settled frame) and **Sound** (off by default; on plays the UI sounds).
- **View on Viewport** (side toolbar) moves the screen into Studio's main view at real size. Turn Sky off there to see the lobby or a course behind it. Use Studio's device emulator for phone sizes.
- Saving a change in the repository (synced by Rojo) redraws the open story.

Stories never call remotes, save data or add anything to the place. Real server timing, delivery handshakes and multiplayer still need Play.

## Animations

The **Animations** folder plays the motion, theatrics and transitions on a loop. A chip in the top-left corner names the step playing.

- **RaceDay**: the whole race day in order: vote and lock-in, next course delivery, 3-2-1-GO, racing, a checkpoint, the final stretch, the finish burst, the finish ticket, results and the event end.
- **ArrivalMoments**: the spotlight and wave moving between the two racers, then the confirmation card rising in.
- **LobbyEntrance**: the lobby HUD flying in after the arrival screen.
- **LobbyMoments**: YOU'RE IN! stamp, race-winner toast, dialog slide, shop pop, coins panel, the phase timer's last five seconds.
- **VoteMoments**: picking, changing your pick, LOCKED IN! and the urgent timer.
- **NextCourseDelivery**: the ticket dropping in and walking through its steps, including slow loading.
- **RaceHud**: the HUD sliding in at GO, passes, a checkpoint burst and the coin counter.
- **ResultsReveal** and **EventEndReveal**: the podium and event-end openings, replaying every **ReplayEvery** seconds (0 plays once).

The race moments in the Race folder (Countdown, Checkpoint, FinalStretch, Finish, TimesUp) also replay while Motion is on.

### Camera sequences need Play

Camera moves in the 3D world cannot run in a preview. Press Play and open **DEV TOOLS [F6]**:

- Arrival fly-in to the lobby: the **Arrival** test profiles, for example **First visit**, **Returning racer** or **Lobby entrance**.
- Grand Arcade arch screens: **Stage opening (local preview)** and **Stage next race (local preview)**.
- Course preview fly-in and the countdown: **Start event**, vote, and the next course is delivered with its preview.
- Finale camera: finish the event's five races (**End race → show results** speeds this up), then **Watch the finale** on the event end screen.

## Stories

| Folder | Story | Controls |
| --- | --- | --- |
| Animations | RaceDay, ArrivalMoments, LobbyEntrance, LobbyMoments, VoteMoments, NextCourseDelivery, RaceHud, ResultsReveal, EventEndReveal | Course, race number; ReplayEvery on the two reveals |
| Arrival | Choose, Creator, Confirm | Hover side, bonus claimed, look options, custom racer, save error |
| Lobby | Lobby | State (1 waiting, 2 joined, 3 up next, 4 racing now), course, coins |
| Lobby | Shop, Panels, RaceOptions | Styles tab; panel (Settings, Records, Coins) and record count; joined |
| Race | Vote, NextCourse | Course count, picked, locked, seconds left; race number, step, slow loading, failed |
| Race | Countdown, Racing, Checkpoint, FinalStretch, StillRacing, Finish, TimesUp, FinishTicket, UnfinishedTicket, Coins | Course, place, gap to best (moments replay while Motion is on) |
| Race | Watch, Practice, Coach | Name, place, loading; practice screen, departing; coach step |
| Event | Results, EventEnd | Racers, your place, DNF, long names, single race, course; race you won, long name, finale |

## Adding a story

Add a `Name.story.luau` module under `src/ServerStorage/UIStories/<Folder>/` that returns `StoryKit.Story(controls, build)`. `build(holder, values)` draws one state into `holder` with `StoryKit.Load("<ScreenModule>")` and may return a cleanup function. Plain values in `controls` (number, text, true/false) become controls. `StoryKit.luau` has the shared sample courses, names and race helpers; `StoryKit.Sequence` plays timed steps for animation stories, and `replay` in the story options adds ReplayEvery.

## Old UI Preview plugin

The earlier **Plugins → Classic Elevation → UI Preview** panel (`tools/ui-preview/`) is superseded by UI Labs and is no longer updated. It predates the overhaul screens. Its files are kept; you can disable it in Studio's plugin manager. Its earlier guide and check history are archived in [OLD_PLUGIN_GUIDE.md](artifacts/ui-preview/OLD_PLUGIN_GUIDE.md).
