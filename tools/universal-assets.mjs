import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';
export const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));
export const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex');
const triple=v=>Array.isArray(v)&&v.length===3&&v.every(Number.isFinite);
function local(p){assert.equal(typeof p,'string','E_PATH');assert.ok(!path.isAbsolute(p)&&path.resolve(root,p).startsWith(root+path.sep),'E_PATH');return path.join(root,p);}
export function validate(config=read('assets/asset-preparation.json')){
 const manifest=read('docs/ASSET_MANIFEST.json');
 assert.equal(config.schemaVersion,1);assert.ok(config.assets.length>=manifest.assets.length);
 for(const m of manifest.assets)assert.ok(config.assets.some(a=>a.assetId===m.assetId),'E_MANIFEST_ASSET_MISSING');
 assert.equal(new Set(config.assets.map(a=>a.assetId)).size,config.assets.length,'E_DUPLICATE_ID');
 for(const a of config.assets){
  const m=manifest.assets.find(m=>m.assetId===a.assetId);assert.ok(m||a.assetType==='prop','E_ASSET_ID');
  assert.ok(['unit','building','castle','prop'].includes(a.assetType),'E_TYPE');
  assert.ok(['human','undead','neutral'].includes(a.faction),'E_FACTION');
  if(m){assert.equal(a.faction,m.faction.toLowerCase(),'E_FACTION_MISMATCH');assert.equal(a.assetType,m.category==='units'?'unit':m.category==='castles'?'castle':'building','E_TYPE_MISMATCH');}
  assert.ok(['none','box'].includes(a.collisionMode),'E_COLLISION');
  assert.ok(['-Z','+Z','-X','+X'].includes(a.desiredForwardDirection),'E_FORWARD');
  assert.ok(a.sourceForwardDirection===null||['-Z','+Z','-X','+X'].includes(a.sourceForwardDirection),'E_SOURCE_FORWARD');
  assert.ok(Number.isInteger(a.maxTriangles)&&a.maxTriangles>0,'E_TRIANGLES');
  assert.ok(a.targetHeightStuds===null||(Number.isFinite(a.targetHeightStuds)&&a.targetHeightStuds>0&&a.targetHeightStuds<=100),'E_HEIGHT');
  assert.equal(typeof a.requiresRig,'boolean');
  assert.ok(Number.isInteger(a.maxVisualComponents)&&a.maxVisualComponents>=1&&a.maxVisualComponents<=128,'E_COMPONENTS');
  if(a.sourceModelPath!==null){assert.ok(/\.(glb|fbx)$/i.test(a.sourceModelPath),'E_SOURCE_FORMAT');assert.ok(fs.existsSync(local(a.sourceModelPath)),'E_SOURCE_MISSING');}
  const expected=m?.approval?{status:'approved',variant:m.selected,path:m.selectedConceptPath,sha256:m.approval.sha256}:null;
  if(m)assert.deepEqual(a.approvedConcept,expected,'E_APPROVAL_MISMATCH');
  else if(a.approvedConcept)assert.ok(a.approvedConcept.status==='approved'&&['A','B'].includes(a.approvedConcept.variant),'E_PROP_APPROVAL');
  if(a.approvedConcept)assert.equal(hash(a.approvedConcept.path),a.approvedConcept.sha256,'E_CONCEPT_CHANGED');
  if(a.assetType==='unit'){
   assert.ok(['humanoid','skeleton','giant'].includes(a.characterCategory),'E_CATEGORY');
   for(const name of ['RightHand','LeftHand','Back','Head','Root'])assert.ok(a.equipmentSlots[name]&&triple(a.equipmentSlots[name].position)&&triple(a.equipmentSlots[name].rotationDegrees),'E_SLOT');
  }
  if(a.plotSizeStuds!==null)assert.ok(Array.isArray(a.plotSizeStuds)&&a.plotSizeStuds.length===2&&a.plotSizeStuds.every(n=>Number.isFinite(n)&&n>0),'E_FOOTPRINT');
  if(['building','castle'].includes(a.assetType))assert.ok(a.spawnPoint&&triple(a.spawnPoint.positionNormalized)&&triple(a.spawnPoint.rotationDegrees),'E_SPAWN_MARKER');
  if(a.geometryEvidence){assert.equal(hash(a.sourceModelPath),a.geometryEvidence.sourceSHA256,'E_GEOMETRY_CHANGED');assert.equal(read(a.geometryEvidence.reportPath).triangleCount,a.geometryEvidence.triangleCount,'E_GEOMETRY_REPORT');}
  assert.ok(['source_missing','downloaded','imported_in_test_scene'].includes(a.importStatus),'E_IMPORT_STATUS');
  assert.ok(['not_prepared','requiring_manual_review','validated'].includes(a.validationStatus),'E_VALIDATION_STATUS');
 }
 for(const kind of ['Sword','Shield','Bow','Staff']){const e=config.equipment[kind];assert.ok(e&&triple(e.offset)&&triple(e.rotationDegrees)&&e.referenceHeightStuds>0,'E_EQUIPMENT');}
 assert.ok(triple(config.scene.origin)&&triple(config.scene.padSize)&&triple(config.scene.frontCamera)&&triple(config.scene.angleCamera));
 assert.ok(Number.isInteger(config.scene.rulerHeight)&&config.scene.rulerHeight>=1&&config.scene.rulerHeight<=100,'E_RULER_LIMIT');
 assert.ok(Number.isFinite(config.scene.lightBrightness)&&config.scene.lightBrightness>=0&&config.scene.lightBrightness<=5,'E_LIGHT_BRIGHTNESS');
 assert.ok(Number.isFinite(config.scene.lightRange)&&config.scene.lightRange>=1&&config.scene.lightRange<=100,'E_LIGHT_RANGE');
 return config;
}
export function preservation(){const s=read('docs/RELEASE_PROTECTED_FILES.json');for(const[p,h]of Object.entries(s.files))assert.equal(hash(p),h,'E_PROTECTED_CHANGED: '+p);assert.deepEqual(read('docs/ASSET_MANIFEST.json').assets.map(a=>({assetId:a.assetId,selected:a.selected??null,approval:a.approval??null})),s.approvals);return {checked:Object.keys(s.files).length,unreadable:[]};}
export function inspect(assetId){
 const c=validate(),a=c.assets.find(a=>a.assetId===assetId);assert.ok(a?.sourceModelPath,'E_SOURCE_MISSING');
 assert.ok(a.sourceModelPath.toLowerCase().endsWith('.glb'),'E_FBX_MANUAL_REVIEW: use importer/Blender for FBX geometry; no fabricated triangle count');
 const out='assets/tests/universal/inspections/'+assetId;
 execFileSync(process.execPath,[path.join(root,'tools/inspect-glb.mjs'),local(a.sourceModelPath),local(out),String(a.maxTriangles)],{cwd:root});
 return read(out+'/geometry.json');
}
export function bundle(){
 const c=validate(),dir=path.join(root,'tools/studio/AssetPipeline');
 const json=JSON.stringify(c,null,2);let equals='==';while(json.includes(']'+equals+']'))equals+='=';
 fs.writeFileSync(path.join(dir,'GeneratedConfig.luau'),'--!strict\n-- Generated from assets/asset-preparation.json; do not edit.\nreturn ['+equals+'['+json+']'+equals+']\n');
 const files=fs.readdirSync(dir).filter(n=>n.endsWith('.luau')).sort();
 const modules=files.map(name=>({name:name.slice(0,-5),source:fs.readFileSync(path.join(dir,name),'utf8')}));
 for(const m of modules)assert.ok(m.source.startsWith('--!strict'),'E_STRICT: '+m.name);
 fs.mkdirSync(path.join(root,'build'),{recursive:true});fs.mkdirSync(path.join(root,'assets/tests/universal'),{recursive:true});
 const guard='local RunService=game:GetService("RunService")\nassert(not RunService:IsRunning(),"E_PLAY_MODE")\nlocal old=workspace:FindFirstChild("KnightVisualTest")\nlocal boot=workspace:FindFirstChild("AssetVisualTestBootstrap")\nlocal universal=workspace:FindFirstChild("AssetVisualTest")\nlocal id=if old then old:FindFirstChild("SceneId") else nil\nlocal uid=if universal then universal:FindFirstChild("SceneId") else nil\nassert((id and id:IsA("StringValue") and id.Value=="castlefight.knight-visual-test.v1") or (uid and uid:IsA("StringValue") and uid.Value=="castlefight.asset-visual-test.v1") or (boot and boot:IsA("StringValue") and boot.Value=="castlefight.asset-visual-test.v1"),"E_TEST_CONTEXT")\nassert(game.PlaceId~=101102700433907,"E_MAIN_MAP")\n';
 const install='--!strict\n-- Generated from disk sources. One-time test-place install; never overwrites modules.\n'+guard+'local storage=game:GetService("ReplicatedStorage")\nassert(not storage:FindFirstChild("CastleFightAssetTools"),"E_PACKAGE_EXISTS: use installed tools or an explicit upgrade")\nlocal package=Instance.new("Folder") package.Name="CastleFightAssetTools"\n'+modules.map(m=>'do local module=Instance.new("ModuleScript") module.Name='+JSON.stringify(m.name)+' module.Source='+JSON.stringify(m.source)+' module.Parent=package end').join('\n')+'\npackage.Parent=storage\nprint("Installed CastleFightAssetTools; no mesh import performed")\n';
 fs.writeFileSync(path.join(root,'build/AssetTools.install.luau'),install);
 const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
 const folder='<Item class="Folder" referent="TOOLS"><Properties><string name="Name">CastleFightAssetTools</string></Properties>'+modules.map((m,i)=>'<Item class="ModuleScript" referent="M'+i+'"><Properties><string name="Name">'+esc(m.name)+'</string><ProtectedString name="Source">'+esc(m.source)+'</ProtectedString></Properties></Item>').join('')+'</Item>';
 const xml=items=>'<?xml version="1.0" encoding="utf-8"?><roblox version="4"><External>null</External><External>nil</External>'+items+'</roblox>\n';
 fs.writeFileSync(path.join(root,'assets/tests/universal/AssetTools.rbxmx'),xml(folder));
 const place=xml('<Item class="Workspace" referent="WORKSPACE"><Properties><string name="Name">Workspace</string></Properties><Item class="StringValue" referent="BOOTSTRAP"><Properties><string name="Name">AssetVisualTestBootstrap</string><string name="Value">castlefight.asset-visual-test.v1</string></Properties></Item></Item><Item class="ReplicatedStorage" referent="STORAGE"><Properties><string name="Name">ReplicatedStorage</string></Properties>'+folder+'</Item><Item class="ServerStorage" referent="SOURCES"><Properties><string name="Name">ServerStorage</string></Properties><Item class="Folder" referent="IMPORTED"><Properties><string name="Name">ImportedAssets</string></Properties></Item></Item>');
 const dest=path.join(root,'assets/tests/universal/AssetVisualTest.rbxlx');
 const receiptPath=path.join(root,'assets/tests/universal/bundle.json');
 if(fs.existsSync(dest)){assert.equal(read('assets/tests/universal/bundle.json').bootstrapSHA256,hash('assets/tests/universal/AssetVisualTest.rbxlx'),'E_PLACE_EDITED: do not overwrite user scene');}
 fs.writeFileSync(dest,place);
 const receipt={toolVersion:c.toolVersion,modules:modules.map(m=>m.name),bootstrapContainsImportedMesh:false,bootstrapRequiresCreateTestScene:true,bootstrapSHA256:hash('assets/tests/universal/AssetVisualTest.rbxlx'),configSHA256:hash('assets/asset-preparation.json'),moduleHashes:Object.fromEntries(files.map(n=>[n,hash('tools/studio/AssetPipeline/'+n)]))};
 fs.writeFileSync(receiptPath,JSON.stringify(receipt,null,2)+'\n');return receipt;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{const command=process.argv[2];if(command==='validate'){const c=validate();console.log('PASS: '+c.assets.length+' configurations; approved concepts match manifest; no generation.');}else if(command==='bundle')console.log(JSON.stringify(bundle()));else if(command==='preservation')console.log(JSON.stringify(preservation()));else if(command==='inspect'){const r=inspect(process.argv[3]);console.log(JSON.stringify({triangles:r.triangleCount,vertices:r.vertexCount,warnings:r.warnings}));}else throw Error('validate | bundle | preservation | inspect ASSET_ID');}catch(e){console.error(e.message);process.exitCode=1;}
}
