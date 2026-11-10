// Builds a genuine standalone Roblox XML place from Parts; never imports or fabricates a mesh.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
const output='assets/tests/human_knight';
fs.mkdirSync(output,{recursive:true});
const sourcePath='tools/studio/KnightVisualTest.luau';
const moduleSource=fs.readFileSync(sourcePath,'utf8');
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
let next=0;
const item=(className,name,properties=[],children=[])=>({className,name,ref:'RBX_TEST_'+next++,properties,children});
const prop=(type,name,value)=>`<${type} name="${name}">${value}</${type}>`;
const vector=(name,v)=>prop('Vector3',name,`<X>${v[0]}</X><Y>${v[1]}</Y><Z>${v[2]}</Z>`);
function cf(name,p,angle=0){const c=Math.cos(angle),s=Math.sin(angle);return prop('CoordinateFrame',name,`<X>${p[0]}</X><Y>${p[1]}</Y><Z>${p[2]}</Z><R00>${c}</R00><R01>${-s}</R01><R02>0</R02><R10>${s}</R10><R11>${c}</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22>`);}
const blue=[37,102,205],silver=[166,179,194],dark=[64,71,84],gray=[109,119,132];
const parts=[];
function part(name,size,position,color,collide=false,angle=0){const n=item('Part',name,[vector('size',size),cf('CFrame',position,angle),prop('Color3uint8','Color3uint8',String((0xff000000+(color[0]<<16)+(color[1]<<8)+color[2])>>>0)),prop('token','Material',256),prop('bool','Anchored','true'),prop('bool','CanCollide',String(collide)),prop('bool','CanTouch','false'),prop('bool','CanQuery',String(collide)),prop('bool','Massless',String(!collide)),prop('token','TopSurface',0),prop('token','BottomSurface',0)]);parts.push({name,size,position,color,collide,angle,ref:n.ref});return n;}
function label(adornee,text,offset=1.5){const textNode=item('TextLabel','Text',[prop('string','Text',esc(text)),prop('bool','TextScaled','true'),prop('float','BackgroundTransparency',1),prop('Color3','TextColor3','<R>0.95</R><G>0.97</G><B>1</B>'),prop('UDim2','Size','<XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO>')]);return item('BillboardGui','Label',[prop('Ref','Adornee',adornee.ref),prop('bool','AlwaysOnTop','true'),vector('StudsOffset',[0,offset,0]),prop('UDim2','Size','<XS>0</XS><XO>230</XO><YS>0</YS><YO>55</YO>')],[textNode]);}
const ground=part('TestGround',[28,0.5,18],[-1,-0.25,0],[49,57,68],true);
const knightPad=part('KnightPad',[6.5,0.25,5],[0,0.125,0],[46,72,107],true);knightPad.children.push(label(knightPad,'BODY NOT IMPORTED\nTarget height: 5 studs',6));
const refPad=part('ReferencePad',[5,0.25,5],[8,0.125,0],[70,83,98],true);
const reference=item('Model','Reference5Stud',[],[
 part('Head',[2,1,1],[8,4.75,0],[195,187,166]),part('Torso',[2,2,1],[8,3.25,0],gray),
 part('LeftArm',[1,2,1],[6.5,3.25,0],gray),part('RightArm',[1,2,1],[9.5,3.25,0],gray),
 part('LeftLeg',[1,2,1],[7.5,1.25,0],dark),part('RightLeg',[1,2,1],[8.5,1.25,0],dark),
]);refPad.children.push(label(refPad,'5 STUD BLOCK REFERENCE\nParts only / no rig',6));
const swordParts=[
 part('Grip',[0.22,0.5,0.22],[-7,1.45,0],blue),
 part('Pommel',[0.32,0.18,0.30],[-7,1.12,0],blue),
 part('Guard',[1,0.18,0.32],[-7,1.78,0],blue),
 part('Blade',[0.44,1.65,0.18],[-7,2.695,0],silver),
 part('AngularTip',[0.305,0.305,0.18],[-7,3.52,0],silver,false,Math.PI/4),
];
const sword=item('Model','Sword',[prop('Ref','PrimaryPart',swordParts[0].ref)],swordParts);
const shieldParts=[
 part('Handle',[0.22,0.65,0.30],[-10,1.75,0.20],dark),
 part('UpperPlate',[1.45,0.35,0.22],[-10,2.63,0],blue),
 part('MainPlate',[1.7,0.95,0.22],[-10,1.98,0],blue),
 part('LowerPlate',[1.24,0.52,0.22],[-10,1.245,0],blue),
 part('Tip',[0.63,0.35,0.22],[-10,0.81,0],blue),
];
const shield=item('Model','Shield',[prop('Ref','PrimaryPart',shieldParts[0].ref)],shieldParts);
const swordPad=part('SwordStand',[2,0.25,2],[-7,0.125,0],dark,true);swordPad.children.push(label(swordPad,'PARTS SWORD\nSeparate visual prop',4.3));
const shieldPad=part('ShieldStand',[2.5,0.25,2],[-10,0.125,0],dark,true);shieldPad.children.push(label(shieldPad,'PARTS BLUE SHIELD\nSeparate visual prop',4.3));
const ruler=[];ruler.push(part('HeightRuler',[0.08,6,0.08],[4.3,3.25,0],[205,211,219]));
for(let i=0;i<=6;i++)ruler.push(part('StudTick_'+i,[0.35,0.04,0.08],[4.3,0.25+i,0],[205,211,219]));
const frontArrow=[part('ForwardMinusZ',[0.12,0.04,1.3],[0,0.29,-3.2],blue),part('ArrowLeft',[0.12,0.04,0.7],[-.21,.29,-3.76],blue,false,-Math.PI/4),part('ArrowRight',[0.12,0.04,0.7],[.21,.29,-3.76],blue,false,Math.PI/4)];

for(const [i,angle] of [[1,-Math.PI/4],[2,Math.PI/4]]){const p=parts.find(p=>p.ref===frontArrow[i].ref).position;const c=Math.cos(angle),s=Math.sin(angle);frontArrow[i].properties[1]=prop('CoordinateFrame','CFrame',`<X>${p[0]}</X><Y>${p[1]}</Y><Z>${p[2]}</Z><R00>${c}</R00><R01>0</R01><R02>${s}</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>${-s}</R20><R21>0</R21><R22>${c}</R22>`);}
const root=item('Model','KnightVisualTest',[],[
 item('StringValue','SceneId',[prop('string','Value','castlefight.knight-visual-test.v1')]),
 item('BoolValue','BodyImported',[prop('bool','Value','false')]),ground,knightPad,refPad,reference,swordPad,shieldPad,sword,shield,
 item('Model','Ruler',[],ruler),item('Model','ForwardGuide',[],frontArrow),
]);
// Camera looks from -Z (Roblox forward) at the complete stand.
function lookAt(position,target){const normalize=v=>{const n=Math.hypot(...v);return v.map(x=>x/n);},cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];const back=normalize(position.map((n,i)=>n-target[i])),right=normalize(cross([0,1,0],back)),up=cross(back,right);return prop('CoordinateFrame','CFrame',`<X>${position[0]}</X><Y>${position[1]}</Y><Z>${position[2]}</Z>`+['R00','R01','R02','R10','R11','R12','R20','R21','R22'].map((n,i)=>`<${n}>${[right,up,back][i%3][Math.floor(i/3)]}</${n}>`).join(''));}
const camera=item('Camera','Camera',[lookAt([17,12,-24],[-1,2,0]),prop('float','FieldOfView',55)]);
const workspace=item('Workspace','Workspace',[prop('Ref','CurrentCamera',camera.ref)],[camera,root]);
const module=item('ModuleScript','KnightVisualTest',[prop('ProtectedString','Source',esc(moduleSource))]);
const replicated=item('ReplicatedStorage','ReplicatedStorage',[],[item('Folder','KnightTestTools',[],[module])]);
const storage=item('ServerStorage','ServerStorage',[],[item('Folder','KnightImportedSource')]);
const lighting=item('Lighting','Lighting',[prop('float','Brightness',2),prop('Color3','Ambient','<R>0.5</R><G>0.5</G><B>0.5</B>'),prop('Color3','OutdoorAmbient','<R>0.6</R><G>0.6</G><B>0.6</B>'),prop('bool','GlobalShadows','false')]);
const serialize=n=>`<Item class="${n.className}" referent="${n.ref}"><Properties>${prop('string','Name',esc(n.name))}${n.properties.join('')}</Properties>${n.children.map(serialize).join('')}</Item>`;
const xml='<?xml version="1.0" encoding="utf-8"?><roblox version="4"><External>null</External><External>nil</External>'+[workspace,replicated,storage,lighting].map(serialize).join('')+'</roblox>\n';
assert.ok(!xml.includes('class="MeshPart"')&&!xml.includes('class="Humanoid"')&&!xml.includes('class="Motor6D"'));
const path=output+'/KnightVisualTest.rbxlx';
const metadataPath=output+'/scene-metadata.json';
// Only refresh an unchanged template produced by this tool; never overwrite a user-saved place.
if(fs.existsSync(path)){
 const previous=JSON.parse(fs.readFileSync(metadataPath,'utf8'));
 assert.equal(previous.bodyImported,false);
 assert.equal(previous.sceneSHA256,crypto.createHash('sha256').update(fs.readFileSync(path)).digest('hex'),'Scene changed externally; save to a new path instead');
}
fs.writeFileSync(path,xml);
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const originalPaths=['CastleFight.rbxl','default.project.json','assets/models/units/human_knight/model.glb','assets/models/units/human_knight/model.fbx','assets/models/units/human_knight/model_base_color.png'];
const originals=Object.fromEntries(originalPaths.map(p=>[p,hash(p)]));
fs.writeFileSync(metadataPath,JSON.stringify({sceneId:'castlefight.knight-visual-test.v1',scenePath:path,status:'prepared_import_required',bodyImported:false,studioOpened:false,studioImportVerified:false,proposedBodyHeightStuds:5,reference:'Unrigged classic block dimensions: 1 head + 2 torso + 2 legs = 5 studs; not a claim about every R15 avatar.',groundTopY:0,displayFeetY:.25,forwardAxis:'-Z',swordParts:swordParts.length,shieldParts:shieldParts.length,allVisualPartsAnchored:true,visualCanCollide:false,visualCanTouch:false,visualCanQuery:false,scenePartCount:parts.length,parts,originalHashes:originals,moduleSource:sourcePath,moduleSHA256:hash(sourcePath),sceneSHA256:hash(path)},null,2)+'\n');
console.log(JSON.stringify({scene:path,parts:parts.length,swordParts:swordParts.length,shieldParts:shieldParts.length,bodyImported:false,sourceFilesPreserved:true}));
