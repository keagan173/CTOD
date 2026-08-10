import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL='https://wezcuprboyvbmlnuqdoi.supabase.co';
const SUPABASE_KEY='sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5';
const sbm=createClient(SUPABASE_URL,SUPABASE_KEY);
const $m=s=>document.querySelector(s);
const escm=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
let roster=[],membershipM=null;

const COACHING_CATEGORIES={
  recognition:['Customer Service','Employee Ownership','Leadership','Teamwork','Safety','Attendance / Reliability','Productivity','Quality of Work','Initiative','Positive Influence','Other Recognition'],
  development:['Communication','Leadership Development','Technical Skills','Sales Skills','Customer Service','Organization / Time Management','Teamwork','Accountability','Productivity','Career Development','Other Development'],
  corrective:['Attendance / Reliability','Safety','Customer Service','Policy / Procedure','Performance / Productivity','Quality of Work','Communication / Conduct','Accountability','Equipment / Property','Minor Documentation','Other Corrective']
};

function addMonths(dateStr,n){if(!dateStr)return'';const d=new Date(dateStr+'T12:00:00');d.setMonth(d.getMonth()+n);return d.toISOString().slice(0,10)}
function fmtDate(d){if(!d)return'';const x=new Date(d+'T12:00:00');return x.toLocaleDateString()}
function fullName(e){return `${e.first_name||''} ${e.last_name||''}`.trim()}
function stateLabel(c){if(!c.include_in_review)return 'Documented only';if(c.type==='recognition')return 'Next review';if(!c.active_carry_forward)return 'Corrected 2 of 2';if((c.resolved_streak||0)===1)return 'Corrected 1 of 2';return 'Active · 0 of 2'}
function categoryOptions(type){return (COACHING_CATEGORIES[type]||[]).map(x=>`<option value="${escm(x)}">${escm(x)}</option>`).join('')}

function showManagerTab(which){
  ['reviewsView','coachingView','employeesView','scheduleView','masterView','accessView'].forEach(id=>{const el=$m('#'+id);if(el)el.classList.toggle('hidden',id!==which+'View')});
  [['tabReviews','reviews'],['tabCoaching','coaching'],['tabEmployees','employees'],['tabSchedule','schedule'],['tabMaster','master'],['tabAccess','access']].forEach(([id,x])=>{const el=$m('#'+id);if(el)el.classList.toggle('active',x===which)});
  if(which==='coaching')loadCoachingWorkspace();
  if(which==='employees')loadEmployeeWorkspace();
  if(which==='schedule')loadScheduleWorkspace();
}

async function getMembership(){
  const u=(await sbm.auth.getUser()).data.user;if(!u)return null;
  const r=await sbm.from('company_memberships').select('company_id,role,active').eq('user_id',u.id).eq('active',true).maybeSingle();
  membershipM=r.data;return membershipM;
}

async function loadRoster(){
  const r=await sbm.rpc('manager_workspace_employees');
  if(r.error)throw r.error;
  roster=r.data||[];return roster;
}

function employeeOptions(selected=''){return '<option value="">Select employee...</option>'+roster.map(e=>`<option value="${e.employee_id}" ${selected===e.employee_id?'selected':''}>${escm(fullName(e))} · ${escm(e.role_title)} · ${escm(e.location_code)}</option>`).join('')}

async function loadCoachingWorkspace(selected=''){
  const host=$m('#coachingView');if(!host)return;
  try{await loadRoster();host.innerHTML=`<section class="card section"><div class="workspace-head"><div><h3>Coaching</h3><div class="sub">Employee → type → category → note → save. Built for a 30-second manager workflow.</div></div></div><label>Employee</label><select id="coachEmployee" class="field">${employeeOptions(selected)}</select><div id="coachEmployeeWorkspace"></div></section>`;
  const sel=$m('#coachEmployee');sel.onchange=()=>renderCoachingEmployee(sel.value);if(selected)renderCoachingEmployee(selected);
  }catch(e){host.innerHTML=`<section class="card section"><div class="issue">${escm(e.message)}</div></section>`}
}

async function renderCoachingEmployee(employeeId){
  const host=$m('#coachEmployeeWorkspace');if(!employeeId){host.innerHTML='';return}
  host.innerHTML=`<div class="manager-grid"><div class="invite-card compact"><h4>New Coaching Moment</h4><div class="grid2"><div><label>Type</label><select id="mcType" class="field"><option value="recognition">Recognition</option><option value="development">Development</option><option value="corrective">Corrective</option></select></div><div><label>Category</label><select id="mcCategory" class="field">${categoryOptions('recognition')}</select></div></div><label>Notes</label><textarea id="mcNotes" class="field" rows="4" placeholder="Document the exact coaching moment..."></textarea><label>Follow-up <span class="sub">(optional)</span></label><textarea id="mcOutcome" class="field" rows="2" placeholder="Only add if follow-up is needed"></textarea><label class="location-option" style="margin-top:12px"><input id="mcInclude" type="checkbox"> <span><strong>Include in next review</strong><div class="sub">If included, Development / Corrective items require two consecutive corrected review cycles before clearing.</div></span></label><div class="actions" style="margin-top:12px"><button id="mcSave" class="btn primary">Save Coaching Moment</button><span id="mcMsg" class="sub"></span></div></div><div class="invite-card compact"><h4>Coaching History</h4><div id="mcHistory" class="sub">Loading...</div></div></div>`;
  const type=$m('#mcType'),cat=$m('#mcCategory'),include=$m('#mcInclude');
  const syncDefaults=()=>{cat.innerHTML=categoryOptions(type.value);include.checked=type.value!=='recognition'};
  type.onchange=syncDefaults;
  cat.onchange=()=>{if(cat.value==='Minor Documentation')include.checked=false};
  syncDefaults();
  $m('#mcSave').onclick=async()=>{
    const category=cat.value,notes=$m('#mcNotes').value.trim(),includeInReview=include.checked;
    if(!category||!notes){$m('#mcMsg').textContent='Choose a category and enter notes.';return}
    const u=(await sbm.auth.getUser()).data.user;
    const coachingType=type.value;
    const carryForward=includeInReview&&coachingType!=='recognition';
    const ins=await sbm.from('coaching_moments').insert({company_id:membershipM.company_id,employee_id:employeeId,created_by_user_id:u.id,occurred_at:new Date().toISOString(),type:coachingType,category,notes,expected_outcome:$m('#mcOutcome').value.trim()||null,include_in_review:includeInReview,record_status:'active',resolved_streak:0,active_carry_forward:carryForward});
    if(ins.error){$m('#mcMsg').textContent=ins.error.message;return}
    $m('#mcMsg').textContent='Saved with date & time.';$m('#mcNotes').value='';$m('#mcOutcome').value='';syncDefaults();await loadCoachingHistory(employeeId)
  };
  await loadCoachingHistory(employeeId);
}

async function loadCoachingHistory(employeeId,target='#mcHistory'){
  const host=$m(target);if(!host)return;
  const r=await sbm.from('coaching_moments').select('id,occurred_at,type,category,notes,expected_outcome,include_in_review,resolved_streak,active_carry_forward,record_status').eq('employee_id',employeeId).order('occurred_at',{ascending:false}).limit(50);
  if(r.error){host.innerHTML=`<div class="issue">${escm(r.error.message)}</div>`;return}
  if(!(r.data||[]).length){host.innerHTML='<div class="sub">No coaching moments yet.</div>';return}
  host.innerHTML=(r.data||[]).map(c=>`<div class="history-row"><div><strong>${escm(c.category)}</strong><div class="sub">${escm(String(c.type).replaceAll('_',' '))} · ${new Date(c.occurred_at).toLocaleString()}</div></div><span class="pill ${c.include_in_review&&c.type!=='recognition'?'yellow':'green'}">${escm(stateLabel(c))}</span><p>${escm(c.notes||'')}</p>${c.expected_outcome?`<div class="sub"><strong>Follow-up:</strong> ${escm(c.expected_outcome)}</div>`:''}<div class="sub" style="margin-top:6px"><strong>${c.include_in_review?'Included in next review':'Documentation only'}</strong></div></div>`).join('');
}

async function loadEmployeeWorkspace(){
  const host=$m('#employeesView');if(!host)return;
  try{await loadRoster();const [roles,locs]=await Promise.all([sbm.from('roles').select('id,title').eq('active',true).order('sort_order'),sbm.from('locations').select('id,location_code,name').eq('status','active').order('location_code')]);
  const allowedLocs=locs.data||[];
  host.innerHTML=`<section class="card section"><h3>Employees</h3><div class="sub">Add employees to your location or remove them from the active roster. Historical reviews and coaching are preserved.</div><div class="manager-grid"><div class="invite-card compact"><h4>Add Employee</h4><div class="grid2"><div><label>First name</label><input id="empFirst" class="field"></div><div><label>Last name</label><input id="empLast" class="field"></div></div><div class="grid2"><div><label>Employee ID / code</label><input id="empCode" class="field" placeholder="Optional"></div><div><label>Hire date</label><input id="empHire" type="date" class="field"></div></div><div class="grid2"><div><label>Location</label><select id="empLocation" class="field">${allowedLocs.map(l=>`<option value="${l.id}">Location ${escm(l.location_code)} · ${escm(l.name)}</option>`).join('')}</select></div><div><label>Job title</label><select id="empRole" class="field">${(roles.data||[]).map(r=>`<option value="${r.id}">${escm(r.title)}</option>`).join('')}</select></div></div><button id="empAdd" class="btn primary" style="margin-top:14px">Add Employee</button><span id="empMsg" class="sub" style="margin-left:10px"></span></div><div class="invite-card compact"><h4>Active Roster</h4><div id="empRoster"></div></div></div></section>`;
  renderEmployeeRoster();$m('#empAdd').onclick=async()=>{const first=$m('#empFirst').value.trim(),last=$m('#empLast').value.trim();if(!first||!last){$m('#empMsg').textContent='First and last name are required.';return}const r=await sbm.rpc('manager_add_employee',{p_first_name:first,p_last_name:last,p_employee_code:$m('#empCode').value.trim()||null,p_location_id:$m('#empLocation').value,p_role_id:$m('#empRole').value,p_hire_date:$m('#empHire').value||null});if(r.error){$m('#empMsg').textContent=r.error.message;return}$m('#empMsg').textContent='Employee added.';await loadEmployeeWorkspace()};
  }catch(e){host.innerHTML=`<section class="card section"><div class="issue">${escm(e.message)}</div></section>`}
}

function renderEmployeeRoster(){
  const host=$m('#empRoster');if(!host)return;
  host.innerHTML=roster.map(e=>`<div class="roster-row"><div><strong>${escm(fullName(e))}</strong><div class="sub">${escm(e.role_title)} · Location ${escm(e.location_code)}${e.employee_code?' · '+escm(e.employee_code):''}</div></div><button class="btn secondary empRemove" data-id="${e.employee_id}" data-name="${escm(fullName(e))}">Remove</button></div>`).join('');
  document.querySelectorAll('.empRemove').forEach(b=>b.onclick=async()=>{if(!confirm(`Remove ${b.dataset.name} from the active roster? Their CTOD history will be preserved.`))return;const r=await sbm.rpc('manager_deactivate_employee',{p_employee_id:b.dataset.id});if(r.error){alert(r.error.message);return}await loadEmployeeWorkspace()});
}

async function loadScheduleWorkspace(){
  const host=$m('#scheduleView');if(!host)return;
  try{await loadRoster();host.innerHTML=`<section class="card section"><h3>Review Schedule</h3><div class="sub">Set the date you plan to hold each review. CTOD automatically proposes the following review six months later, and you can edit either date anytime before finalization.</div><div class="tablewrap" style="margin-top:14px"><table class="table schedule-table"><thead><tr><th>Employee</th><th>Current Review Date</th><th>Following Review</th><th>Status</th><th></th></tr></thead><tbody>${roster.map(e=>`<tr data-review="${e.review_id||''}"><td><strong>${escm(fullName(e))}</strong><div class="sub">${escm(e.role_title)} · ${escm(e.location_code)}</div></td><td><input class="field schedCurrent" type="date" value="${escm(e.scheduled_review_date||'')}"></td><td><input class="field schedNext" type="date" value="${escm(e.next_review_date||'')}"></td><td><span class="pill">${escm(String(e.review_status||'No review').replaceAll('_',' '))}</span></td><td><button class="btn primary schedSave" ${e.review_id?'':'disabled'}>Save</button><div class="sub schedMsg"></div></td></tr>`).join('')}</tbody></table></div></section>`;
  document.querySelectorAll('.schedule-table tbody tr').forEach(tr=>{const cur=tr.querySelector('.schedCurrent'),next=tr.querySelector('.schedNext'),save=tr.querySelector('.schedSave'),msg=tr.querySelector('.schedMsg');cur.onchange=()=>{if(cur.value)next.value=addMonths(cur.value,6)};save.onclick=async()=>{if(!cur.value){msg.textContent='Choose review date.';return}const r=await sbm.rpc('manager_set_review_schedule',{p_review_id:tr.dataset.review,p_scheduled_date:cur.value,p_next_review_date:next.value||null});if(r.error){msg.textContent=r.error.message;return}msg.textContent='Saved.';await loadRoster()}});
  }catch(e){host.innerHTML=`<section class="card section"><div class="issue">${escm(e.message)}</div></section>`}
}

async function enhanceReviewDetail(){
  const detail=$m('#reviewDetail');if(!detail||detail.classList.contains('hide')||detail.querySelector('.employee-coaching-history'))return;
  const name=detail.querySelector('h3')?.textContent?.trim();if(!name)return;
  try{if(!roster.length)await loadRoster();const e=roster.find(x=>fullName(x)===name);if(!e)return;const box=document.createElement('div');box.className='invite-card employee-coaching-history';box.innerHTML=`<h4 style="margin-top:0">Coaching History</h4><div id="detailCoachHistory-${e.employee_id}" class="sub">Loading...</div><div class="sub" style="margin-top:8px">Use the Coaching tab for the fastest entry workflow.</div>`;detail.appendChild(box);await loadCoachingHistory(e.employee_id,'#detailCoachHistory-'+e.employee_id)}catch{}
}

function wireTabs(){
  const map={tabReviews:'reviews',tabCoaching:'coaching',tabEmployees:'employees',tabSchedule:'schedule',tabMaster:'master',tabAccess:'access'};
  Object.entries(map).forEach(([id,tab])=>{const el=$m('#'+id);if(el)el.addEventListener('click',()=>setTimeout(()=>showManagerTab(tab),0))});
}

async function init(){
  const invite=new URLSearchParams(location.search).get('invite');if(invite)return;
  for(let i=0;i<40;i++){const app=$m('#app');const session=(await sbm.auth.getSession()).data.session;if(app&&session){break}await new Promise(r=>setTimeout(r,250))}
  if(!(await getMembership()))return;
  if(!['manager','market_leader','area_leader','owner','admin','executive'].includes(membershipM.role))return;
  await loadRoster().catch(()=>{});wireTabs();
  const detail=$m('#reviewDetail');if(detail){new MutationObserver(()=>setTimeout(enhanceReviewDetail,50)).observe(detail,{childList:true,subtree:true})}
}

init();
