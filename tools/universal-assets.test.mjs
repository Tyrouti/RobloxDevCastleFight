import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validate,preservation} from './universal-assets.mjs';
const config=()=>JSON.parse(fs.readFileSync('assets/asset-preparation.json','utf8'));
test('registry preserves selections and exposes honest source availability',()=>{
 const c=validate();assert.equal(c.assets.length,16);assert.equal(c.assets.filter(a=>a.sourceModelPath).length,1);
 assert.equal(c.assets.filter(a=>a.approvedConcept).length,7);assert.equal(c.assets.find(a=>a.assetId==='human_knight').targetHeightStuds,5);
 assert.equal(c.assets.find(a=>a.assetId==='human_barracks').targetHeightStuds,null);
});
test('reject malformed fields and changed approved choices',()=>{
 for(const [mutate,expected]of [
  [c=>c.assets.push(c.assets[0]),/E_DUPLICATE_ID/],
  [c=>c.assets[0].approvedConcept.variant='B',/E_APPROVAL_MISMATCH/],
  [c=>c.assets[0].targetHeightStuds=-5,/E_HEIGHT/],
  [c=>c.assets[0].collisionMode='complex_magic',/E_COLLISION/],
  [c=>c.assets[0].sourceModelPath='../outside.glb',/E_PATH/],
  [c=>c.assets[0].equipmentSlots.RightHand.position=[0,NaN,0],/E_SLOT/],
  [c=>c.assets[0].geometryEvidence.triangleCount=1,/E_GEOMETRY_REPORT/],
  [c=>c.assets[0].assetType='building',/E_TYPE_MISMATCH/],
 ]){const c=config();mutate(c);assert.throws(()=>validate(c),expected);}
});
test('additional prop config and missing content remain explicit',()=>{
 const c=config();const prop={...c.assets[0],assetId:'test_prop_schema_only',assetType:'prop',faction:'neutral',sourceModelPath:null,approvedConcept:null,targetHeightStuds:null,geometryEvidence:null,equipmentSlots:{},requiresRig:false,characterCategory:null,importStatus:'source_missing',validationStatus:'not_prepared'};
 c.assets.push(prop);assert.equal(validate(c).assets.length,17);
});
test('game sync mapping excludes editor modules and Workspace',()=>{
 const game=JSON.parse(fs.readFileSync('default.project.json','utf8'));
 assert.equal(game.tree.Workspace,undefined);assert.ok(!JSON.stringify(game).includes('AssetPipeline'));
 const tools=JSON.parse(fs.readFileSync('asset-tools.project.json','utf8'));assert.equal(tools.tree.Workspace,undefined);
 assert.equal(tools.tree.ReplicatedStorage.CastleFightAssetTools.$path,'tools/studio/AssetPipeline');
});
test('protected sources and original scene/config preservation',()=>{const result=preservation();assert.ok(result.checked>=40);});
