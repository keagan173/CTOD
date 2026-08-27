import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.112.2';

const URL='https://wezcuprboyvbmlnuqdoi.supabase.co';
const KEY='sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5';
const sb=createClient(URL,KEY);
const company=new URLSearchParams(location.search).get('company');
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
const scopedRoles=new Set(['manager','market_leader','area_leader']);
let locations=[];
let users=[];

async function session(){
  const {data:{session}}=await sb.auth.getSession();
  if(!session) throw new Error('Sign in required');
  return session;
}

async function callOwner(action,p={}){
  const s=await session();
  const r=await fetch(URL+'/functions/v1/ctod-owner-api',{
    method:'POST',
    headers:{authorization:'Bearer '+s.access_token,apikey:KEY,'content-type':'application/json'},
    body:JSON.stringify({action,company_id:company,...p})
  });
  const d=await r.json().catch(()=>({}));
  if(!r.ok||!d.ok) throw new Error(typeof d.error==='string'?d.error:'Owner service failed');
  return d;
}

async function callAccess(action,p={}){
  const s=await session();
  const r=await fetch(URL+'/functions/v1/ctod-owner-access-api',{
    method:'POST',
    headers:{authorization:'Bearer '+s.access_token,apikey:KEY,'content-type':'application/json'},
    body:JSON.stringify({action,company_id:company,...p})
  });
  const d=await r.json().catch(()=>({}));
  if(!r.ok||!d.ok) throw new Error(typeof d.error==='string'?d.error:'Access service failed');
  return d;
}

function roleLabel(role){
  return String(role||'').replaceAll('_',' ').replace(/\b\w/g,m=>m.toUpperCase());
}

function accessSummary(user){
  if(!scopedRoles.has(user.role)) return 'Company-wide access';
  const locs=user.locations||[];
  return locs.length?locs.map(l=>'Location '+l.location_code+' '+l.name).join(', '):'No active location access';
}

function renderUsers(){
  const host=document.querySelector('#currentAccessList');
  if(!host) return;
  host.innerHTML=users.length?users.map(u=>`<div class="row access-user-row" data-user="${esc(u.user_id)}">
    <div><b>${esc(u.email)}</b> <span class="pill">${esc(roleLabel(u.role))}</span></div>
    <div class="muted small" style="margin-top:4px">${esc(accessSummary(u))}</div>
    <div style="margin-top:7px"><button class="btn secondary manageAccess" data-user="${esc(u.user_id)}">Manage Access</button></div>
    <div class="accessEditor" id="editor-${esc(u.user_id)}"></div>
  </div>`).join(''):'<div class="muted">No active customer users.</div>';
  document.querySelectorAll('.manageAccess').forEach(b=>b.onclick=()=>openEditor(b.dataset.user));
}

function openEditor(userId){
  const user=users.find(u=>u.user_id===userId);
  const host=document.getElementById('editor-'+userId);
  if(!user||!host) return;
  const active=new Set((user.locations||[]).map(l=>l.id));
  host.innerHTML=`<div class="account-banner" style="margin-top:10px">
    <div class="small muted">Role</div>
    <select class="field accessRole">
      <option value="executive" ${user.role==='executive'?'selected':''}>Executive</option>
      <option value="viewer" ${user.role==='viewer'?'selected':''}>Viewer</option>
      <option value="area_leader" ${user.role==='area_leader'?'selected':''}>Area Leader</option>
      <option value="market_leader" ${user.role==='market_leader'?'selected':''}>Market Leader</option>
      <option value="manager" ${user.role==='manager'?'selected':''}>Manager</option>
    </select>
    <div class="accessScopeHelp muted small"></div>
    <div class="location-box accessLocations">${locations.map(l=>`<label class="loc"><input type="checkbox" value="${esc(l.id)}" ${active.has(l.id)?'checked':''}><span><b>${esc(l.location_code)}</b> ${esc(l.name)} <span class="muted">${esc([l.city,l.state_code].filter(Boolean).join(', '))}</span></span></label>`).join('')}</div>
    <button class="btn primary saveAccess">Save Access</button>
    <button class="btn secondary cancelAccess">Cancel</button>
    <span class="muted small accessSaveMsg" style="margin-left:8px"></span>
  </div>`;
  const role=host.querySelector('.accessRole');
  const locBox=host.querySelector('.accessLocations');
  const help=host.querySelector('.accessScopeHelp');
  const sync=()=>{
    const scoped=scopedRoles.has(role.value);
    help.textContent=scoped?'Choose the only locations this person should be able to access.':'This role receives company-wide access. Location selections are ignored.';
    locBox.style.display=scoped?'block':'none';
  };
  role.onchange=sync; sync();
  host.querySelector('.cancelAccess').onclick=()=>host.innerHTML='';
  host.querySelector('.saveAccess').onclick=async()=>{
    const msg=host.querySelector('.accessSaveMsg');
    try{
      const location_ids=scopedRoles.has(role.value)?[...host.querySelectorAll('.accessLocations input:checked')].map(x=>x.value):[];
      if(scopedRoles.has(role.value)&&!location_ids.length) throw new Error('Select at least one location.');
      msg.textContent='Saving...';
      await callAccess('update',{user_id:user.user_id,role:role.value,location_ids});
      msg.textContent='Saved.';
      await refresh();
    }catch(e){msg.textContent=e.message||String(e)}
  };
}

async function refresh(){
  if(!company) throw new Error('Customer ID missing');
  const [owner,access]=await Promise.all([callOwner('status'),callAccess('list')]);
  locations=(owner.configuration?.locations||[]).filter(l=>l.status==='active');
  users=access.users||[];
  renderUsers();
}

async function mount(){
  const accessCard=[...document.querySelectorAll('section.card')].find(x=>x.querySelector('h2')?.textContent?.trim()==='Access & Invitations');
  if(!accessCard) return;
  const intro=accessCard.querySelector('.muted');
  const panel=document.createElement('div');
  panel.id='currentAccessPanel';
  panel.innerHTML='<div style="border-top:1px solid #edf1f5;margin-top:16px;padding-top:14px"><div class="top"><div><h3 style="margin:0">Current Access</h3><div class="muted small">Change an accepted user’s role or location scope without revoking their login or sending a new invitation.</div></div><button id="refreshCurrentAccess" class="btn secondary">Refresh Access</button></div><div id="currentAccessMsg" class="muted small" style="margin-top:8px"></div><div id="currentAccessList" style="margin-top:8px"></div></div>';
  if(intro) intro.insertAdjacentElement('afterend',panel); else accessCard.prepend(panel);
  document.querySelector('#refreshCurrentAccess').onclick=()=>refresh().catch(e=>{document.querySelector('#currentAccessMsg').textContent=e.message});
  try{await refresh()}catch(e){document.querySelector('#currentAccessMsg').textContent=e.message||String(e)}
}

if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',mount); else mount();
