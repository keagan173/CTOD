import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL='https://wezcuprboyvbmlnuqdoi.supabase.co';
const sb=createClient(SUPABASE_URL,'sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5');
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
const ACCESS_ROLE_LABELS={manager:'Manager',market_leader:'Market Leader',area_leader:'Area Director',executive:'Executive',viewer:'Viewer',owner:'Owner',admin:'Administrator'};
const ACCESS_ROLES=['manager','market_leader','area_leader','viewer'];
let editingLocationId=null;

function injectAdminStyles(){
  if($('#ctodAdminStyles'))return;
  const s=document.createElement('style');
  s.id='ctodAdminStyles';
  s.textContent=`
#locationsAdminView,#rolesAdminView{color:#eaf5ff}
#locationsAdminView .section,#rolesAdminView .section{background:linear-gradient(180deg,#0d2944,#0a2036)!important;border:1px solid rgba(83,201,255,.28)!important;color:#eaf5ff!important}
#locationsAdminView h3,#locationsAdminView h4,#locationsAdminView label,#rolesAdminView h3,#rolesAdminView h4,#rolesAdminView label{color:#f6fbff!important}
#locationsAdminView .sub,#rolesAdminView .sub{color:#a9bfd2!important}
#locationsAdminView .invite-card,#rolesAdminView .invite-card{background:#112f4d!important;border:1px solid rgba(89,198,255,.22)!important}
#locationsAdminView .field,#rolesAdminView .field{background:#f8fbff!important;color:#152337!important;border:1px solid #b9c9d8!important}
#locationsAdminView .tablewrap{background:#0b2238;border:1px solid rgba(89,198,255,.18);border-radius:14px;overflow:auto}
#locationsAdminView .table{color:#eaf5ff!important;min-width:1100px}
#locationsAdminView .table th{background:#102f4c;color:#89d9ff!important;border-bottom:1px solid rgba(89,198,255,.22)!important;position:sticky;top:0;z-index:1}
#locationsAdminView .table td{color:#eaf5ff!important;border-bottom:1px solid rgba(255,255,255,.08)!important;vertical-align:top}
#locationsAdminView .table tbody tr:hover{background:rgba(53,164,224,.12)}
#locationsAdminView .admin-actions{display:flex;gap:8px;white-space:nowrap;flex-wrap:wrap}
#locationsAdminView .admin-edit{background:#1d6fa5;color:white}
#locationsAdminView .admin-danger{background:#5b2630;color:#ffd9df}
#locationsAdminView .admin-activate{background:#185b47;color:#d9fff1}
#locationsAdminView .status-pill{display:inline-block;padding:4px 9px;border-radius:999px;font-size:12px;font-weight:800;background:#174b3a;color:#c9ffe9}
#locationsAdminView .status-pill.inactive{background:#4d2930;color:#ffdce1}
#locationsAdminView .status-pill.pending{background:#5f4a19;color:#ffe9a8}
#locationsAdminView .editor-head{display:flex;justify-content:space-between;align-items:center;gap:12px}
#locationsAdminView #laCancel{display:none}
#locationsAdminView .access-summary{display:grid;gap:4px;min-width:190px}
#locationsAdminView .access-count{font-weight:900;color:#eaf8ff}
#locationsAdminView .access-email{font-size:12px;color:#a9bfd2;overflow:hidden;text-overflow:ellipsis;max-width:230px}
#locationsAdminView .access-panel{display:none;border:1px solid rgba(72,205,255,.48)!important;box-shadow:0 15px 36px rgba(0,0,0,.2);margin:16px 0 20px}
#locationsAdminView .access-panel.open{display:block}
#locationsAdminView .access-person{display:grid;grid-template-columns:minmax(220px,1fr) 150px 160px auto;gap:12px;align-items:center;padding:12px 0;border-top:1px solid rgba(255,255,255,.09)}
#locationsAdminView .access-person:first-child{border-top:0}
#locationsAdminView .access-source{font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:#7bd9ff;font-weight:900}
#locationsAdminView .access-note{padding:12px 14px;border-radius:12px;background:rgba(28,105,150,.18);border:1px solid rgba(77,190,246,.2);color:#cbeaff;margin-top:12px}
#locationsAdminView .access-form{display:grid;grid-template-columns:minmax(230px,1fr) 190px auto;gap:10px;align-items:end;margin-top:14px}
#locationsAdminView .pending-invite{display:flex;justify-content:space-between;gap:12px;align-items:center;padding:12px 0;border-top:1px solid rgba(255,255,255,.09)}
#locationsAdminView .pending-invite:first-child{border-top:0}
#locationsAdminView .access-message{margin-top:10px;min-height:20px;color:#bdeaff}
@media(max-width:760px){#locationsAdminView .grid2{grid-template-columns:1fr}#locationsAdminView .admin-actions{flex-direction:column}#locationsAdminView .access-person,#locationsAdminView .access-form{grid-template-columns:1fr}#locationsAdminView .pending-invite{align-items:flex-start;flex-direction:column}}
`;
  document.head.appendChild(s);
}

function fmtDate(value){
  if(!value)return '—';
  const d=new Date(value);
  return Number.isNaN(d.getTime())?'—':d.toLocaleDateString(undefined,{year:'numeric',month:'short',day:'numeric'});
}

function roleLabel(role){
  return ACCESS_ROLE_LABELS[role]||String(role||'').replaceAll('_',' ');
}

async function isAdmin(){
  const u=(await sb.auth.getUser()).data.user;
  if(!u)return false;
  const r=await sb.from('company_memberships').select('role').eq('user_id',u.id).eq('active',true).maybeSingle();
  return ['owner','admin','executive'].includes(r.data?.role);
}

function install(){
  injectAdminStyles();
  const tabs=$('#app>.tabs');
  if(!tabs||$('#tabLocationsAdmin'))return;
  const master=$('#tabMaster');
  for(const [id,label] of [['tabLocationsAdmin','Locations'],['tabRolesAdmin','Job Roles']]){
    const b=document.createElement('button');
    b.id=id;
    b.className='btn tab secondary';
    b.textContent=label;
    tabs.insertBefore(b,master);
    b.onclick=()=>show(id==='tabLocationsAdmin'?'locationsAdmin':'rolesAdmin');
  }
  for(const id of ['locationsAdminView','rolesAdminView']){
    const v=document.createElement('div');
    v.id=id;
    v.className='view hidden';
    $('#app').appendChild(v);
  }
  document.querySelectorAll('#app>.tabs .tab:not(#tabLocationsAdmin):not(#tabRolesAdmin)').forEach(b=>b.addEventListener('click',()=>{
    $('#locationsAdminView').classList.add('hidden');
    $('#rolesAdminView').classList.add('hidden');
  }));
}

function show(which){
  document.querySelectorAll('#app>.view').forEach(v=>v.classList.add('hidden'));
  document.querySelectorAll('#app>.tabs .tab').forEach(b=>b.classList.remove('active'));
  $('#'+which+'View').classList.remove('hidden');
  $('#tab'+(which==='locationsAdmin'?'LocationsAdmin':'RolesAdmin')).classList.add('active');
  which==='locationsAdmin'?locations():roles();
}

function pendingInvitesFor(locationId,invites){
  const now=Date.now();
  return invites.filter(i=>(i.location_ids||[]).includes(locationId)&&!i.accepted_at&&!i.revoked_at&&new Date(i.expires_at).getTime()>now);
}

function activeAccessFor(locationId,accessRows){
  return accessRows.filter(a=>a.location_id===locationId);
}

function accessSummary(locationId,accessRows,invites){
  const active=activeAccessFor(locationId,accessRows);
  const pending=pendingInvitesFor(locationId,invites);
  const emails=active.slice(0,2).map(a=>a.email).filter(Boolean);
  return `<div class="access-summary"><div class="access-count">${active.length} current${pending.length?` · ${pending.length} pending`:''}</div>${emails.map(email=>`<div class="access-email">${esc(email)}</div>`).join('')}${active.length>2?`<div class="access-email">+${active.length-2} more</div>`:''}</div>`;
}

function accessRoleOptions(selected='manager'){
  return ACCESS_ROLES.map(role=>`<option value="${role}" ${role===selected?'selected':''}>${esc(roleLabel(role))}</option>`).join('');
}

async function renderAccessPanel(location,accessRows,invites){
  const panel=$('#locationAccessPanel');
  if(!panel)return;
  const current=activeAccessFor(location.id,accessRows);
  const pending=pendingInvitesFor(location.id,invites);
  panel.classList.add('open');
  panel.dataset.locationId=location.id;
  panel.innerHTML=`
    <div class="editor-head">
      <div><div class="x-eyebrow">Location Access</div><h4 style="margin:4px 0 0">Location ${esc(location.location_code)} · ${esc(location.name)}</h4></div>
      <button id="locationAccessClose" class="btn secondary">Close</button>
    </div>
    <div class="access-note"><strong>Safe manager change:</strong> invite the new manager, confirm they appear under Current Access, then remove the departing manager. Removing access never deletes employee, coaching, review, transfer, or audit history.</div>
    <h4 style="margin-bottom:4px">Current Access (${current.length})</h4>
    <div id="currentLocationAccess">${current.length?current.map(a=>`
      <div class="access-person" data-user-id="${esc(a.user_id)}">
        <div><strong>${esc(a.email||'Unknown user')}</strong><div class="access-source">${a.access_source==='company_wide'?'Company-wide access':'Location access'}</div></div>
        <div><strong>${esc(roleLabel(a.access_role))}</strong><div class="sub">Role</div></div>
        <div><strong>${esc(fmtDate(a.granted_at))}</strong><div class="sub">Granted</div></div>
        <div>${a.access_source==='location'?`<button class="btn admin-danger removeLocationAccess" data-user-id="${esc(a.user_id)}" data-email="${esc(a.email)}" data-role="${esc(a.access_role)}">Remove Access</button>`:'<span class="status-pill">Company-wide</span>'}</div>
      </div>`).join(''):'<div class="sub" style="padding:12px 0">No location-scoped users currently have access. Company-wide owners and administrators are listed when present.</div>'}</div>
    <h4 style="margin:20px 0 4px">Pending Invites (${pending.length})</h4>
    <div id="pendingLocationInvites">${pending.length?pending.map(i=>`
      <div class="pending-invite" data-invite-id="${esc(i.invite_id)}">
        <div><strong>${esc(i.email)}</strong><div class="sub">${esc(roleLabel(i.intended_role))} · sent ${esc(fmtDate(i.created_at))} · expires ${esc(fmtDate(i.expires_at))}</div></div>
        <button class="btn admin-danger revokeLocationInvite" data-invite-id="${esc(i.invite_id)}">Revoke Invite</button>
      </div>`).join(''):'<div class="sub" style="padding:12px 0">No pending invitations for this location.</div>'}</div>
    <h4 style="margin:20px 0 4px">Give Access</h4>
    <div class="sub">Existing CTOD users are granted this location immediately. New or inactive users receive an activation email and create their own password.</div>
    <div class="access-form">
      <div><label>Email</label><input id="locationAccessEmail" type="email" class="field" placeholder="manager@company.com"></div>
      <div><label>Access Role</label><select id="locationAccessRole" class="field">${accessRoleOptions()}</select></div>
      <button id="locationAccessGrant" class="btn primary">Grant / Send Invite</button>
    </div>
    <div id="locationAccessMsg" class="access-message"></div>`;

  $('#locationAccessClose').onclick=()=>{
    panel.classList.remove('open');
    panel.innerHTML='';
  };

  panel.querySelectorAll('.removeLocationAccess').forEach(button=>button.onclick=async()=>{
    const email=button.dataset.email||'this user';
    if(!confirm(`Remove ${email}'s access to Location ${location.location_code}? Their employee, coaching, review, transfer, and audit history will remain unchanged.`))return;
    button.disabled=true;
    const result=await sb.rpc('admin_set_location_access',{
      p_location_id:location.id,
      p_user_id:button.dataset.userId,
      p_active:false,
      p_access_role:button.dataset.role||'manager'
    });
    if(result.error){
      button.disabled=false;
      $('#locationAccessMsg').textContent=result.error.message;
      return;
    }
    await locations(location.id);
    $('#locationAccessMsg').textContent=`Access removed for ${email}. Historical records were preserved.`;
  });

  panel.querySelectorAll('.revokeLocationInvite').forEach(button=>button.onclick=async()=>{
    if(!confirm('Revoke this pending invitation?'))return;
    button.disabled=true;
    const result=await sb.rpc('revoke_access_invite',{p_invite_id:button.dataset.inviteId});
    if(result.error){
      button.disabled=false;
      $('#locationAccessMsg').textContent=result.error.message;
      return;
    }
    await locations(location.id);
    $('#locationAccessMsg').textContent='Invitation revoked.';
  });

  $('#locationAccessGrant').onclick=async()=>{
    const button=$('#locationAccessGrant');
    const email=$('#locationAccessEmail').value.trim().toLowerCase();
    const role=$('#locationAccessRole').value;
    const msg=$('#locationAccessMsg');
    if(!email||!email.includes('@')){msg.textContent='Enter a valid email address.';return}
    button.disabled=true;
    msg.textContent='Checking CTOD access...';

    const direct=await sb.rpc('admin_grant_location_access_by_email',{
      p_location_id:location.id,
      p_email:email,
      p_access_role:role
    });
    if(direct.error){
      button.disabled=false;
      msg.textContent=direct.error.message;
      return;
    }
    if(direct.data?.status==='granted'){
      await locations(location.id);
      $('#locationAccessMsg').textContent=`${email} now has access to Location ${location.location_code}.`;
      return;
    }
    if(direct.data?.status==='already_company_wide'){
      button.disabled=false;
      msg.textContent=`${email} already has company-wide access, including this location.`;
      return;
    }

    msg.textContent='Creating invitation...';
    const created=await sb.rpc('create_access_invite',{p_email:email,p_role:role,p_location_ids:[location.id]});
    if(created.error){
      button.disabled=false;
      msg.textContent=created.error.message;
      return;
    }
    const session=(await sb.auth.getSession()).data.session;
    if(!session){
      button.disabled=false;
      msg.textContent='Your session expired. Sign in again before sending an invitation.';
      return;
    }
    let delivery={};
    try{
      const deliveryRequestId=crypto.randomUUID();
      const response=await fetch(SUPABASE_URL+'/functions/v1/send-ctod-invite',{
        method:'POST',
        headers:{authorization:'Bearer '+session.access_token,'content-type':'application/json'},
        body:JSON.stringify({invite_id:created.data.invite_id,delivery_request_id:deliveryRequestId})
      });
      delivery=await response.json();
      if(!response.ok||delivery.error)throw new Error(delivery.error||'Invitation delivery failed');
    }catch(error){
      delivery={email_sent:false,message:error.message,invite_url:location.origin+'/?invite='+created.data.token};
    }
    await locations(location.id);
    const nextMsg=$('#locationAccessMsg');
    if(delivery.existing_user_updated){
      nextMsg.textContent=`${email} now has access to Location ${location.location_code}.`;
    }else if(delivery.email_sent){
      nextMsg.textContent=`Activation email ${created.data?.reused?'resent':'sent'} to ${email}. Access will appear here after activation.`;
    }else{
      nextMsg.textContent=`Invitation created for ${email}, but automatic email delivery was not confirmed. Use the main Access tab to copy the activation link.`;
    }
  };
}

async function locations(openAccessId=null){
  const h=$('#locationsAdminView');
  h.innerHTML='<section class="card section"><div class="sub">Loading locations and access...</div></section>';
  const [locationResult,accessResult,inviteResult]=await Promise.all([
    sb.from('locations').select('*').order('location_code'),
    sb.rpc('admin_list_location_access'),
    sb.rpc('list_access_invites')
  ]);
  const firstError=locationResult.error||accessResult.error||inviteResult.error;
  if(firstError){
    h.innerHTML='<section class="card section"><div class="issue">'+esc(firstError.message)+'</div></section>';
    return;
  }
  const locationRows=locationResult.data||[];
  const accessRows=accessResult.data||[];
  const invites=inviteResult.data||[];
  h.innerHTML=`<section class="card section">
    <div class="x-eyebrow">Company Structure</div>
    <h3>Locations</h3>
    <div class="sub">Master location directory, current access, pending manager invitations, and store status. Access changes preserve all historical records.</div>
    <div id="locationAccessPanel" class="invite-card access-panel"></div>
    <div class="invite-card">
      <div class="editor-head"><h4 id="laEditorTitle">Add Location</h4><button id="laCancel" class="btn secondary">Cancel Edit</button></div>
      <div class="grid2">
        <div><label>Location #</label><input id="laCode" class="field" maxlength="3"></div>
        <div><label>Name</label><input id="laName" class="field"></div>
        <div><label>Address</label><input id="laAddress" class="field"></div>
        <div><label>City</label><input id="laCity" class="field"></div>
        <div><label>State</label><input id="laState" class="field" maxlength="2"></div>
        <div><label>ZIP</label><input id="laZip" class="field"></div>
        <div><label>Market</label><input id="laMarket" class="field"></div>
        <div><label>Area</label><input id="laArea" class="field"></div>
      </div>
      <button id="laAdd" class="btn primary" style="margin-top:12px">Add Location</button><span id="laMsg" class="sub" style="margin-left:10px"></span>
    </div>
    <div class="tablewrap"><table class="table"><thead><tr><th>Location</th><th>Name</th><th>City / State</th><th>Market</th><th>Area</th><th>Current Access</th><th>Status</th><th>Actions</th></tr></thead><tbody>${locationRows.map(x=>`
      <tr data-location-id="${esc(x.id)}">
        <td><strong>${esc(x.location_code)}</strong></td>
        <td>${esc(x.name)}</td>
        <td>${esc(x.city||'')} ${esc(x.state_code||'')}</td>
        <td>${esc(x.market_name||'')}</td>
        <td>${esc(x.area_name||'')}</td>
        <td>${accessSummary(x.id,accessRows,invites)}</td>
        <td><span class="status-pill ${x.status==='active'?'':'inactive'}">${esc(x.status)}</span></td>
        <td><div class="admin-actions"><button class="btn admin-edit locAccess">Manage Access</button><button class="btn admin-edit locEdit">Edit</button><button class="btn ${x.status==='active'?'admin-danger':'admin-activate'} locToggle">${x.status==='active'?'Deactivate':'Activate'}</button></div></td>
      </tr>`).join('')}</tbody></table></div>
  </section>`;

  const reset=()=>{
    editingLocationId=null;
    $('#laEditorTitle').textContent='Add Location';
    $('#laAdd').textContent='Add Location';
    $('#laCancel').style.display='none';
    ['laCode','laName','laAddress','laCity','laState','laZip','laMarket','laArea'].forEach(id=>$('#'+id).value='');
    $('#laMsg').textContent='';
  };
  $('#laCancel').onclick=reset;
  $('#laAdd').onclick=async()=>{
    const payload={
      p_location_id:editingLocationId,
      p_location_code:$('#laCode').value,
      p_name:$('#laName').value,
      p_address:$('#laAddress').value||null,
      p_city:$('#laCity').value||null,
      p_state:$('#laState').value||null,
      p_postal:$('#laZip').value||null,
      p_market:$('#laMarket').value||null,
      p_area:$('#laArea').value||null
    };
    const result=await sb.rpc('admin_upsert_location',payload);
    $('#laMsg').textContent=result.error?result.error.message:(editingLocationId?'Location updated.':'Location added.');
    if(!result.error){editingLocationId=null;setTimeout(()=>locations(),250)}
  };
  document.querySelectorAll('.locAccess').forEach(button=>button.onclick=()=>{
    const row=button.closest('tr');
    const location=locationRows.find(value=>value.id===row.dataset.locationId);
    if(!location)return;
    renderAccessPanel(location,accessRows,invites);
    $('#locationAccessPanel').scrollIntoView({behavior:'smooth',block:'start'});
  });
  document.querySelectorAll('.locEdit').forEach(button=>button.onclick=()=>{
    const row=button.closest('tr');
    const x=locationRows.find(value=>value.id===row.dataset.locationId);
    if(!x)return;
    editingLocationId=x.id;
    $('#laEditorTitle').textContent=`Edit Location ${x.location_code}`;
    $('#laAdd').textContent='Save Changes';
    $('#laCancel').style.display='inline-block';
    $('#laCode').value=x.location_code||'';
    $('#laName').value=x.name||'';
    $('#laAddress').value=x.address_line1||'';
    $('#laCity').value=x.city||'';
    $('#laState').value=x.state_code||'';
    $('#laZip').value=x.postal_code||'';
    $('#laMarket').value=x.market_name||'';
    $('#laArea').value=x.area_name||'';
    $('#laMsg').textContent='';
    document.querySelector('#locationsAdminView .invite-card:not(.access-panel)').scrollIntoView({behavior:'smooth',block:'start'});
  });
  document.querySelectorAll('.locToggle').forEach(button=>button.onclick=async()=>{
    const row=button.closest('tr');
    const x=locationRows.find(value=>value.id===row.dataset.locationId);
    if(!x)return;
    const makingActive=x.status!=='active';
    const ok=confirm(`${makingActive?'Activate':'Deactivate'} Location ${x.location_code} - ${x.name}? ${makingActive?'It will return to active company reporting.':'Historical employee and review data will be preserved.'}`);
    if(!ok)return;
    button.disabled=true;
    const result=await sb.rpc('admin_set_location_active',{p_location_id:x.id,p_active:makingActive});
    if(result.error){alert(result.error.message);button.disabled=false}else locations();
  });
  if(openAccessId){
    const location=locationRows.find(value=>value.id===openAccessId);
    if(location)await renderAccessPanel(location,accessRows,invites);
  }
}

async function roles(){
  const h=$('#rolesAdminView');
  h.innerHTML='<section class="card section"><div class="sub">Loading job roles...</div></section>';
  const r=await sb.from('roles').select('*').order('sort_order');
  if(r.error){h.innerHTML='<section class="card section"><div class="issue">'+esc(r.error.message)+'</div></section>';return}
  h.innerHTML=`<section class="card section"><div class="x-eyebrow">Review Architecture</div><h3>Job Roles & Questions</h3><div class="sub">Add/deactivate job titles and control the review questions attached to each role.</div><div class="invite-card"><label>New Job Role</label><div class="actions"><input id="raTitle" class="field" style="max-width:420px"><button id="raAdd" class="btn primary">Add Role</button></div><div id="raMsg" class="sub"></div></div><div id="roleCards">${(r.data||[]).map(x=>`<div class="invite-card role-admin" data-id="${x.id}"><div class="workspace-head"><div><h4>${esc(x.title)}</h4><div class="sub">${x.active?'Active':'Inactive'}</div></div><div class="actions"><button class="btn secondary roleQuestions">Edit Questions</button><button class="btn secondary roleToggle">${x.active?'Deactivate':'Activate'}</button></div></div><div class="questionEditor"></div></div>`).join('')}</div></section>`;
  $('#raAdd').onclick=async()=>{
    const x=await sb.rpc('admin_upsert_role',{p_title:$('#raTitle').value});
    $('#raMsg').textContent=x.error?x.error.message:'Role added.';
    if(!x.error)roles();
  };
  document.querySelectorAll('.role-admin').forEach(card=>{
    const role=(r.data||[]).find(x=>x.id===card.dataset.id);
    card.querySelector('.roleToggle').onclick=async()=>{await sb.rpc('admin_set_role_active',{p_role_id:role.id,p_active:!role.active});roles()};
    card.querySelector('.roleQuestions').onclick=()=>questions(card,role);
  });
}

async function questions(card,role){
  const box=card.querySelector('.questionEditor');
  const r=await sb.from('question_definitions').select('id,question_text,section_name,category,sort_order,active').eq('role_id',role.id).order('sort_order');
  if(r.error){box.innerHTML='<div class="issue">'+esc(r.error.message)+'</div>';return}
  box.innerHTML=`<div style="margin-top:14px"><div class="grid2"><div><label>New Question</label><input class="field qNew"></div><div><label>Section</label><input class="field qSection" value="Performance"></div></div><button class="btn primary qAdd" style="margin-top:10px">Add Question</button>${(r.data||[]).map(q=>`<div class="history-row" data-q="${q.id}"><label>Question</label><input class="field qText" value="${esc(q.question_text)}"><div class="actions" style="margin-top:8px"><button class="btn secondary qSave">Save</button><button class="btn secondary qToggle">${q.active?'Deactivate':'Activate'}</button></div></div>`).join('')}</div>`;
  box.querySelector('.qAdd').onclick=async()=>{
    await sb.rpc('admin_upsert_question',{p_role_id:role.id,p_question_text:box.querySelector('.qNew').value,p_section_name:box.querySelector('.qSection').value,p_category:'Performance',p_sort_order:(r.data||[]).length*10+10});
    questions(card,role);
  };
  box.querySelectorAll('[data-q]').forEach(row=>{
    const q=(r.data||[]).find(x=>x.id===row.dataset.q);
    row.querySelector('.qSave').onclick=async()=>{
      await sb.rpc('admin_upsert_question',{p_question_id:q.id,p_role_id:role.id,p_question_text:row.querySelector('.qText').value,p_section_name:q.section_name,p_category:q.category,p_sort_order:q.sort_order});
      questions(card,role);
    };
    row.querySelector('.qToggle').onclick=async()=>{
      await sb.rpc('admin_set_question_active',{p_question_id:q.id,p_active:!q.active});
      questions(card,role);
    };
  });
}

(async()=>{
  for(let i=0;i<50;i++){
    if($('#app')&&!$('#app').hidden)break;
    await new Promise(resolve=>setTimeout(resolve,200));
  }
  if(await isAdmin())install();
})();
