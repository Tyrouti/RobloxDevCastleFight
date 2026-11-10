# Castle Fight asset pipeline

For already downloaded GLB/FBX preparation, see [Universal Asset Pipeline](UNIVERSAL_ASSET_PIPELINE.md). Concept/paid-approval commands remain separate; editor tools never call Meshy. Registry: ASSET_MANIFEST.json,16 assets (6 units/8 buildings/2 castles). [Discovered MCP schemas](MESHY_CAPABILITIES.md) do not prove account access or successful jobs.

## Layout and lifecycle

assets/references stores references/rights. assets/concepts/{units,buildings,castles}/{assetId} stores selection.json,prompt_A/B.txt and real authorized variant_A/B.png only. Never create empty/fake PNGs. Models/textures go to assets/models/{category}/{assetId};rig/clips to assets/animations/{assetId} on actual download;assets/ui reserved.

awaiting_concepts→concepts_partial→awaiting_selection→approved→model_submitted→model_ready→rigged→animated. failed retains task details. Rigging only for suitable units. selected=null/approval=pending until user chooses;concept approval never permits payment.

## Local Node.js18+ commands

~~~powershell
node tools/asset-pipeline.mjs validate
node tools/asset-pipeline.mjs gallery
node tools/asset-pipeline.mjs import human_knight A C:/downloads/concept_A.png REAL_TASK_ID
node tools/asset-pipeline.mjs import human_knight B C:/downloads/concept_B.png REAL_TASK_ID
node tools/asset-pipeline.mjs select human_knight A user
node tools/asset-pipeline.mjs plan-3d human_knight C:/path/approval.json
node tools/asset-pipeline.mjs record-3d human_knight C:/path/approval.json REAL_3D_TASK_ID
node --test tools/asset-pipeline.test.mjs
~~~

gallery.html is a static local A/B viewer. Tell Codex “Select A for human_knight”;agent runs CLI select. Browser has no save buttons/server. select requires both concepts,hash-binds chosen PNG,resets prior paid permission,updates gallery;choice locks after3D submission.

import checks PNG header/dimensions/IEND,not complete decode/visual QA;exclusive wx write prevents overwrite. SHA detects changes/deletion. Interrupted metadata save after PNG write gives E_CONCEPT_CHANGED:restore metadata from verified receipt,do not regenerate/delete image. Existing concepts never auto-replace;agree a separate revision folder/registry preserving history.

## Future Meshy workflow — separate permission required

1. Agree style/scale/A-B differences/reference rights/prompts. Before **each** paid call,agree model/settings/cost. Image generation/editing also costs credits.
2. Generate A/B separately through actual text_to_image/image_to_image,record real IDs/exact generationSettings.concepts. Different views of one image are not two concepts.
3. Poll existing task ID. On creation timeout,list tasks before retry:payment may already have occurred.
4. Download to temporary path,visually inspect,import into protected folder,record source/license provenance.
5. User chooses A/B;select approves exact file. Separately agree3D geometry/texture models/polycount/format/cost;never invent budget.
6. Create approval.json for **one** asset. plan-3d validates/prints dry-run,never calls Meshy. Recheck immediately before manually authorized MCP request.
7. Immediately record-3d actual task with same approval:taskIds.model3d/status=model_submitted/exact settings/paidApproval. On success download chosen format without overwrite,record local paths/SHA/receipt/URL/provenance,status=model_ready. URLs expire;save files locally.
8. Separately authorize rig for textured humanoid≤300K faces,clear limbs/preferred T-pose;record rig ID/settings. Walking/running included;extra clips require actual list_animations IDs/separate animate payment. Rig/animation downloader returns URLs;ordinary HTTP download into animations/{assetId},no overwrite,verify files/paths.
9. Independently inspect topology/textures/rig/scale/collision/import/performance in Studio. Meshy rig does not guarantee Roblox compatibility. Nothing auto-imports,publishes,or syncs Workspace.

approval.json structure only,not permission:

~~~json
{"assetId":"human_knight","variant":"A","sha256":"TODO_FROM_SELECTION","status":"pending","approvedBy":null,"approvedAt":null,"evidence":null,"credits":null,"settings":{"ai_model":null,"model_type":"smart-topology","target_polycount":null,"should_texture":null,"texture_model":null,"target_formats":[]}}
~~~

evidence is exact permission quote/link covering asset/settings/cost;approvedAt ISO8601. Fill numbers/models only after agreement. No batch generation command. One approval never covers other assets. Local JSON is workflow protection,not authentication;disk owners can edit it/call MCP directly,but agent must honor permission gates.

validate exits0 for valid placeholders;ungenerated PNG absence is normal. Errors exit1:E_MANIFEST/E_CATEGORY(registry),E_SCHEMA/E_IDENTITY/E_STATUS(metadata),E_PATH(escape),E_PNG_INVALID,E_CONCEPT_MISSING/E_CONCEPT_CHANGED,E_TWO_CONCEPTS_REQUIRED,E_APPROVAL/E_APPROVAL_HASH,E_3D_NOT_APPROVED,E_PAID_APPROVAL,E_SETTINGS,E_EXISTS/E_LOCKED. After manual task/metadata updates run validate/gallery. Setup does not verify full image decode,real generation,network download,Studio import. Never store API secrets.
