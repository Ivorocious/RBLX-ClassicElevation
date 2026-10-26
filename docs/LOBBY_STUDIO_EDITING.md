# Fine-tuning the lobby in Roblox Studio

Stop Play before editing. Changes made during Play disappear when it stops.

## Select and move a complete object

In Explorer, open **Workspace → Lobby → Editable → 01_Lower**. Its 44 named models include boards, benches, trees, planters, lamps, supports, banners, walls, guards, stairs, floors and the B10 hall finishes.

Select the **Model** in Explorer, then use Studio's normal Move, Rotate or Scale tools. Each object contains its visible meshes and its invisible collision. Benches also contain their seats; lamps and boards contain their light sources. Moving the complete model keeps those pieces together.

Useful starting points:

| Model | What it edits |
| --- | --- |
| Lower_Board_Wins / Lower_Board_Times | Each complete board and its columns/light |
| Bench_0_-29 / Bench_0_29 | Each bench, collision and two working seats |
| Gardens_Tree_07 / Gardens_Tree_08 | Each lower tree and planter |
| Planter_0_0 / Planter_0_1 | Each small planted pot |
| Lower_Slab_01 | Lower floor, paving, rim and floor collision |
| Stairs_Stair_01 | Complete central staircase, guards and lanterns |
| Guardrails_Rail_01 | Front guard |
| SideGuard_0_-1 / SideGuard_0_1 | Side guards |
| Lower_RearWall | Rear wall and its trim |
| Lower_GrandPillar_-1 / 1 | Each fluted stair pillar, base, capital and collision |
| Lower_SocialBench_-1 / 1 | Each inward-facing edge bench with two seats |
| Lower_SocialGarden_-1 / 1 | Each grouped edge planter arrangement |
| Lower_FloorInlay_-1 / 1 | Each flat rectangular social bay inlay |
| Lower_GatheringCrest / Lower_RouteInlays | Central compass and Practice floor arrows |
| Lower_RecordsCrest | Shallow decorative panel below Records |
| Lower_Ceiling_-29 / 0 / 29 | Each ceiling trim bay and its light |

Invisible collision and seat parts are locked to avoid accidental viewport selection. Select their parent model in Explorer to move the whole object. Visible meshes can be selected normally. Avoid moving or resizing only a visual mesh unless you also intend to adjust its collision separately.

Each of the eight Gardens_Tree models includes a locked **TreeTrunkCollider** above its planter. Move or scale the complete tree model so the trunk collider follows. Current and historical lobby recovery models are in the [local backup package](../backups/pre-phase-cleanup-2026-09-08/README.md).

## Other floors and barriers

The other Editable folders contain arrival, shop and podium architecture. Shared room assemblies are under 05_Architecture. The functional winner display is grouped in **Lobby → Podium**, including its monument geometry, display markers, names and avatars; move this complete model if needed.

The invisible barriers are named **Arrival_InvisibleBarrier_-1 / 1** and **Shops_InvisibleBarrier_-1 / 1** inside the matching floor folders. Their invisible Part is named InvisibleBarrier. The arrival barriers meet the moved walls behind the stairs; shop barriers cross the side walks just behind the trees. Keep their floor-to-ceiling coverage if you move them.

The spawn and spectator markers remain named service markers directly under Lobby. Moving decorative spawn-emblem geometry alone does not move the player spawn.

B10 adds **SideWallFinish_-1 / 1** under Editable/02_Arrival, fitted to the owner's manually positioned side walls. These separate decorative models have no collision; select both the wall and its finish when moving that whole assembly. **Podium/MonumentFinish** contains the new podium trim and follows the complete Podium model.

## Keep your edits

Save the Studio place after editing. LobbyService preserves the existing Workspace.Lobby when Play starts, so it does not rebuild over your manual adjustments. Keep a copy of the whole lobby before a large layout change.

The Blender source is the starting layout; it does not automatically receive manual Studio changes. Running the installer on a replacement model recreates the authored layout. Rojo saves and synchronizes scripts, while the saved Studio place retains your geometry edits.

After moving something, check its contact with the floor, walk around it, sit on moved benches and test any changed stair landing. Model-level movement, rotation and uniform scaling were checked on isolated copies of a board, bench, tree, staircase and floor. This does not validate every future manual edit.
