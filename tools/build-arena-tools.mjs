// One-way disk source packaging. Keep the original MapTools asset untouched.
import fs from 'node:fs';
import crypto from 'node:crypto';
const sources={MapConfig:'src/shared/Config/MapConfig.luau',TerritoryService:'src/server/TerritoryService.luau',ArenaVisuals:'tools/studio/ArenaVisuals.luau',MapBuilder:'tools/studio/MapBuilder.luau'};
const quote=s=>{let n=0;while(s.includes(']'+ '='.repeat(n)+']'))n++;return '['+'='.repeat(n)+'['+s+']'+'='.repeat(n)+']'};
const xml=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const statements=[],items=[],hashes={};
for(const [name,file] of Object.entries(sources)) {
 const source=fs.readFileSync(file,'utf8'); hashes[file]=crypto.createHash('sha256').update(source).digest('hex');
 statements.push(`do local m=Instance.new("ModuleScript"); m.Name=${quote(name)}; m.Source=${quote(source)}; m.Parent=package end`);
 items.push(`<Item class="ModuleScript"><Properties><string name="Name">${name}</string><ProtectedString name="Source">${xml(source)}</ProtectedString></Properties></Item>`);
}
fs.mkdirSync('build',{recursive:true});
fs.writeFileSync('build/Arena17A.install.luau',`--!strict
assert(game:GetService("RunService"):IsEdit(),"E_EDIT_ONLY")
assert(game.PlaceId==101102700433907,"E_WRONG_PLACE")
local storage=game:GetService("ServerStorage")
assert(not storage:FindFirstChild("CastleFightArena17ATools"),"E_TOOLS_EXIST_NO_OVERWRITE")
local package=Instance.new("Folder"); package.Name="CastleFightArena17ATools"
${statements.join('\n')}
package.Parent=storage
return "Installed disk-authored arena tools; Workspace unchanged"
`);
fs.writeFileSync('assets/maps/Arena17ATools.rbxmx',`<roblox version="4"><Item class="Folder"><Properties><string name="Name">CastleFightArena17ATools</string></Properties>${items.join('')}</Item></roblox>`);
fs.writeFileSync('assets/maps/arena17a-bundle.json',JSON.stringify({sources,hashes,workspaceSync:false,automaticBuild:false},null,2)+'\n');
console.log('PASS: Arena17A bundle generated; original MapTools preserved.');
