import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const fail = (code, message) => { throw new Error(`${code}: ${message}`); };
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const pngSignature = Buffer.from([137,80,78,71,13,10,26,10]);
function validPNG(bytes) {
  return bytes.length > 32 && bytes.subarray(0,8).equals(pngSignature)
    && bytes.toString('ascii',12,16) === 'IHDR'
    && bytes.readUInt32BE(16) > 0 && bytes.readUInt32BE(20) > 0
    && bytes.includes(Buffer.from('IEND'));
}
function local(root, relative) {
  if (typeof relative !== 'string' || path.isAbsolute(relative)) fail('E_PATH', String(relative));
  const resolved = path.resolve(root, relative);
  if (!resolved.startsWith(path.resolve(root) + path.sep)) fail('E_PATH', relative);
  // Disallow symlinks/junctions escaping the project as well.
  let ancestor = resolved;
  while (!fs.existsSync(ancestor)) ancestor = path.dirname(ancestor);
  const real = fs.realpathSync(ancestor);
  if (real !== fs.realpathSync(root) && !real.startsWith(fs.realpathSync(root) + path.sep)) fail('E_PATH', relative);
  return resolved;
}
function context(root, id) {
  const manifest = read(path.join(root, 'docs/ASSET_MANIFEST.json'));
  const item = manifest.assets.find(a => a.assetId === id);
  if (!item) fail('E_ASSET', id);
  const file = local(root, item.selectionPath);
  return { item, file, data: read(file) };
}
function save(file, data) {
  const temp = file + '.' + crypto.randomUUID() + '.tmp';
  try { fs.writeFileSync(temp, JSON.stringify(data, null, 2) + '\n', { flag: 'wx' }); fs.renameSync(temp, file); }
  finally { if (fs.existsSync(temp)) fs.unlinkSync(temp); }
}
function checkData(root, item, d) {
  if (d.assetId !== item.assetId || d.category !== item.category) fail('E_IDENTITY', item.assetId);
  if (![null,'A','B'].includes(d.selected)) fail('E_SELECTION', item.assetId);
  if (!['awaiting_concepts','concepts_partial','awaiting_selection','approved','model_submitted','model_ready','rigged','animated','failed'].includes(d.status)) fail('E_STATUS', item.assetId);
  if (!d.taskIds?.concepts || !d.paths || !d.generationSettings || !d.approval || !d.conceptHashes) fail('E_SCHEMA', item.assetId);
  for (const v of ['A','B']) {
    const f = local(root, d.paths['variant_' + v]);
    local(root, d.paths['prompt_' + v]);
    if (!fs.existsSync(local(root, d.paths['prompt_' + v]))) fail('E_PROMPT_MISSING', item.assetId + '/' + v);
    if (fs.existsSync(f)) {
      const bytes = fs.readFileSync(f);
      if (!validPNG(bytes)) fail('E_PNG_INVALID', item.assetId + '/' + v);
      if (d.conceptHashes[v] !== hash(bytes)) fail('E_CONCEPT_CHANGED', item.assetId + '/' + v);
    } else if (d.conceptHashes[v] || d.selected === v) fail('E_CONCEPT_MISSING', item.assetId + '/' + v);
  }
  for (const key of ['modelDirectory','animationDirectory']) local(root, d.paths[key]);
  if (d.selected !== null || d.approval.status === 'approved') {
    if (!d.selected || d.approval.status !== 'approved' || d.approval.variant !== d.selected || !d.approval.approvedBy || !d.approval.approvedAt) fail('E_APPROVAL', item.assetId);
    for (const v of ['A','B']) if (!d.conceptHashes[v]) fail('E_TWO_CONCEPTS_REQUIRED', item.assetId);
    if (d.approval.sha256 !== d.conceptHashes[d.selected]) fail('E_APPROVAL_HASH', item.assetId);
  }
  if (['approved','model_submitted','model_ready','rigged','animated'].includes(d.status) && d.approval.status !== 'approved') fail('E_3D_NOT_APPROVED', item.assetId);
  if (d.taskIds.model3d && (d.approval.status !== 'approved' || d.paidApproval?.status !== 'approved' || !d.paidApproval.evidence || d.paidApproval.assetId !== d.assetId || d.paidApproval.variant !== d.selected || d.paidApproval.sha256 !== d.approval.sha256 || !d.generationSettings.model3d)) fail('E_3D_NOT_APPROVED', item.assetId);
  if (['model_submitted','model_ready','rigged','animated'].includes(d.status) && !d.taskIds.model3d) fail('E_MODEL_TASK_MISSING', item.assetId);
}
export function validate(root = ROOT) {
  const m = read(path.join(root, 'docs/ASSET_MANIFEST.json'));
  if (m.schemaVersion !== 1 || m.assets.length !== 16 || new Set(m.assets.map(a => a.assetId)).size !== 16) fail('E_MANIFEST', 'Expected 16 unique assets');
  for (const [category, count] of [['units',6],['buildings',8],['castles',2]]) if (m.assets.filter(a => a.category === category).length !== count) fail('E_CATEGORY', category);
  const errors = [];
  for (const a of m.assets) { try { checkData(root, a, read(local(root,a.selectionPath))); } catch(e) { errors.push(e.message); } }
  if (errors.length) fail('E_VALIDATION', errors.join('\n'));
  return m;
}
export function importConcept(root, id, variant, source, taskId) {
  if (!['A','B'].includes(variant) || !taskId) fail('E_ARGUMENT', 'import requires A/B, PNG and real task ID');
  validate(root);
  const {file,data:d} = context(root,id);
  if (d.selected || d.taskIds.model3d) fail('E_LOCKED', id);
  const bytes = fs.readFileSync(source);
  if (!validPNG(bytes)) fail('E_PNG_INVALID', source);
  const target = local(root,d.paths['variant_' + variant]);
  if (fs.existsSync(target)) fail('E_EXISTS', 'Existing concept cannot be overwritten: ' + target);
  fs.writeFileSync(target,bytes,{flag:'wx'});
  d.conceptHashes[variant] = hash(bytes);
  d.taskIds.concepts[variant] = taskId;
  d.status = d.conceptHashes.A && d.conceptHashes.B ? 'awaiting_selection' : 'concepts_partial';
  save(file,d);
}
export function select(root,id,variant,approvedBy) {
  if (!['A','B'].includes(variant) || !approvedBy) fail('E_ARGUMENT','select requires A/B and approver');
  validate(root);
  const {file,data:d} = context(root,id);
  if (d.taskIds.model3d) fail('E_LOCKED','3D already submitted');
  if (!d.conceptHashes.A || !d.conceptHashes.B) fail('E_TWO_CONCEPTS_REQUIRED',id);
  d.selected = variant;
  d.status = 'approved';
  d.approval = {status:'approved',variant,sha256:d.conceptHashes[variant],approvedBy,approvedAt:new Date().toISOString()};
  d.paidApproval = {status:'not_requested',evidence:null};
  save(file,d);
}
export function plan3d(root,id,approvalFile) {
  validate(root);
  const {data:d} = context(root,id);
  if (!d.selected || d.approval.status !== 'approved') fail('E_3D_NOT_APPROVED',id);
  if (d.taskIds.model3d) fail('E_LOCKED','Do not resubmit an existing task');
  const a = read(approvalFile);
  const s = a.settings;
  if (a.assetId !== id || a.variant !== d.selected || a.sha256 !== d.approval.sha256 || a.status !== 'approved' || !a.approvedBy || !a.approvedAt || !a.evidence || !Number.isFinite(a.credits) || a.credits <= 0) fail('E_PAID_APPROVAL','Explicit per-asset cost approval required');
  if (!s || !['meshy-t2','meshy-t2.5'].includes(s.ai_model) || s.model_type !== 'smart-topology' || !Number.isInteger(s.target_polycount) || s.target_polycount < 100 || s.target_polycount > (s.ai_model === 'meshy-t2' ? 15000 : 30000) || typeof s.should_texture !== 'boolean' || !s.target_formats?.length || s.target_formats.some(f => !['glb','fbx'].includes(f))) fail('E_SETTINGS','Specify approved smart-topology model, polycount, texture choice and FBX/GLB formats');
  if (s.should_texture && !['meshy-n1','meshy-7','meshy-6-lite'].includes(s.texture_model)) fail('E_SETTINGS','Specify texture_model');
  if (s.texture_model === 'meshy-n1' && (s.enable_pbr || (s.texture_resolution && s.texture_resolution !== '2k') || s.texture_prompt || s.remove_lighting)) fail('E_SETTINGS','Unsupported Meshy N1 options');
  const allowed = ['ai_model','model_type','target_polycount','should_texture','texture_model','target_formats','pose_mode','texture_resolution','enable_pbr'];
  if (Object.keys(s).some(k => !allowed.includes(k))) fail('E_SETTINGS','Unknown or unsupported setting');
  if (s.pose_mode && !['t-pose','a-pose'].includes(s.pose_mode)) fail('E_SETTINGS','Invalid pose_mode');
  if (s.texture_resolution && !['2k','4k','8k'].includes(s.texture_resolution)) fail('E_SETTINGS','Invalid texture_resolution');
  if (s.texture_model === 'meshy-6-lite' && s.texture_resolution && s.texture_resolution !== '2k') fail('E_SETTINGS','Lite supports 2k');
  return {tool:'meshy_image_to_3d',args:{...s,file_path:local(root,d.paths['variant_' + d.selected])},paidApproval:a,dryRun:true};
}
export function record3d(root,id,approvalFile,taskId) {
  if (!taskId || !taskId.trim()) fail('E_ARGUMENT','Real task ID required');
  const plan = plan3d(root,id,approvalFile);
  const {file,data:d} = context(root,id);
  d.taskIds.model3d = taskId;
  d.status = 'model_submitted';
  d.generationSettings.model3d = plan.args;
  d.paidApproval = plan.paidApproval;
  save(file,d);
}
export function gallery(root = ROOT) {
  const m = validate(root);
  const escape = s => String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const cards = m.assets.map(a => {
    const d = context(root,a.assetId).data;
    return `<section><h2>${escape(a.name)} (${escape(a.assetId)})</h2><p>Status: ${escape(d.status)}; selected: ${escape(d.selected ?? 'none')}</p><div class="pair">` + ['A','B'].map(v => {
      const relative = path.relative(path.join(root,'assets/concepts'),local(root,d.paths['variant_' + v])).split(path.sep).join('/');
      const approved = d.selected === v && d.approval.status === 'approved';
      return `<figure class="${approved ? 'approved' : 'unselected'}"${approved ? ' style="outline:4px solid #66e5a3;background:#173d30"' : ''}><figcaption>${escape(a.name)} — ${v}${approved ? ' <strong style="display:inline-block;padding:4px 10px;background:#66e5a3;color:#10251b">APPROVED</strong>' : ''}</figcaption>${fs.existsSync(local(root,d.paths['variant_'+v])) ? `<img src="${escape(relative)}" alt="${escape(a.name)} ${v}${approved ? ' — approved' : ''}">` : '<p>Concept not created yet</p>'}<pre>Select ${v} for ${escape(a.assetId)}</pre></figure>`;
    }).join('') + '</div></section>';
  }).join('\n');
  fs.writeFileSync(path.join(root,'assets/concepts/gallery.html'),`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Castle Fight concepts</title><style>body{font:16px system-ui;max-width:1200px;margin:24px auto;padding:16px;background:#171d28;color:#eee}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0;padding:16px;background:#253044}img{width:100%;max-height:480px;object-fit:contain}section{margin-bottom:40px}pre{white-space:pre-wrap}@media(max-width:600px){.pair{grid-template-columns:1fr}}</style><h1>Castle Fight — concept selection</h1><p>Static viewer. Tell Codex “Select A/B for assetId”. The CLI saves your selection; the browser does not write files. Regenerate the gallery after selecting. Concept approval does not authorize paid generation.</p>${cards}</html>\n`);
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const [command,...args] = process.argv.slice(2);
    if (command === 'validate') { validate(); console.log('OK: 16 assets; manifest and approvals valid (missing ungenerated concepts allowed).'); }
    else if (command === 'gallery') { gallery(); console.log('OK: assets/concepts/gallery.html'); }
    else if (command === 'import') { importConcept(ROOT,...args); console.log('OK: imported without overwrite'); }
    else if (command === 'select') { select(ROOT,...args); gallery(); console.log('OK: concept approved; paid generation NOT approved'); }
    else if (command === 'plan-3d') console.log(JSON.stringify(plan3d(ROOT,...args),null,2));
    else if (command === 'record-3d') { record3d(ROOT,...args); console.log('OK: task receipt recorded; no API call made'); }
    else fail('E_COMMAND','validate | gallery | import ID A/B PNG TASK_ID | select ID A/B APPROVER | plan-3d ID APPROVAL_JSON | record-3d ID APPROVAL_JSON TASK_ID');
  } catch(e) { console.error(/^E_/.test(e.message) ? e.message : 'E_IO: ' + e.message); process.exitCode = 1; }
}
