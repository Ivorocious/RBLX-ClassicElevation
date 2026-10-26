# City Run V3 painted asset kit

Final Stage 1: **V3_KIT_05 + V3_DISTRICT_ADDON_01**. V1/V2 and gameplay remain unchanged.

Open [CityRun_V3_Stage1.blend](CityRun_V3_Stage1.blend) for all 69 editable assets. [stage1-manifest.json](stage1-manifest.json) lists verified individual exports; [MOUNTING.md](MOUNTING.md) explains contacts. Final native reviews and handoff: [Stage 1 report](../../../docs/CITY_RUN_V3_ASSET_KIT.md).

## Contents

- 69 unique reusable meshes; 22,746 triangles across one copy of the library.
- Largest asset: 1,904 triangles.
- One opaque 2048 x 1024 painted atlas and one shared material.
- Editable .blend, two uploaded FBX packages, per-asset FBXs, deterministic generators, manifest and mounting metadata.
- Atlas RGBA8 + full mip-chain estimate: 10.67 MiB; actual Roblox memory unmeasured. roblox_import.json confirms one shared image ID for all 69 meshes.

## Rebuild

Run from the project root using Blender 5.2 and Python with Pillow:

```powershell
python assets/city_run/v3/paint_atlas.py
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python assets/city_run/v3/build_asset_kit.py
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python assets/city_run/v3/render_gallery.py
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python assets/city_run/v3/audit_assets.py
python assets/city_run/v3/write_catalog.py
```

The refine_*.py files are historical one-time authoring patches, not rebuild steps.

## Editing and import

- Each mesh lives in its own named Blender collection; use Edit Mode and linked-piece selection for fine adjustments.
- Source uses Z-up; FBX exports Y-up. Kit05 cloud import was enlarged about 24.236689 times; import_review05.luau restores manifest dimensions and source editing pivots. All 64 meshes passed the native check.
- Origins are bottom-center; mounting sockets and recommended flags are in manifest.json.
- Import each of the two packages once and clone normalized canonical meshes. Importing every FBX separately could duplicate texture IDs.
- Texture is packed into .blend and embedded in FBX; the editable generator and external PNG are included.
- Renders include temporary gallery floors, scale markers and fit fixtures; those are excluded from exports.
- Fit images are assembly studies, not the actual map or proof of race clearance.
- Reuse runtime-owned cable/winch assemblies, colliders and hazard controllers; vehicle skins require explicit axis/pivot checks.

After building the base, run `build_district_addon.py`, `audit_district_addon.py`, `package_stage1.py` and `audit_stage1_package.py` with background Blender. Package source lives in `CityRun_V3_Stage1.blend`; the two upload FBXs are preserved separately. The table below lists the 64 base assets; the [add-on catalog](district_addon01/README.md) lists the remaining five.

## Base catalog

| Asset | Family | Tier | Roblox size X/Y/Z | Triangles |
|---|---|---|---|---:|
| V3_Ochre_Narrow | Architecture | Mid | 17.10 / 48.00 / 17.10 | 944 |
| V3_Coral_Wide | Architecture | Mid | 25.10 / 48.00 / 21.10 | 1224 |
| V3_Sage_Wide | Architecture | Mid | 25.10 / 60.00 / 21.10 | 1552 |
| V3_Cream_Tall | Architecture | Mid | 25.10 / 72.00 / 25.10 | 1904 |
| V3_Blue_Narrow | Architecture | Mid | 17.10 / 60.00 / 21.10 | 1180 |
| V3_Brick_Broad | Architecture | Mid | 33.10 / 48.00 / 25.10 | 1520 |
| V3_Terminal_Wing | Architecture | Mid | 25.10 / 24.00 / 21.10 | 568 |
| V3_FlatRoof_Narrow | Roofs | Mid | 17.00 / 2.50 / 17.00 | 220 |
| V3_FlatRoof_Wide | Roofs | Mid | 25.00 / 2.50 / 21.00 | 220 |
| V3_FlatRoof_Broad | Roofs | Mid | 33.00 / 2.50 / 25.00 | 220 |
| V3_GableRoof_Narrow | Roofs | Mid | 17.60 / 5.20 / 17.60 | 120 |
| V3_GableRoof_Wide | Roofs | Mid | 25.60 / 5.20 / 21.60 | 120 |
| V3_SteppedRoof | Roofs | Mid | 24.00 / 3.10 / 20.00 | 132 |
| V3_Sign_Market | Street | Close | 12.00 / 4.00 / 0.58 | 14 |
| V3_Sign_Depot | Street | Close | 12.00 / 4.00 / 0.58 | 14 |
| V3_Sign_Terminal | Street | Close | 12.00 / 4.00 / 0.58 | 14 |
| V3_Sign_Courtyard | Street | Close | 12.00 / 4.00 / 0.58 | 14 |
| V3_Awning_12 | Street | Close | 12.00 / 2.98 / 8.00 | 72 |
| V3_Awning_24 | Street | Close | 24.00 / 2.98 / 8.00 | 72 |
| V3_MarketStall | Street | Close | 9.00 / 9.30 / 6.00 | 60 |
| V3_Crate | Street | Close | 4.00 / 4.00 / 4.19 | 24 |
| V3_Bench | Street | Close | 10.00 / 4.10 / 3.05 | 48 |
| V3_Planter | Street | Close | 8.00 / 5.00 / 3.00 | 120 |
| V3_Tree | Street | Close | 9.90 / 15.25 / 6.40 | 168 |
| V3_Lamp | Street | Close | 3.15 / 11.50 / 1.70 | 92 |
| V3_Ledge_Short | Openings | Close | 8.00 / 2.26 / 3.00 | 36 |
| V3_Ledge_Long | Openings | Close | 16.00 / 2.26 / 3.00 | 36 |
| V3_Balcony | Openings | Close | 12.00 / 4.34 / 5.00 | 84 |
| V3_FacadeStrip | Openings | Mid | 24.00 / 12.00 / 1.06 | 18 |
| V3_MuralPanel | Openings | Close | 24.00 / 12.00 / 1.06 | 14 |
| V3_Shopfront | Openings | Close | 16.00 / 12.00 / 2.50 | 26 |
| V3_ArchPortal | Landmarks | Close | 18.00 / 20.75 / 3.50 | 660 |
| V3_Arcade | Landmarks | Close | 28.00 / 13.00 / 4.00 | 1892 |
| V3_ClockTower | Landmarks | Close | 13.00 / 40.00 / 13.00 | 228 |
| V3_DepotCanopy | Industrial | Close | 26.00 / 11.35 / 14.00 | 120 |
| V3_ScaffoldBay | Industrial | Close | 10.30 / 12.00 / 10.30 | 216 |
| V3_CraneTruss | Industrial | Mid | 24.17 / 4.30 / 4.30 | 336 |
| V3_IBeam | Industrial | Close | 16.00 / 2.00 / 2.00 | 36 |
| V3_SignalGantry | Industrial | Close | 25.00 / 16.00 / 1.52 | 50 |
| V3_WaterTank | Industrial | Close | 8.40 / 13.00 / 8.40 | 224 |
| V3_Chimney | Roofs | Close | 4.80 / 6.30 / 4.80 | 88 |
| V3_Fence | Industrial | Close | 12.15 / 4.00 / 0.20 | 72 |
| V3_RailBed | Industrial | Mid | 10.00 / 1.26 / 24.00 | 132 |
| V3_WreckingBallSkin | Vehicles | Close | 10.00 / 12.03 / 10.00 | 260 |
| V3_MarketCar | Vehicles | Close | 6.74 / 5.00 / 12.27 | 132 |
| V3_DeliveryVan | Vehicles | Close | 6.74 / 7.00 / 14.27 | 132 |
| V3_TrainCar | Vehicles | Close | 8.62 / 9.00 / 29.60 | 164 |
| V3_Skyline_1 | Skyline | Distant | 21.00 / 52.00 / 17.00 | 60 |
| V3_Skyline_2 | Skyline | Distant | 29.00 / 70.00 / 19.00 | 88 |
| V3_Skyline_3 | Skyline | Distant | 17.00 / 84.50 / 17.00 | 80 |
| V3_Skyline_4 | Skyline | Distant | 37.00 / 60.00 / 21.00 | 92 |
| V3_LoggiaResidence | Architecture | Mid | 31.00 / 48.00 / 21.30 | 916 |
| V3_CourtyardGallery | Architecture | Mid | 25.00 / 48.00 / 21.30 | 916 |
| V3_ShopBase | Openings | Close | 25.00 / 10.50 / 21.00 | 30 |
| V3_GardenPortal | Landmarks | Close | 20.00 / 13.35 / 4.00 | 662 |
| V3_CourtyardFountain | Street | Close | 10.00 / 5.40 / 10.00 | 168 |
| V3_TerminalColonnade | Landmarks | Close | 24.00 / 13.25 / 3.00 | 572 |
| V3_MansardRoof | Roofs | Mid | 24.93 / 5.00 / 20.93 | 44 |
| V3_BarrelRoof | Roofs | Mid | 23.95 / 4.00 / 20.00 | 100 |
| V3_CornerCafe | Architecture | Close | 24.65 / 36.00 / 24.47 | 836 |
| V3_ServiceRear | Openings | Mid | 24.00 / 48.00 / 3.29 | 176 |
| V3_UnevenShopRow | Street | Close | 30.20 / 15.35 / 11.20 | 228 |
| V3_SkylineCluster | Skyline | Distant | 37.70 / 68.00 / 19.70 | 102 |
| V3_AtelierHall | Architecture | Mid | 29.00 / 53.85 / 23.30 | 728 |

## Validation boundary

Local kit05 geometry and FBX round-trip checks pass. Approved kit05 upload and native verification are recorded in roblox_import.json and docs/artifacts/city-run/v3/studio07/import-audit.json: 64 meshes, one shared texture, zero dimension/pivot/flag errors. Course assembly, mobile benchmarks and 20-player validation remain outstanding.
