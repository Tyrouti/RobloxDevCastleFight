# Castle Fight asset inventory

This maintained inventory summarizes the audit of 2026-11-10. It describes asset readiness separately from the implemented P23 gameplay. No new generation, import, rigging, or asset approval is authorized by this document.

## Registry and readiness

| Category | Count and status |
|---|---|
| Registry | 16 unique assets: six units, eight buildings, two historical castle slots |
| Concept images | 14 original PNGs: A/B pairs for seven assets |
| Approved concepts | Seven selections; source images and recorded hashes verified in the historical audit |
| No selected concept | Nine entries: seven buildings and two historical castles |
| External production models | One logical asset, Human Knight, in GLB and FBX |
| Fully game-ready external models | Zero |
| New unit/building model backlog | 13: five units and eight buildings; improve the existing Knight rather than regenerate it |
| Historical castle slots | Two, purpose unresolved after the Crystal redesign; not an order for new models |
| Rigs and animation clips | Zero; future animated presentation concerns six characters |

Parts-based arena, lobby, buildings, and units already exist. Missing GLB files do not mean missing gameplay. Alternate formats, archived copies, screenshots, concept images, and editor packages do not count as additional production models. Environment prop quantities are not approved.

## Approved concepts

| Asset | Selection | Source |
|---|---|---|
| Human Knight | A | assets/concepts/units/human_knight/variant_A.png |
| Human Archer | A | assets/concepts/units/human_archer/variant_A.png |
| Human Mage | A | assets/concepts/units/human_mage/variant_A.png |
| Undead Giant | B | assets/concepts/units/undead_giant/variant_B.png |
| Undead Skeleton Archer | A | assets/concepts/units/undead_skeleton_archer/variant_A.png |
| Undead Necromancer | B | assets/concepts/units/undead_necromancer/variant_B.png |
| Human Barracks / KnightBarracks | B | assets/concepts/buildings/human_barracks/variant_B.png |

All seven selected hashes matched manifest, selection.json, and asset-preparation.json in the historical audit; no approved image was missing. Alternatives remain preserved and unapproved. Selection does not approve 3D quality or paid generation. Do not repeat these choices.

No A/B images yet exist for ArcherTower, MageAcademy, LightSanctuary, GiantGraveyard, BoneTower, NecromancerCrypt, CursedObelisk, Human Castle, or Undead Castle. Prompts and selection placeholders are not images. human_knight_barracks is an old alias placeholder for human_barracks, not another building; undead_archer aliases undead_skeleton_archer.

## Units and buildings

Knight is SOURCE_DOWNLOADED, historically IMPORTED/PREPARED in a separate test, and REQUIRES_REVIEW. Partial static inspection is not completed visual, animation, or gameplay approval. Archer, Mage, Giant, SkeletonArcher, Necromancer, and Human Barracks are CONCEPT_ONLY with no external source. The other nine entries are SOURCE_MISSING. None is GAME_READY.

UnitConfig/UnitPresentation define exactly six characters. Knight is the ordinary Human melee fighter; no separate Human elite/giant or Undead melee skeleton/elite is approved. All future rigs need a separate implementation task: current UnitModels rejects Bone, joints, Humanoid, AnimationController, and constraints. Simply inserting an animated model into templates is not integration.

| Building | Faction | Implemented role | External model |
|---|---|---|---|
| KnightBarracks | Human | Produces Knight | Missing; concept B approved |
| ArcherTower | Human | Produces Archer | Missing |
| MageAcademy | Human | Produces Mage | Missing |
| LightSanctuary | Human | P22 lane shield | Missing |
| GiantGraveyard | Undead | Produces Giant | Missing |
| BoneTower | Undead | Produces SkeletonArcher | Missing |
| NecromancerCrypt | Undead | Produces Necromancer | Missing |
| CursedObelisk | Undead | P22 lane curse | Missing |

The two towers are Producers, not stationary attacking defenses. All eight external-building source paths, target heights, source directions, and plot sizes remain unresolved/null in preparation configuration. Human Barracks paid approval is pending; its plan is not a generated result. Historical building-branch tests used a labeled Knight fixture, not an actual barracks model.

## Knight source and import evidence

| File | Size | Geometry |
|---|---:|---|
| assets/models/units/human_knight/model.glb | 2790672 bytes | glTF 2.0, 1576 triangles, 2019 attribute vertices, one mesh/node/primitive |
| assets/models/units/human_knight/model.fbx | 2784700 bytes | Binary FBX 7400, one mesh, 793 control points, 1576 triangular polygons |

These are two formats from one task, not two assets. Raw bounds: 0.9575200081 × 0.8862310052 × 0.2978509963; not a chosen Roblox scale. GLB SHA-256: 462353370a5e38030e46ee5d74d580fa0557fc8f5ef614c018012f84bcb15a6d. FBX SHA-256: 6448184d6ce31fb47b1917db2f76c0dcdc07152adfc518068efa8c9a3165d95b. Historical metadata verification matched all 13 saved files.

Three welded components: body 1488 triangles and two hip plates of 44 each. Zero degenerate/duplicate triangles and boundary/nonmanifold welded edges were found. UV/normals and one base-color PNG 2048×2048 exist; metallicFactor=0, roughnessFactor=1. No extra PBR maps, skin, skeleton, or clips. Self-intersection, thickness, and deformation are not certified. The source lacks the concept sword and shield. Preserve concept A and improve this model.

FBX references model.fbm/texture_0.png without a sidecar, but embeds 2705589 bytes in Video.Content. This is not proof of texture loss; verify extraction/linking in Importer or Blender. Separate FBX import was not checked in the inventory audit. The diagnostic FBX reader and 12-triangle synthetic cube remain build-only tools, not production assets.

KnightVisualTest_Updated.rbxlx preserves the real import: MeshId 92061902066137, TextureID 108942469871178. Eight instances share that ID: normalized body, original small import, prepared copy, and five QA archives. Six Diagnostics records are not six assets. Normalized XML bounds are approximately 5.40233517 × 5.00012207 × 1.68047762 studs; report height is 5, feet/surface Y=0.25. Tiny differences reflect measurement precision. No Bone/Motor6D/Humanoid/Animation occurs in that saved scene. IDs do not prove current network availability.

Sword and Shield are separate five-Part static props with Grip/Handle pivots. Five AssetRoot Attachments are provisional markers, not bones. Historical gameplay windows had no accepted runtime template folders and used Parts fallbacks. Do not reimport the Knight merely because the main game has no template; use existing sources and saved test.

## Scale and visual hierarchy

Use studs and compare against the chosen actual Roblox avatar, not a claimed universal avatar height. Existing presentation references: ordinary units 5 studs, Giant 6.5. These are visual references, not new balance approval. Most pipeline heights remain null. QA archives at height 6 are experiments, not approved Knight scale.

Real build pads are 8×10, visible markers 7.8 square, factory margin 0.5 each side and height ceiling 12. Thus technical footprint is at most 7×9, preferably 7×7 inside the visible square. Suggested building heights 6–10 remain proposals, with towers below the existing ceiling and main crystals. The 14×14 test plot does not establish fit on an actual pad. Knight T-pose span approximately 5.4 needs formation/equipment review.

Visual priority: main crystals, environment, buildings, then units by class. Crystals dominate; large trees/columns add depth outside combat corridors. Ordinary Knight/skeleton characters should read near player height, Giants clearly taller. No source model was rescaled by this release.

The historical 17B snapshot contained 1303 Parts/WedgeParts, 16 trees, eight wayshrines, 16 planting groups, roads, markers, perimeter, and cyan/purple crystal shrines. P20/P23 later preserve the approved battle arena with 1404 parts and add a separate lobby. These authored Parts environments are existing content, not missing external models. The two castle manifest slots still need a decision about Crystal-era purpose. Bow/Staff equipment templates are not confirmed; configuration/fallback details do not establish imported weapons.

## Pipeline capabilities and limits

The pipeline validates registry IDs, selections, paths, approvals, and evidence. It prepares a copy of an already imported object with scale/pivot/declared facing, static physics, unit markers or building plot/exit diagnostics. GLB inspection reports geometry/UV/PNG/views; FBX production QA remains manual. CheckAsset uses offline triangles only when observed MeshId matches evidence, not live Roblox topology. Over-budget status is a warning/manual review, not GAME_READY.

It does not automate local Importer, infer a face, create rigs/weights/animation, approve models, guarantee an unobstructed doorway, or deliver accepted runtime templates. Future mass preparation requires agreed dimensions, per-revision reports, material/texture/LOD budgets, actual pad/exit checks, physical-device tests, and separate source/import/prepared/visual/gameplay approvals.

## Preservation and known discrepancies

Original A/B alternatives, reference, source model formats, QA scenes, and provenance are retained. Staging copies/build caches/backups are excluded from release. Fourteen staging PNGs and seven duplicated inspection files were historical duplicates, not extra assets; do not count them twice. Editor rbxmx and bootstrap rbxlx packages contain tools, not a mesh collection. Original alternatives are useful history and are not automatically deleted.

Historical audit: 16 registry entries, 59 local manifest references, seven approved hashes, 13 Knight saved-file hashes, and 99 protected-file comparisons passed. Both validators passed. It was a read-only inventory, with no new Playtest/import/Prepare/Reset/camera changes or type/build rerun.

Earlier bootstrap false import flags describe their original stage; later live-session reports and Updated scene confirm import. model_ready means generation completed, not quality approval: needs_manual_revision, approvedForGameplay=false, and pending user approval remain material. The manifest does not yet designate the Updated test as canonical. All seven concept sets have license=null; provenance/receipts exist but documented usage rights need completion. No account/license verification is implied.

Two existing Node-test failures were documented before localization: lifecycle fixture expects an ungenerated Knight but receives E_LOCKED after actual 3D submission; preservation expects an obsolete BuildingConfig hash. Do not silently replace historical hashes to manufacture PASS. Current release check results are in [ENGLISH_RELEASE.md](ENGLISH_RELEASE.md).

## Next authorized planning steps

Preserve seven approved concepts; agree dimensions and the two historical castle slots. Improve existing Knight equipment/budget/hip plates/joints, then separately commission rig/integration. Human Barracks B and the five other approved characters need separate production permission. Seven other buildings need A/B selection before 3D. Environment replacements require an explicit asset list. No paid work is authorized here.

Manual review remains: open existing Updated test separately, verify current mesh/texture availability, views/UV/equipment, FBX texture extraction, scale beside the intended avatar, and later deformation. Do not regenerate or reimport everything by default. Physical-device and complete gameplay readiness remain unverified.
