import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root=path.resolve(import.meta.dirname,'..');
const sources={MapConfig:'src/shared/Config/MapConfig.luau',TerritoryService:'src/server/TerritoryService.luau',ArenaVisuals:'tools/studio/ArenaVisuals.luau',MapBuilder:'tools/studio/MapBuilder.luau'};
const xml=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const quote=s=>{let n=0;while(s.includes(']'+ '='.repeat(n)+']'))n++;return '['+'='.repeat(n)+'['+s+']'+'='.repeat(n)+']'};
const items=[];const statements=[];const hashes={};
for(const [name,file] of Object.entries(sources)){
 const source=fs.readFileSync(path.join(root,file),'utf8');
 hashes[file]=crypto.createHash('sha256').update(source).digest('hex');
 items.push(`<Item class="ModuleScript"><Properties><string name="Name">${name}</string><ProtectedString name="Source">${xml(source)}</ProtectedString></Properties></Item>`);
 statements.push(`do local m=Instance.new("ModuleScript"); m.Name=${quote(name)}; m.Source=${quote(source)}; m.Parent=package end`);
}
fs.mkdirSync(path.join(root,'assets/maps'),{recursive:true});fs.mkdirSync(path.join(root,'build'),{recursive:true});
fs.writeFileSync(path.join(root,'assets/maps/MapTools.rbxmx'),`<roblox version="4"><Item class="Folder"><Properties><string name="Name">CastleFightMapTools</string></Properties>${items.join('')}</Item></roblox>`);
const installer=`--!strict\n-- Generated one-way from disk. Does not build the map.\nassert(game:GetService("RunService"):IsEdit(),"E_EDIT_ONLY")\nassert(game.PlaceId==101102700433907 or game.PlaceId==0,"E_WRONG_PLACE")\nassert(not workspace:FindFirstChild("KnightVisualTest") and not workspace:FindFirstChild("AssetVisualTest"),"E_ASSET_TEST_PLACE")\nlocal storage=game:GetService("ServerStorage")\nassert(not storage:FindFirstChild("CastleFightMapTools"),"E_TOOLS_EXIST_NO_OVERWRITE")\nlocal package=Instance.new("Folder"); package.Name="CastleFightMapTools"\n${statements.join('\n')}\npackage.Parent=storage\nreturn "Installed CastleFightMapTools; map not created"\n`;
fs.writeFileSync(path.join(root,'build/MapTools.install.luau'),installer);
fs.writeFileSync(path.join(root,'assets/maps/map-tools-bundle.json'),JSON.stringify({sources,hashes,automaticBuild:false,workspaceSync:false},null,2)+'\n');
console.log('PASS: MapTools.rbxmx and build/MapTools.install.luau generated; no Studio writes.');
