# MC_P1_BL02 bounded asset revision

Prepared for the owner's one remaining Phase 1 improvement/early optimization pass. BL01 files are preserved. This helper owns only BL02 `architecture.py`, `mechanisms.py`, this note and the read-only `check_library.py`. The lead owns composition, facade context, renders, exports/uploads, contacts, Studio integration and gameplay evidence. Daylight remains current; final night is deferred.

Both `build_library(collection)` APIs, all eighteen `MC_*` AssetKeys, zero local object origins, Z-up/front-minus-Y axes and main mounting dimensions are preserved. Materials use `MC_BL02_`. No scene setup, render/save/export or behavior happens when importing either module. No texture bake, external tool or new pipeline is introduced.

## Concrete appearance changes

- **Hero window:** replace fine circular brass rods with closed flat lead ribbons. The dark warm Lead RGB is 54/45/34. The two pointed lancets have broad contrasting surrounds, a strong center divider and crossbar, four legible diamonds rather than six very fine diamonds, and a broad four-lobed upper motif. The curved outer border remains. Tracery sits within the old mounting envelope, with fewer slices and no bevel on already shaped lead.
- **Glass:** five closed solid regions retain the original outer pointed profile and inset depth: alternating Amber/AmberLight lower regions plus AmberPale above the lancet crowns. These export as actual geometry/material colors. AmberLight is 232/170/72; AmberPale is 246/204/122; base Amber remains 191/106/28. Tiny 0.008-stud internal separations prevent coincident pane side faces from becoming nonmanifold during the established export cleanup. The center and lower horizontal separations sit behind broad lead. No transparent shells or shader-only pattern is used.
- **Masonry:** four broad course marks on each window jamb, six major radial joints on the stone arch and five shallow recessed shaft courses on each turret. These are combined into the existing asset meshes, with no per-brick runtime objects. The lead-owned main facade still needs its own restrained stone relief and supports.
- **Mechanisms:** one-segment bevel highlights on stone/rectangular relief; skip bevels on already shaped tracery, iron rail rods, weight metal, pulley rims and cage/core. Car arch curves use four samples per half rather than six; four tiny front/back corner badges are removed. Cage's eight tiny ornamental arch curves use three samples per half rather than five, with four-sided rods rather than five-sided rods. The main eight-sided cage, eight posts, main hoops, roof/base profiles and core profile remain. Pulley main rim sampling drops from forty to twenty-four, and the smaller hub from twenty-four to sixteen.

## Measured library triangles

Checked in installed Blender **5.2.1 LTS**, in a fresh isolated background process. Counts below evaluate modifiers and apply the **same** remove-doubles/dissolve-degenerate/recalculate-normals cleanup used by BL01 `build_sample.py`. They are one-copy library counts, not native placed totals or FPS measurements.

| Asset | BL01 | BL02 | Reduction |
| --- | ---: | ---: | ---: |
| MC_WindowFrame | 5,772 | 3,852 | 33.26% |
| MC_WindowTracery | 12,316 | 1,312 | 89.35% |
| MC_WindowGlass | 560 | 216 | 61.43% |
| MC_StoneArch | 2,788 | 2,100 | 24.68% |
| MC_TurretStone | 4,512 | 3,212 | 28.81% |
| MC_SlateSpire | 1,500 | 860 | 42.67% |
| MC_BalustradeStone | 1,080 | 440 | 59.26% |
| MC_BalustradeIron | 5,076 | 1,268 | 75.02% |
| MC_CarStone | 2,916 | 1,292 | 55.69% |
| MC_CarIronBrass | 8,088 | 936 | 88.43% |
| MC_WeightStone | 220 | 92 | 58.18% |
| MC_WeightIron | 1,352 | 168 | 87.57% |
| MC_PulleyIron | 2,608 | 496 | 80.98% |
| MC_PulleyBrass | 3,908 | 836 | 78.61% |
| MC_LanternCage | 6,788 | 1,220 | 82.03% |
| MC_LanternCore | 220 | 60 | 72.73% |
| MC_KillCasing | 3,076 | 1,364 | 55.66% |
| MC_KillRed | 216 | 88 | 59.26% |
| **One copy of each of eighteen edit units** | **62,996** | **19,812** | **68.55%** |

The eighteen keys still produce eighteen edit units. Matching placement counts would reduce their placed triangle contribution, but the lead must count the actual revised sample, including its separately improved facade/context. Nothing here establishes a target-device performance improvement.

## Mounting/contact differences to verify

The car's stone deck is still X ±7, Y ±6, Z -1 to 0; side rail top remains Z=3 with open transfer ends. Removing four decorative badges shrinks CarIronBrass's furthest Y extent from ±6.044335 to ±5.995. Main rail X extents remain ±6.995. The poses, rail posts and deck-contact authoring inputs are untouched.

The source cage still spans Z -3.5 to +3.5. Removing the cosmetic bevel changes its radial evaluated bound from ±1.997310 to ±2.000000, an increase of **0.002690 per horizontal side**. Core height remains Z -1.75 to +1.58, while its radial bound changes from ±1.446862 to ±1.450000, an increase of **0.003138 per side**. These are source units; multiply by the actual native instance scale when verifying clearances. Main cage/core profile coordinates and cage post positions are unchanged. The decorative little cage arches are slightly more faceted, so mesh contact on those thin bars must not be assumed identical. No touch/query flags, hidden hazard contacts, motion settings or controller code were edited. The lead must verify the newly imported visible cage/core contact and safe waits before carrying gameplay evidence forward.

Major frame bounds remain width 24 and depth 2.74; its beveled pointed tip differs by about 0.00145 in evaluated height. The stone arch retains rise 17/depth 4.24, with end-edge bevel differences around 0.00134. Turret and spire mounting bounds are unchanged. Glass retains X ±9.625 and Y 0.08 to 0.26; removing its bevel restores about 0.00813 at the existing source apex. New lead is narrower/deeper inside the prior decorative tracery bounds. None of these decorative edits authorize shifting tested landings, boarding contacts or waits.

## Checks and tradeoffs

Python compilation passed. `check_library.py` completed in a fresh Blender process with the original foreground scene left alone. It checks all eighteen matching keys, unchanged zero origins, the BL02 material prefix, finite vertices, zero boundary/nonmanifold edges, zero zero-area triangles and positive signed closed volume after the existing export cleanup. All revised meshes passed. This is geometry evidence; positive volume is a winding check, not a claim that every overlapping surface is optimal.

The reduced bevel work gives sharper edges and less rounded small metal detail. Twenty-four-sided pulley rims and simplified ornamental curves may show more facets very close to the camera. Broader lead and lighter amber areas should read better in daylight, but the lead's actual player-height render/native comparison is still required. No rendered, imported, gameplay, pacing, sound, mobile-device or twenty-real-racer acceptance is claimed here. A fresh independent integrated review remains required; this helper is the implementation author.

The read-only comparison can be rerun with:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python assets/moonlit_citadel/bl02/check_library.py
```

It prints a JSON comparison to stdout and writes no reports, assets, images or scene files. Both libraries are built in that isolated process only. The established export cleanup remains necessary for cosmetic pointed-tip bevel slivers; its tiny-edge fixes are included in the counts above.
