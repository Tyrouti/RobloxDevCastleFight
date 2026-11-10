# English release — review candidate

Status: prepared locally for content review. No commit or push has been made. The local repository has no commits, all release files are untracked, and the current unborn branch is master. Ordinary git diff is therefore empty; comparisons against the pre-translation backup are available in build/english-source-review.diff and build/english-tools-review.diff.

## Scope and completed work

- Maintained source, player-facing building/HUD/lobby/portal text, active developer documentation, and asset inventory are English.
- Source changes: eight Luau files, string literals only. Internal identifiers, remote names, API names, configuration keys, and executable tokens are preserved. No Cyrillic custom identifiers required renaming.
- Fifteen selected core service/balance/navigation files match the original backup byte-for-byte. No gameplay or balance changes were introduced.
- README covers overview, features, stack, installation, Studio/Rojo setup, tests, structure, status, and limitations. .gitattributes was added and .gitignore cleaned up.
- Earlier completed historical translations remain intact. Broad archive translation stopped when scope was reduced; no further historical translation is planned.
- Original concepts/models and approved P21B/P22/P23 remain local. Intermediate arena files, build output, tool binaries, locks, logs, and the full backup are excluded from Git. Existing translated historical documents remain available because active documentation links to them.
- Signed download query parameters were removed from 10 metadata/receipt JSON files; paths, task IDs, approvals, concept hashes, and original model/image bytes were retained. Sanitized URLs are provenance references, not guaranteed download links. Original receipts remain in the ignored backup.

## Focused audit and validation actually executed

| Check | Result |
|---|---|
| Focused Cyrillic audit | 205 candidate text files, zero Cyrillic lines; binary places and historical screenshot pixels excluded |
| Source compatibility comparison | Eight modified Luau sources differ only in string literals; fifteen protected files unchanged |
| Luau strict analysis | PASS: src, Roblox platform, local definitions, P23 sourcemap; exit 0, no source diagnostics |
| Rojo default build | PASS: build/English-runtime.rbxlx |
| Rojo P23 build | PASS: build/English-p23-code.rbxlx |
| verify.ps1 | PASS: JSON, three sync paths, four strict configs, 58 Luau files without BOM |
| Asset manifest validator | PASS: 16 assets |
| Universal configuration validator | PASS: 16 configurations, approved concepts match manifest |
| Node automated tests | 4 PASS, 2 FAIL; known baseline issues below |
| Largest asset inspected | model.glb, 2790672 bytes; current files do not require Git LFS |

Successful checks were not rerun after documentation-only changes. The only subsequent JSON changes remove signed URL query parameters; identifiers and approval hashes are unchanged. No binary build or Studio validation is claimed for those metadata edits.

The lifecycle test expects E_TWO_CONCEPTS_REQUIRED but the already-generated Knight returns E_LOCKED. The preservation test expects an obsolete BuildingConfig hash in build/universal-preservation.json, which is also a nonportable ignored prerequisite. Both failures were documented before localization. Test expectations or historical hashes were not replaced to produce a false PASS.

## P23 and runtime limitations

CastleFight_Arena17B_P23_Lobby.rbxl remains the approved original and was not overwritten. Its embedded scripts and portal properties retain historical Russian text. A separate English full-place derivative was not generated after the scope reduction. The release currently provides English disk sources: open a disposable P23 copy, connect the P23 Rojo profile after inspecting its diff, and verify the localized scene in Studio. Code builds do not contain the full map and lobby.

No fresh English multiplayer Playtest, phone-layout acceptance, or full-place reopen/save was completed. Existing P23 reports document older tests only. No Roblox publication or paid generation occurred. The next review must decide whether to include original binary milestones as historical inputs and whether a separately saved English full-place artifact is required before upload.

## GitHub and backup

The last authenticated check confirmed owner Tyrouti and PRIVATE visibility for https://github.com/Tyrouti/RobloxDevCastleFight. The remote had no commits/default branch; fetch found no HEAD. Visibility will need rechecking before any eventual push. No remote branch/history was modified and no local remote was added.

Full pre-translation backup: build/backups/english-release/project-before.tar. SHA-256: 5A444B7DBE8F626326677F72749A756097BB834FDC166BEDF9A606932C939B86. This includes original milestone places, concepts, models, manifests, existing systems, and original receipts. It stays local and is not a release upload.

Review aids: build/release-candidate-files.txt, build/focused-audit.json, build/english-source-review.diff, build/english-tools-review.diff, and build/english-review-summary.json. No commit hash or pushed branch exists. Push is explicitly on hold until user review.
