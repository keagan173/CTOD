const sb=window.ctodSupabase;
const ctx=window.ctodWorkspaceContext;
if(!sb||!ctx||!['owner','admin'].includes(ctx.role))throw new Error('CTOD configuration workspace requires owner/admin context.');

const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
const companyId=ctx.companyId;
let state={context:null,units:[],locations:[],roles:[],questions:[],reasons:[],ratings:[]};

function inject(){
  const tabs=document.querySelector('#app>.tabs');
  if(!tabs||document.querySelector('#tabConfig'))return;
  const btn=document.createElement('button');btn.id='tabConfig';btn.className='btn tab secondary';btn.textContent='Configuration';tabs.appendChild(btn);
  const view=document.createElement('div');view.id='configView';view.className='view hidden';document.querySelector('#app').appendChild(view);
  const style=document.createElement('style');style.textContent=`
  #configView .cfg-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}.cfg-list{display:grid;gap:8px}.cfg-row{border:1px solid var(--line);border-radius:12px;padding:11px;display:flex;justify-content:space-between;gap:12px;align-items:center}.cfg-head{display:flex;justify-content:space-between;gap:12px;align-items:flex-start;flex-wrap:wrap}.cfg-badge{padding:6px 10px;border-radius:999px;background:var(--pale);font-size:12px;font-weight:900}.cfg-actions{display:flex;gap:8px;flex-wrap:wrap}.cfg-muted{color:var(--muted);font-size:12px}.cfg-wide{grid-column:1/-1}@media(max-width:800px){#configView .cfg-grid{grid-template-columns:1fr}.cfg-wide{grid-column:auto}}
  `;document.head.appendChild(style);
  btn.onclick=async()=>{showConfig();await load();};
  ['tabReviews','tabCoaching','tabEmployees','tabSchedule','tabMaster','tabAccess'].forEach(id=>document.querySelector('#'+id)?.addEventListener('click',()=>view.classList.add('hidden')));
}

function showConfig(){
  document.querySelectorAll('#app>.view').forEach(v=>v.classList.add('hidden'));
  document.querySelector('#configView')?.classList.remove('hidden');
  document.querySelectorAll('#app>.tabs .tab').forEach(b=>b.classList.remove('active'));
  const b=document.querySelector('#tabConfig');b?.classList.add('active');b?.classList.remove('secondary');
}

async function ensureDraft(){
  if(state.context?.config_status==='draft')return state.context.config_version_id;
  const {data,error}=await sb.rpc('admin_begin_configuration_draft',{p_company_id:companyId,p_version_label:null});
  if(error)throw error;
  await load();return data;
}

async function load(){
  const c=await sb.from('v_company_configuration_context').select('*').eq('company_id',companyId).single();
  if(c.error)throw c.error;
  state.context=c.data;
  const cfg=c.data.config_version_id;
  const [units,locations,roles,questions,reasons,ratings]=await Promise.all([
    sb.from('organization_units').select('*').eq('company_id',companyId).order('sort_order'),
    sb.from('locations').select('*').eq('company_id',companyId).order('location_code'),
    sb.from('roles').select('*').eq('company_id',companyId).order('sort_order'),
    cfg?sb.from('question_definitions').select('*').eq('company_id',companyId).eq('config_version_id',cfg).order('sort_order'):Promise.resolve({data:[]}),
    cfg?sb.from('reason_definitions').select('*').eq('company_id',companyId).eq('config_version_id',cfg).order('sort_order'):Promise.resolve({data:[]}),
    cfg?sb.from('rating_scale_items').select('*').eq('company_id',companyId).eq('config_version_id',cfg).order('sort_order'):Promise.resolve({data:[]})
  ]);
  for(const r of [units,locations,roles,questions,reasons,ratings])if(r.error)throw r.error;
  Object.assign(state,{units:units.data||[],locations:locations.data||[],roles:roles.data||[],questions:questions.data||[],reasons:reasons.data||[],ratings:ratings.data||[]});
  render();
}

function render(){
  const c=state.context||{};const draft=c.config_status==='draft';
  const host=document.querySelector('#configView');
  host.innerHTML=`<div class="cfg-head" style="margin-bottom:16px"><div><h2 style="margin:0">Customer Configuration</h2><div class="sub">Build this company without changing CTOD Core.</div></div><div class="cfg-actions"><span class="cfg-badge">${esc(c.config_status||'none')} · ${esc(c.version_label||'No config')}</span>${draft?'<button id="cfgPublish" class="btn primary">Publish Configuration</button>':'<button id="cfgDraft" class="btn primary">Start Configuration Draft</button>'}</div></div>
  <div id="cfgMsg" class="sub" style="margin-bottom:12px"></div>
  <div class="cfg-grid">
    <section class="card section"><h3>Company Profile</h3><label>Company Name</label><input id="cfgCompanyName" class="field" value="${esc(c.company_name||'')}"><label>Timezone</label><input id="cfgTimezone" class="field" value="${esc(c.timezone||'America/Boise')}"><label>Review Cadence (months)</label><input id="cfgCadence" class="field" type="number" min="1" max="24" value="${esc(c.review_cadence_months||6)}"><button id="cfgSaveCompany" class="btn primary" style="margin-top:14px">Save Company</button></section>
    <section class="card section"><h3>Organization Hierarchy</h3><div class="grid2"><div><label>Type</label><select id="cfgUnitType" class="field"><option>region</option><option>area</option><option>market</option><option>division</option><option>department</option><option>group</option></select></div><div><label>Code</label><input id="cfgUnitCode" class="field"></div></div><label>Name</label><input id="cfgUnitName" class="field"><label>Parent</label><select id="cfgUnitParent" class="field"><option value="">None</option>${state.units.map(u=>`<option value="${u.id}">${esc(u.unit_type)} · ${esc(u.name)}</option>`).join('')}</select><button id="cfgAddUnit" class="btn primary" style="margin-top:14px">Add Unit</button><div class="cfg-list" style="margin-top:12px">${state.units.map(u=>`<div class="cfg-row"><div><strong>${esc(u.name)}</strong><div class="cfg-muted">${esc(u.unit_type)}${u.unit_code?' · '+esc(u.unit_code):''}</div></div><button class="btn secondary cfgToggleUnit" data-id="${u.id}" data-active="${u.active}">${u.active?'Deactivate':'Activate'}</button></div>`).join('')||'<div class="sub">No hierarchy units yet.</div>'}</div></section>
    <section class="card section"><h3>Locations</h3><div class="grid2"><div><label>Location Code</label><input id="cfgLocCode" class="field"></div><div><label>Name</label><input id="cfgLocName" class="field"></div></div><label>Hierarchy Unit</label><select id="cfgLocUnit" class="field"><option value="">None</option>${state.units.filter(u=>u.active).map(u=>`<option value="${u.id}">${esc(u.unit_type)} · ${esc(u.name)}</option>`).join('')}</select><div class="grid2"><div><label>City</label><input id="cfgLocCity" class="field"></div><div><label>State</label><input id="cfgLocState" class="field"></div></div><button id="cfgAddLocation" class="btn primary" style="margin-top:14px">Add Location</button><div class="cfg-list" style="margin-top:12px">${state.locations.map(l=>`<div class="cfg-row"><div><strong>${esc(l.location_code)} · ${esc(l.name)}</strong><div class="cfg-muted">${esc(l.city||'')}${l.state_code?', '+esc(l.state_code):''}</div></div><button class="btn secondary cfgToggleLocation" data-id="${l.id}" data-active="${l.status==='active'}">${l.status==='active'?'Deactivate':'Activate'}</button></div>`).join('')||'<div class="sub">No locations yet.</div>'}</div></section>
    <section class="card section"><h3>Job Roles</h3><label>Role Title</label><input id="cfgRoleTitle" class="field"><button id="cfgAddRole" class="btn primary" style="margin-top:14px">Add Role</button><div class="cfg-list" style="margin-top:12px">${state.roles.map(r=>`<div class="cfg-row"><strong>${esc(r.title)}</strong><button class="btn secondary cfgToggleRole" data-id="${r.id}" data-active="${r.active}">${r.active?'Deactivate':'Activate'}</button></div>`).join('')||'<div class="sub">No roles yet.</div>'}</div></section>
    <section class="card section cfg-wide"><h3>Review Questions</h3><div class="grid2"><div><label>Role</label><select id="cfgQuestionRole" class="field"><option value="">Company-wide</option>${state.roles.filter(r=>r.active).map(r=>`<option value="${r.id}">${esc(r.title)}</option>`).join('')}</select></div><div><label>Section</label><input id="cfgQuestionSection" class="field" placeholder="Leadership"></div></div><label>Question</label><textarea id="cfgQuestionText" class="field" rows="3"></textarea><button id="cfgAddQuestion" class="btn primary" style="margin-top:14px">Add Question to Draft</button><div class="cfg-list" style="margin-top:12px">${state.questions.map(q=>`<div class="cfg-row"><div><strong>${esc(q.question_text)}</strong><div class="cfg-muted">${esc(q.section_name)} · ${esc(state.roles.find(r=>r.id===q.role_id)?.title||'Company-wide')}</div></div><button class="btn secondary cfgToggleQuestion" data-id="${q.id}" data-active="${q.active}">${q.active?'Deactivate':'Activate'}</button></div>`).join('')||'<div class="sub">No questions in this configuration.</div>'}</div></section>
    <section class="card section cfg-wide"><h3>Question Reasons</h3><div class="grid2"><div><label>Question</label><select id="cfgReasonQuestion" class="field">${state.questions.filter(q=>q.active).map(q=>`<option value="${q.id}">${esc(q.question_text)}</option>`).join('')}</select></div><div><label>Rating</label><select id="cfgReasonRating" class="field">${state.ratings.map(r=>`<option value="${esc(r.code)}">${esc(r.label)}</option>`).join('')}</select></div></div><label>Reason</label><input id="cfgReasonLabel" class="field"><button id="cfgAddReason" class="btn primary" style="margin-top:14px">Add Reason to Draft</button><div class="cfg-list" style="margin-top:12px">${state.reasons.slice(0,100).map(r=>`<div class="cfg-row"><div><strong>${esc(r.label)}</strong><div class="cfg-muted">${esc(r.rating_code||'Any rating')}</div></div><button class="btn secondary cfgToggleReason" data-id="${r.id}" data-active="${r.active}">${r.active?'Deactivate':'Activate'}</button></div>`).join('')||'<div class="sub">No reasons in this configuration.</div>'}</div></section>
  </div>`;
  wire();
}

const msg=t=>{const x=document.querySelector('#cfgMsg');if(x)x.textContent=t||'';};
const slug=s=>String(s||'').trim().toUpperCase().replace(/[^A-Z0-9]+/g,'_').replace(/^_|_$/g,'').slice(0,40)||'GENERAL';

function wire(){
  document.querySelector('#cfgDraft')?.addEventListener('click',async()=>{try{msg('Creating protected draft...');await ensureDraft();msg('Draft ready.');}catch(e){msg(e.message)}});
  document.querySelector('#cfgPublish')?.addEventListener('click',async()=>{try{const {error}=await sb.rpc('admin_publish_configuration',{p_company_id:companyId,p_config_version_id:state.context.config_version_id});if(error)throw error;await load();msg('Configuration published. Historical versions remain intact.');}catch(e){msg(e.message)}});
  document.querySelector('#cfgSaveCompany')?.addEventListener('click',async()=>{try{const name=document.querySelector('#cfgCompanyName').value.trim(),timezone=document.querySelector('#cfgTimezone').value.trim(),cadence=Number(document.querySelector('#cfgCadence').value||6);let r=await sb.from('companies').update({name,timezone}).eq('id',companyId);if(r.error)throw r.error;r=await sb.from('company_settings').upsert({company_id:companyId,review_cadence_months:cadence,updated_at:new Date().toISOString()});if(r.error)throw r.error;await load();msg('Company settings saved.');}catch(e){msg(e.message)}});
  document.querySelector('#cfgAddUnit')?.addEventListener('click',async()=>{try{const payload={company_id:companyId,unit_type:document.querySelector('#cfgUnitType').value,unit_code:document.querySelector('#cfgUnitCode').value.trim()||null,name:document.querySelector('#cfgUnitName').value.trim(),parent_unit_id:document.querySelector('#cfgUnitParent').value||null,sort_order:state.units.length+1};if(!payload.name)throw new Error('Unit name is required.');const r=await sb.from('organization_units').insert(payload);if(r.error)throw r.error;await load();msg('Hierarchy unit added.');}catch(e){msg(e.message)}});
  document.querySelector('#cfgAddLocation')?.addEventListener('click',async()=>{try{const payload={company_id:companyId,location_code:document.querySelector('#cfgLocCode').value.trim(),name:document.querySelector('#cfgLocName').value.trim(),organization_unit_id:document.querySelector('#cfgLocUnit').value||null,city:document.querySelector('#cfgLocCity').value.trim()||null,state_code:document.querySelector('#cfgLocState').value.trim()||null,status:'active'};if(!payload.location_code||!payload.name)throw new Error('Location code and name are required.');const r=await sb.from('locations').insert(payload);if(r.error)throw r.error;await load();msg('Location added.');}catch(e){msg(e.message)}});
  document.querySelector('#cfgAddRole')?.addEventListener('click',async()=>{try{const title=document.querySelector('#cfgRoleTitle').value.trim();if(!title)throw new Error('Role title is required.');const r=await sb.from('roles').insert({company_id:companyId,title,active:true,sort_order:state.roles.length+1});if(r.error)throw r.error;await load();msg('Role added.');}catch(e){msg(e.message)}});
  document.querySelector('#cfgAddQuestion')?.addEventListener('click',async()=>{try{const cfg=await ensureDraft(),text=document.querySelector('#cfgQuestionText').value.trim(),section=document.querySelector('#cfgQuestionSection').value.trim()||'Performance';if(!text)throw new Error('Question text is required.');const code='Q_'+Date.now().toString(36).toUpperCase();const r=await sb.from('question_definitions').insert({company_id:companyId,config_version_id:cfg,role_id:document.querySelector('#cfgQuestionRole').value||null,question_code:code,section_code:slug(section),section_name:section,question_text:text,category:null,active:true,sort_order:state.questions.length+1,question_weight:1,section_weight:1,requires_rating:true,requires_reason:true,notes_required_for_exceptional:false,notes_required_for_unsatisfactory:true});if(r.error)throw r.error;await load();msg('Question added to draft.');}catch(e){msg(e.message)}});
  document.querySelector('#cfgAddReason')?.addEventListener('click',async()=>{try{const cfg=await ensureDraft(),question_id=document.querySelector('#cfgReasonQuestion').value,label=document.querySelector('#cfgReasonLabel').value.trim(),rating_code=document.querySelector('#cfgReasonRating').value;if(!question_id||!label||!rating_code)throw new Error('Question, rating, and reason are required.');const q=state.questions.find(x=>x.id===question_id);const r=await sb.from('reason_definitions').insert({company_id:companyId,config_version_id:cfg,label,reason_type:'review',rating_code,category:q?.category||null,role_id:q?.role_id||null,active:true,sort_order:state.reasons.filter(x=>x.question_id===question_id&&x.rating_code===rating_code).length+1,external_code:null,question_id});if(r.error)throw r.error;await load();msg('Reason added to draft.');}catch(e){msg(e.message)}});
  document.querySelectorAll('.cfgToggleUnit').forEach(b=>b.onclick=()=>toggle('organization_units',b.dataset.id,b.dataset.active!=='true'));
  document.querySelectorAll('.cfgToggleLocation').forEach(b=>b.onclick=()=>toggleLocation(b.dataset.id,b.dataset.active!=='true'));
  document.querySelectorAll('.cfgToggleRole').forEach(b=>b.onclick=()=>toggle('roles',b.dataset.id,b.dataset.active!=='true'));
  document.querySelectorAll('.cfgToggleQuestion').forEach(b=>b.onclick=()=>toggle('question_definitions',b.dataset.id,b.dataset.active!=='true'));
  document.querySelectorAll('.cfgToggleReason').forEach(b=>b.onclick=()=>toggle('reason_definitions',b.dataset.id,b.dataset.active!=='true'));
}

async function toggle(table,id,active){try{if(['question_definitions','reason_definitions'].includes(table))await ensureDraft();const r=await sb.from(table).update({active}).eq('id',id).eq('company_id',companyId);if(r.error)throw r.error;await load();}catch(e){msg(e.message)}}
async function toggleLocation(id,active){try{const r=await sb.from('locations').update({status:active?'active':'inactive'}).eq('id',id).eq('company_id',companyId);if(r.error)throw r.error;await load();}catch(e){msg(e.message)}}

inject();