# human_knight A — trial 3D model

Result: **needs_manual_revision**. Body supports further prototyping but does not fully reproduce approved concept: **sword and blue shield are missing**. Not a finished gameplay unit.

Exactly one Meshy task01a1b89e-d28b-76c6-be63-1c73e0706249,15credits. Only approved variant_A.png used,hash matched approval. meshy-t2.5/smart-topology/target1500/T-pose/meshy-n1/2Kbasecolor. No rigging/animation/regeneration/human_barracks task.

Saved:model.glb(original geometry),model.fbx(same task,binary header checked;separate full FBX geometry review not performed in this initial trial),model_base_color.png,embedded extraction inspection/textures/image_0.png,originalpreview.png,task.json(permission/exact args/receipts/downloads),inspection/geometry.json,front/side/back/three_quarter and components_* diagnostic renders,metadata.json/hashes. These renders are diagnostics,not generations.

| Check | Result |
|---|---|
| Triangles |1576,target1500,+76/about5.1%|
| Attribute vertices |2019,including UV/normal seams|
| Mesh/node/primitive |1each|
| Welded connected components |1488+44+44triangles:body/two hip plates|
| Degenerate/duplicate triangles |0/0|
| Boundary/nonmanifold welded edges |0/0|
| UV/normals |Present|
| Base color |PNG2048×2048,decoded/CRCchecked/rendered|
| Extra PBR maps |None;metallicFactor0/roughnessFactor1|
| Skeleton/skin/animation |None|
| T-pose |Visually present,arms extended/legs distinct|
| Sword/shield/separability |Both missing,cannot test separation|

Helmet/body/blue-gray palette recognizable;one mesh node,no unrelated objects. Detached pieces are hip armor,not weapons. Self-intersections/internal surfaces not fully checked. Feet share minimumY−0.4440920055,no pedestal;origin near body center. Raw bounds0.9575200081×0.8862310052×0.2978509963. Roblox size not agreed. For chosen heightH:centerXZ,subtract minimumY,uniform scaleH/0.8862310052;source not normalized.

Manual next steps:

1. Import a **copy** in Blender,compare saved views,preserve original.
2. Manually add separate simple sword/shield from approvedA;no existing weapon objects to separate. Paid correction requires separate permission.
3. If strict1500budget,try copy Decimate ratio1500/1576≈0.9518,then inspect actual count/face/shoulders/UV/silhouette. Ratio does not guarantee count. Equipment adds budget;allocate separately or reduce body. No automatic optimization performed.
4. Inspect shoulder/elbow/hip/knee topology,weight both hip plates,create armature/skinning/bend checks. T-pose is not deformation approval. No obvious large paper-thin protrusions visually,but finger/edge thickness uncertified.
5. After agreedH,normalize working copy/pivot at feet-center;rawGLB unit is not game scale.
6. Separate empty Roblox test:import oneGLB orFBX,Uploadoff/NoRig,review warnings/orientation/ScaleUnit/texture/base. Settings vary by importer/version. Do not import both as duplicate units.
7. Check gameplay camera,color/UV,feet/pivot/collision/performance. No final main-place import/publication in this initial task.

Sources:[Importer](https://create.roblox.com/docs/studio/importer),[Meshy Image to3D](https://docs.meshy.ai/en/api/image-to-3d),[models](https://docs.meshy.ai/en/api/models).

Limits:container/buffers/accessors/indices/finite coordinates/topology/tolerant connectivity/UV/PNG/views checked. Inspector self-tested on closed12triangle cube/transforms. Not independent glTF validation,Blender cleanup,deformation,or actual Studio import. Generation finished,model user approval still pending. Later import evidence is documented separately;do not confuse this initial report with current game readiness.
