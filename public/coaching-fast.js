import { ctodSupabase as sb } from './ctod-config.js';
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
let roster=[], membership=null, rendering=false;

const categories={
  recognition:['Customer Service','Leadership','Teamwork','Safety','Sales / Performance','Technical Skill','Reliability / Attendance','Initiative','Positive Influence','Other Recognition'],
  development:['Communication','Leadership Development','Technical Skill','Sales Development','Customer Service','Time Management','Organization','Teamwork','Attendance / Reliability','Minor Documentation','Other Development'],
  corrective:['Attendance / Tardiness','Policy / Procedure','Safety','Customer Service','Work Quality','Productivity','Communication / Conduct','Teamwork / Behavior','Carelessness / Damage','Failure to Follow Direction','Minor Documentation','Other Corrective']
};

function fullName(e){return `${e.first_name||''} ${e.last_name||''}`.trim()}
function employeeOptions(selected=''){return '<option value="">Select employee...</option>'+roster.map(e=>`<option value="${e.employee_id}" ${selected===e.employee_id?'selected':''}>${esc(fullName(e))} · #${esc(e.employee_code||'------')} · ${esc(e.role_title)} · ${esc(e.location_code)}</option>`).join('')}
function categoryOptions(type){return categories[type].map(x=>`<option value="${esc(x)}">${esc(x)}</option>`).join('')}
function stamp(){return new Date().toLocaleString([], {dateStyle:'medium',timeStyle:'short'})}
function statusText(c){if(!c.include_in_review)return 'Documented only';if(c.type==='recognition')return c.active_carry_forward?'Include next review':'Reviewed';if(!c.active_carry_forward)return 'Resolved 2 of 2';if((c.resolved_streak||0)===1)return 'Corrected 1 of 2';return 'Active · 0 of 2'}
function statusClass(c){if(!c.include_in_review)return 'green';if(c.type==='recognition')return 'green';return c.active_carry_forward?'yellow':'green'}

async function bootstrap(){
  const user=(await sb.auth.getUser()).data.user;if(!user)return false;
  const m=await sb.from('company_memberships').select('company_id,role,active').eq('user_id',user.id).eq('active',true).maybeSingle();
  membership=m.data;if(!membership)return false;
  const r=await sb.rpc('manager_workspace_employees');if(r.error)return false;
  roster=r.data||[];return true;
}

async function renderCoaching(selected=''){
  if(rendering)return;rendering=true;
  try{
    const host=$('#coachingView');if(!host)return;
    if(!membership && !(await bootstrap()))return;
    host.dataset.fastCoaching='1';
    host.innerHTML=`<section class="card section"><div class="workspace-head"><div><h3>Coaching</h3><div class="sub">Fast entry: employee → type → category → notes → save. CTOD timestamps it automatically.</div></div><div class="pill green">30-second workflow</div></div><label>Employee</label><select id="fastCoachEmployee" class="field">${employeeOptions(selected)}</select><div id="fastCoachBody"></div></section>`;
    const sel=$('#fastCoachEmployee');sel.onchange=()=>renderEmployee(sel.value);if(selected)await renderEmployee(selected);
  } finally {rendering=false}
}

async function renderEmployee(employeeId){
  const host=$('#fastCoachBody');if(!host)return;
  if(!employeeId){host.innerHTML='';return}
  const e=roster.find(x=>x.employee_id===employeeId);
  host.innerHTML=`<div class="manager-grid"><div class="invite-card compact"><h4>New Coaching Moment</h4><div class="grid2"><div><label>Type</label><select id="fcType" class="field"><option value="recognition">Recognition</option><option value="development">Development</option><option value="corrective">Corrective</option></select></div><div><label>Category</label><select id="fcCategory" class="field">${categoryOptions('recognition')}</select></div></div><label>Notes</label><textarea id="fcNotes" class="field" rows="4" placeholder="Document the exact event or issue..."></textarea><div class="invite-card" style="margin-top:12px"><div style="display:flex;justify-content:space-between;gap:14px;align-items:center"><div><strong>Include in next review</strong><div class="sub">If included, Development/Corrective items require two consecutive corrected review cycles before they clear.</div></div><input id="fcInclude" type="checkbox" style="width:22px;height:22px"></div></div><div class="sub" style="margin-top:10px"><strong>Timestamp:</strong> <span id="fcStamp">${esc(stamp())}</span> · Employee #${esc(e?.employee_code||'')}</div><div class="actions" style="margin-top:14px"><button id="fcSave" class="btn primary">Save Coaching Moment</button><span id="fcMsg" class="sub"></span></div></div><div class="invite-card compact"><h4>Coaching History</h4><div id="fcHistory" class="sub">Loading...</div></div></div>`;
  const type=$('#fcType'),cat=$('#fcCategory'),include=$('#fcInclude');
  const syncType=()=>{cat.innerHTML=categoryOptions(type.value);include.checked=type.value!=='recognition'};
  type.onchange=syncType;cat.onchange=()=>{if(cat.value==='Minor Documentation')include.checked=false};syncType();
  $('#fcSave').onclick=async()=>{
    const notes=$('#fcNotes').value.trim();if(!notes){$('#fcMsg').textContent='Add a short note describing what happened.';return}
    const user=(await sb.auth.getUser()).data.user;const shouldInclude=include.checked;const now=new Date().toISOString();
    const ins=await sb.from('coaching_moments').insert({company_id:membership.company_id,employee_id:employeeId,created_by_user_id:user.id,occurred_at:now,type:type.value,category:cat.value,notes,expected_outcome:null,include_in_review:shouldInclude,record_status:'active',resolved_streak:0,active_carry_forward:shouldInclude});
    if(ins.error){$('#fcMsg').textContent=ins.error.message;return}
    $('#fcMsg').textContent=shouldInclude?'Saved · queued for next review.':'Saved · documentation only.';$('#fcNotes').value='';$('#fcStamp').textContent=stamp();await loadHistory(employeeId);
  };
  await loadHistory(employeeId);
}

async function loadHistory(employeeId){
  const host=$('#fcHistory');if(!host)return;
  const r=await sb.from('coaching_moments').select('id,occurred_at,type,category,notes,include_in_review,resolved_streak,active_carry_forward,record_status').eq('employee_id',employeeId).order('occurred_at',{ascending:false}).limit(50);
  if(r.error){host.innerHTML=`<div class="issue">${esc(r.error.message)}</div>`;return}
  if(!(r.data||[]).length){host.innerHTML='<div class="sub">No coaching moments yet.</div>';return}
  host.innerHTML=r.data.map(c=>`<div class="history-row"><div style="display:flex;justify-content:space-between;gap:10px"><div><strong>${esc(c.category)}</strong><div class="sub">${esc(String(c.type).replaceAll('_',' '))} · ${esc(new Date(c.occurred_at).toLocaleString([], {dateStyle:'short',timeStyle:'short'}))}</div></div><span class="pill ${statusClass(c)}">${esc(statusText(c))}</span></div><p>${esc(c.notes||'')}</p>${c.include_in_review&&c.type!=='recognition'?`<div class="sub"><strong>Two-cycle rule:</strong> ${c.active_carry_forward?(c.resolved_streak||0)+' of 2 corrected cycles':'complete'}</div>`:''}</div>`).join('');
}

function wire(){
  const tab=$('#tabCoaching');if(tab)tab.addEventListener('click',()=>setTimeout(()=>renderCoaching(),120));
  const host=$('#coachingView');if(host)new MutationObserver(()=>{if(!host.classList.contains('hidden')&&!host.dataset.fastCoaching)setTimeout(()=>renderCoaching(),20)}).observe(host,{childList:true,subtree:false});
}

for(let i=0;i<40;i++){if($('#app'))break;await new Promise(r=>setTimeout(r,200))}
await bootstrap().catch(()=>false);wire();
