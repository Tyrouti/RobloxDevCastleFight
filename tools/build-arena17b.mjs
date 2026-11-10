// Reproducible code builds and provenance. Geometry stays in the saved place, outside Rojo.
import fs from 'node:fs';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
const rojo=process.env.ROJO_PATH || '.tools/asset-validation/rojo/rojo.exe';
fs.mkdirSync('build',{recursive:true});
for(const [project,output] of [['default.project.json','build/Arena17B-code.rbxlx'],['arena-tools.project.json','build/Arena17B-tools.rbxlx'],['arena-redesign.project.json','build/Arena17B-sync.rbxlx']]) execFileSync(rojo,['build',project,'--output',output],{stdio:'inherit'});
const files=['tools/studio/MapBuilder.luau','tools/studio/ArenaVisuals.luau','tools/studio/TestArena17A.luau','tools/studio/TestArena17BGameplay.luau','src/shared/Config/MapConfig.luau','arena-tools.project.json','arena-redesign.project.json'];
const hashes=Object.fromEntries(files.map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex')]));
fs.writeFileSync('assets/maps/arena17b-bundle.json',JSON.stringify({visualRevision:'17B',hashes,workspaceSync:false,geometryFile:'CastleFight_Arena_v17B.rbxl',editorToolsPath:'ServerStorage.CastleFightArena17ATools',apply:'MapBuilder.Redesign(expectedPlaceId)',backupRequired:'ServerStorage.Arena17B_Before.Map',screenshots:['assets/maps/arena17b/top.jpg','assets/maps/arena17b/game-angle.jpg']},null,2)+'\n');
console.log('PASS: 17B code builds and source manifest; no place overwritten.');
