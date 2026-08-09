import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const SUPABASE_URL='https://wezcuprboyvbmlnuqdoi.supabase.co';
const SUPABASE_KEY='sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5';
const sbe=createClient(SUPABASE_URL,SUPABASE_KEY);
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
let currentEmployeeId=null;

function injectStyles(){if(document.querySelector('#ctodEmployeeEditStyles'))return;const s=document.createElement('style');s.id='ctodEmployeeEditStyles';s.textContent=`
.employee-edit-backdrop{position:fixed;inset:0;background:rgba(1,8,16,.72);backdrop-filter:blur(7px);z-index:12000;display:grid;place-items:center;padding:20px}.employee-edit-backdrop.hidden{display:none}.employee-edit-modal{width:min(720px,100%);max-height:90vh;overflow:auto;background:linear-gradient(160deg,#091f34,#061420);border:1px solid #275675;border-radius:22px;padding:20px;box-shadow:0 35px 120px rgba(0,0,0,.58);color:#eaf2fb}.employee-edit-modal h3{margin:0;color:#fff;font-size:26px}.edit-lock{background:#071a2b;border:1px solid #173b57;border-radius:12px;padding:12px;color:#79bfff;font-weight:850;letter-spacing:.06em}.edit-actions{display:flex;gap:10px;justify-content:flex-end;margin-top:18px}.edit-note{font-size:11px;color:#7895ad;margin-top:7px}.profile-head>div:last-child{display:flex;gap:8px;flex-wrap:wrap;justify-content:flex-end}
`;document.head.appendChild(s)}

async function getRoster(){const r=await sbe.rpc('manager_workspace_employees');if(r.error)throw r.error;return r.data||[]}
async function getEmployee(employeeId){
 const [emp,assign,roles,locs,roster]=await Promise.all([
  sbe.from('employees').select('id,employee_code,first_name,last_name,hire_date,employment_status').eq('id',employeeId).single(),
  sbe.from('employment_assignments').select('location_id,role_id,effective_from').eq('employee_id',employeeId).is('effective_to',null).order('effective_from',{ascending:false}).limit(1).maybeSingle(),
  sbe.from('roles').select('id,title').eq('active',true).order('sort_order'),
  sbe.from('locations').select('id,location_code,name').eq('status','active').order('location_code'),
  getRoster()
 ]);
 if(emp.error)throw emp.error;if(assign.error)throw assign.error;
 const allowed=new Set((roster||[]).map(x=>x.location_id));
 return {emp:emp.data,assign:assign.data,roles:roles.data||[],locs:(locs.data||[]).filter(l=>allowed.has(l.id))};
}

function ensureModal(){if(document.querySelector('#employeeEditBackdrop'))return;const wrap=document.createElement('div');wrap.id='employeeEditBackdrop';wrap.className='employee-edit-backdrop hidden';wrap.innerHTML=`<div class="employee-edit-modal"><div id="employeeEditBody"></div></div>`;document.body.appendChild(wrap);wrap.addEventListener('click',e=>{if(e.target===wrap)wrap.classList.add('hidden')})}

async function openEditor(employeeId){currentEmployeeId=employeeId;ensureModal();const wrap=document.querySelector('#employeeEditBackdrop'),body=document.querySelector('#employeeEditBody');wrap.classList.remove('hidden');body.innerHTML='<div class="sub">Loading employee information...</div>';
 try{const d=await getEmployee(employeeId);const e=d.emp,a=d.assign||{};body.innerHTML=`<div class="x-eyebrow">Employee 360</div><h3>Edit Info</h3><div class="sub">Update current employee information. Historical assignments and finalized reviews are preserved.</div><label>6-digit employee number</label><div class="edit-lock">${esc(e.employee_code)}</div><div class="edit-note">Permanent CTOD identity. Managers cannot edit this number.</div><div class="grid2"><div><label>First name</label><input id="editFirst" class="field" value="${esc(e.first_name)}"></div><div><label>Last name</label><input id="editLast" class="field" value="${esc(e.last_name)}"></div></div><div class="grid2"><div><label>Hire date</label><input id="editHire" type="date" class="field" value="${esc(e.hire_date||'')}"></div><div><label>Job title</label><select id="editRole" class="field">${d.roles.map(r=>`<option value="${r.id}" ${r.id===a.role_id?'selected':''}>${esc(r.title)}</option>`).join('')}</select></div></div><label>Location</label><select id="editLocation" class="field">${d.locs.map(l=>`<option value="${l.id}" ${l.id===a.location_id?'selected':''}>Location ${esc(l.location_code)} · ${esc(l.name)}</option>`).join('')}</select><div class="edit-note">Managers only see locations they are authorized to manage. A location or role change creates assignment history instead of erasing the prior assignment.</div><div class="edit-actions"><button id="editCancel" class="btn secondary">Cancel</button><button id="editSave" class="btn primary">Save Changes</button></div><div id="editMsg" class="sub"></div>`;
 document.querySelector('#editCancel').onclick=()=>wrap.classList.add('hidden');document.querySelector('#editSave').onclick=async()=>{const msg=document.querySelector('#editMsg'),first=document.querySelector('#editFirst').value.trim(),last=document.querySelector('#editLast').value.trim();if(!first||!last){msg.textContent='First and last name are required.';return}msg.textContent='Saving...';const r=await sbe.rpc('manager_edit_employee',{p_employee_id:employeeId,p_first_name:first,p_last_name:last,p_hire_date:document.querySelector('#editHire').value||null,p_location_id:document.querySelector('#editLocation').value,p_role_id:document.querySelector('#editRole').value});if(r.error){msg.textContent=r.error.message;return}msg.textContent='Saved.';setTimeout(()=>{wrap.classList.add('hidden');document.querySelector('#tabPeople')?.click()},450)};
 }catch(err){body.innerHTML=`<div class="issue">${esc(err.message)}</div><div class="edit-actions"><button class="btn secondary" id="editClose">Close</button></div>`;document.querySelector('#editClose').onclick=()=>wrap.classList.add('hidden')}
}

function enhanceProfile(){const profile=document.querySelector('#personProfile');if(!profile)return;const coach=profile.querySelector('#profileCoach');if(!coach||profile.querySelector('#profileEdit'))return;const code=(profile.querySelector('.profile-number')?.textContent||'').match(/(\d{6})/)?.[1];if(!code)return;getRoster().then(roster=>{const emp=roster.find(x=>String(x.employee_code)===code);if(!emp||document.querySelector('#profileEdit'))return;const edit=document.createElement('button');edit.id='profileEdit';edit.className='x-action';edit.textContent='Edit Info';edit.onclick=()=>openEditor(emp.employee_id);coach.parentElement.appendChild(edit)}).catch(()=>{})}

injectStyles();ensureModal();new MutationObserver(()=>setTimeout(enhanceProfile,20)).observe(document.documentElement,{childList:true,subtree:true});enhanceProfile();