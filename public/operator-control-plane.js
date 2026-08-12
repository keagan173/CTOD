import { ctodConfig, ctodSupabase as sb } from './ctod-config.js';

const host=document.querySelector('#operatorApp');
const context=window.ctodWorkspaceContext||{};
const esc=value=>String(value??'').replace(/[&<>\"]/g,character=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[character]));
const human=value=>String(value??'').replaceAll('_',' ').replace(/\b\w/g,character=>character.toUpperCase());
const fmt=value=>value?new Intl.DateTimeFormat('en-US',{dateStyle:'medium',timeStyle:'short'}).format(new Date(value)):'—';
const compact=value=>new Intl.NumberFormat('en-US',{notation:'compact',maximumFractionDigits:1}).format(Number(value||0));
const statusClass=value=>['healthy','active','ready','current','available'].includes(String(value))?'good':['blocked','failed','closed','suspended'].includes(String(value))?'bad':'warn';
const localDateTime=value=>value?new Date(new Date(value).getTime()-new Date(value).getTimezoneOffset()*60000).toISOString().slice(0,16):'';

let dashboard=null;
let selectedCompanyId=null;
let diagnostics=null;
let provisioningKey=crypto.randomUUID();
let slugTouched=false;

host.innerHTML=`
<style id="ctodOperatorStyles">
  body{background:#050c15;color:#eaf2f7}.shell{max-width:1500px}.brand{display:none}
  #operatorApp{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#eaf2f7}
  .op-shell{--ink:#eaf2f7;--muted:#91a7b8;--line:#20354a;--panel:#0b1724;--panel2:#101f2e;--gold:#d8aa35;--blue:#4bb3e5;--green:#48c78e;--red:#ff6b6b;--orange:#f0a64a;display:grid;gap:18px;padding-bottom:44px}
  .op-header{display:flex;align-items:center;justify-content:space-between;gap:20px;padding:24px 26px;border:1px solid var(--line);border-radius:20px;background:radial-gradient(circle at 100% 0,#153858 0,transparent 45%),linear-gradient(145deg,#0f2132,#08131f);box-shadow:0 20px 60px #0008}
  .op-eyebrow{color:var(--gold);font-size:11px;font-weight:900;letter-spacing:.16em;text-transform:uppercase}.op-header h1{font-size:34px;line-height:1.05;margin:7px 0}.op-header p{color:var(--muted);margin:0;font-size:13px}.op-actions{display:flex;gap:10px;flex-wrap:wrap;justify-content:flex-end}
  .op-btn{appearance:none;border:1px solid #31516d;background:#14283a;color:var(--ink);border-radius:10px;padding:10px 14px;font:800 12px/1.2 inherit;cursor:pointer}.op-btn:hover{border-color:#4b789a;background:#193249}.op-btn.primary{background:var(--gold);border-color:var(--gold);color:#10100d}.op-btn.danger{background:#3a1920;border-color:#7d3541;color:#ffdce2}.op-btn:disabled{opacity:.38;cursor:not-allowed}
  .op-privacy{display:flex;gap:12px;align-items:flex-start;padding:13px 16px;border:1px solid #254561;border-radius:14px;background:#0a1b2a;color:#b9cbd7;font-size:12px}.op-privacy strong{color:#e7f1f7}.op-lock{font-size:18px}
  .op-kpis{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:12px}.op-kpi{padding:16px;border:1px solid var(--line);border-radius:15px;background:var(--panel)}.op-kpi span{display:block;color:var(--muted);font-size:10px;font-weight:900;letter-spacing:.08em}.op-kpi strong{display:block;font-size:28px;margin-top:5px}.op-kpi.attention strong{color:var(--orange)}
  .op-layout{display:grid;grid-template-columns:minmax(0,1.65fr) minmax(300px,.75fr);gap:18px}.op-panel{border:1px solid var(--line);border-radius:18px;background:var(--panel);overflow:hidden}.op-panel-head{display:flex;align-items:flex-start;justify-content:space-between;gap:15px;padding:18px 20px;border-bottom:1px solid var(--line)}.op-panel-head h2,.op-panel-head h3{margin:0;font-size:19px}.op-panel-head p{margin:5px 0 0;color:var(--muted);font-size:12px}.op-panel-body{padding:18px 20px}
  .op-field{width:100%;box-sizing:border-box;border:1px solid #2a465f;border-radius:10px;background:#07131f;color:var(--ink);padding:11px 12px;font:500 13px/1.3 inherit;outline:none}.op-field:focus{border-color:var(--blue);box-shadow:0 0 0 3px #4bb3e51a}.op-field::placeholder{color:#5e7486}.op-field option{background:#07131f}.op-label{display:block;color:#a8bbc9;font-size:11px;font-weight:800;margin:12px 0 6px}.op-grid2{display:grid;grid-template-columns:1fr 1fr;gap:13px}.op-grid3{display:grid;grid-template-columns:repeat(3,1fr);gap:13px}.op-form-actions{display:flex;align-items:center;gap:10px;margin-top:15px;flex-wrap:wrap}
  .op-search{max-width:280px}.op-customer-head,.op-customer-row{display:grid;grid-template-columns:minmax(180px,1.7fr) .7fr .8fr .8fr .8fr .7fr;gap:10px;align-items:center}.op-customer-head{padding:10px 18px;color:#7990a2;font-size:10px;font-weight:900;letter-spacing:.08em;text-transform:uppercase}.op-customer-row{width:100%;padding:14px 18px;border:0;border-top:1px solid #162b3d;background:transparent;color:var(--ink);text-align:left;cursor:pointer}.op-customer-row:hover,.op-customer-row.selected{background:#10283b}.op-customer-row.selected{box-shadow:inset 3px 0 var(--gold)}.op-customer-name strong{display:block;font-size:14px}.op-customer-name small{display:block;color:var(--muted);margin-top:3px}.op-cell{font-size:12px;color:#bfd0dc}.op-badge{display:inline-flex;align-items:center;gap:5px;border:1px solid #34516a;border-radius:999px;padding:5px 8px;font-size:10px;font-weight:900;text-transform:uppercase;letter-spacing:.04em}.op-badge.good{background:#113428;border-color:#24634b;color:#8ae7bb}.op-badge.warn{background:#352a13;border-color:#6c5425;color:#ffd37b}.op-badge.bad{background:#3a1920;border-color:#74313d;color:#ffadb9}
  .op-release{display:flex;justify-content:space-between;gap:12px;padding:12px 0;border-top:1px solid #172c3e}.op-release:first-child{border-top:0}.op-release strong{display:block}.op-release small{color:var(--muted)}
  .op-detail{display:none}.op-detail.visible{display:block}.op-detail-head{display:flex;justify-content:space-between;gap:20px;align-items:flex-start;padding:22px}.op-detail-head h2{margin:4px 0 5px;font-size:28px}.op-detail-head p{color:var(--muted);margin:0}.op-detail-stats{display:grid;grid-template-columns:repeat(6,1fr);border-top:1px solid var(--line);border-bottom:1px solid var(--line)}.op-detail-stat{padding:14px 18px;border-right:1px solid var(--line)}.op-detail-stat:last-child{border-right:0}.op-detail-stat small{display:block;color:var(--muted);font-size:10px;font-weight:800}.op-detail-stat strong{display:block;font-size:20px;margin-top:3px}.op-detail-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;padding:18px}.op-subpanel{border:1px solid #1e374c;border-radius:14px;background:var(--panel2);padding:16px}.op-subpanel h3{margin:0 0 4px;font-size:15px}.op-subpanel>p{color:var(--muted);font-size:11px;margin:0 0 12px}.op-wide{grid-column:1/-1}
  .op-health{display:grid;grid-template-columns:220px 1fr;gap:18px;align-items:start}.op-health-score{padding:18px;border:1px solid #274258;border-radius:13px;background:#081521;text-align:center}.op-health-score strong{display:block;font-size:20px;margin-top:7px}.op-facts{display:grid;grid-template-columns:repeat(4,1fr);gap:8px}.op-fact{padding:11px;border:1px solid #20384b;border-radius:10px;background:#091622}.op-fact small{display:block;color:var(--muted);font-size:9px;text-transform:uppercase}.op-fact strong{display:block;margin-top:4px;font-size:14px}
  .op-table{width:100%;border-collapse:collapse}.op-table th,.op-table td{padding:10px;border-bottom:1px solid #1d3548;text-align:left;font-size:11px}.op-table th{color:#7890a2;text-transform:uppercase;letter-spacing:.06em}.op-table td{color:#c7d6e0}.op-empty{padding:24px;color:var(--muted);text-align:center}.op-audit{display:grid;gap:8px}.op-audit-row{padding:12px;border:1px solid #20394d;border-radius:11px;background:#091622}.op-audit-row strong{font-size:12px}.op-audit-row small{color:var(--muted);display:block;margin-top:4px}.op-audit-row details{margin-top:8px;color:#91a7b8;font-size:10px}.op-audit-row pre{white-space:pre-wrap;word-break:break-word;max-height:220px;overflow:auto}
  .op-bottom{display:grid;grid-template-columns:1fr 1fr;gap:18px}.op-operator{display:grid;grid-template-columns:minmax(150px,1.4fr) 1fr auto;gap:10px;align-items:center;padding:12px 0;border-top:1px solid #1a3144}.op-operator:first-child{border-top:0}.op-operator strong{display:block}.op-operator small{color:var(--muted)}
  .op-notice{position:fixed;right:24px;bottom:24px;z-index:10000;max-width:420px;padding:14px 16px;border:1px solid #3c607c;border-radius:12px;background:#11283a;color:#eaf4fa;box-shadow:0 15px 50px #000b;font-size:12px;font-weight:700}.op-notice.error{border-color:#8d3b48;background:#3b1720;color:#ffd9df}.op-hidden{display:none!important}.op-inline-note{color:var(--muted);font-size:11px}.op-result{margin-top:12px;padding:12px;border:1px solid #2a4c64;border-radius:10px;background:#071521;color:#bdd0dc;font-size:11px;word-break:break-word}.op-result a{color:#72cfff}
  @media(max-width:1100px){.op-kpis{grid-template-columns:repeat(3,1fr)}.op-layout,.op-bottom{grid-template-columns:1fr}.op-detail-grid{grid-template-columns:1fr 1fr}.op-customer-head,.op-customer-row{grid-template-columns:minmax(180px,1.5fr) .8fr .8fr .8fr}.op-customer-head>*:nth-child(n+5),.op-customer-row>*:nth-child(n+5){display:none}.op-detail-stats{grid-template-columns:repeat(3,1fr)}.op-detail-stat:nth-child(3){border-right:0}.op-health{grid-template-columns:1fr}}
  @media(max-width:700px){.op-header{align-items:flex-start;flex-direction:column}.op-actions{justify-content:flex-start}.op-kpis{grid-template-columns:1fr 1fr}.op-detail-grid,.op-grid2,.op-grid3{grid-template-columns:1fr}.op-customer-head,.op-customer-row{grid-template-columns:1fr .7fr .8fr}.op-customer-head>*:nth-child(n+4),.op-customer-row>*:nth-child(n+4){display:none}.op-detail-stats{grid-template-columns:1fr 1fr}.op-detail-stat:nth-child(2n){border-right:0}.op-facts{grid-template-columns:1fr 1fr}.op-operator{grid-template-columns:1fr}.op-panel-head{flex-direction:column}.op-search{max-width:none}}
</style>
<div class="op-shell">
  <header class="op-header">
    <div><div class="op-eyebrow">CTOD Platform Operations</div><h1>Operator Control Plane</h1><p id="opIdentity"></p></div>
    <div class="op-actions"><button id="opRefresh" class="op-btn">Refresh control plane</button><button id="opSignOut" class="op-btn">Sign out</button></div>
  </header>
  <div class="op-privacy"><span class="op-lock">◈</span><div><strong>Privacy boundary enforced.</strong> This workspace exposes customer lifecycle, aggregate health, release, and leader-account metadata. Employee identities and review content are not returned by the operator API.</div></div>
  <section id="opKpis" class="op-kpis"></section>
  <div class="op-layout">
    <section class="op-panel">
      <div class="op-panel-head"><div><h2>Customer directory</h2><p>Lifecycle, configuration lineage, aggregate usage, and operational status.</p></div><input id="opCustomerSearch" class="op-field op-search" type="search" placeholder="Search company, slug, or template"></div>
      <div id="opCustomerHead" class="op-customer-head"><span>Customer</span><span>Lifecycle</span><span>Health</span><span>Core</span><span>Employees</span><span>Locations</span></div>
      <div id="opCustomers"></div>
    </section>
    <aside class="op-panel">
      <div class="op-panel-head"><div><h3>Core release catalog</h3><p>Status registry for controlled customer assignments.</p></div></div>
      <div id="opReleases" class="op-panel-body"></div>
    </aside>
  </div>
  <section id="opDetail" class="op-panel op-detail"></section>
  <div class="op-bottom">
    <section class="op-panel">
      <div class="op-panel-head"><div><h3>Provision customer</h3><p>Creates a tenant from the customer-neutral Blank Standard Master.</p></div><span class="op-badge warn">Admin only</span></div>
      <form id="opProvisionForm" class="op-panel-body">
        <div class="op-grid2"><div><label class="op-label" for="opCompanyName">Company name</label><input id="opCompanyName" class="op-field" required maxlength="160" placeholder="Acme Operations"></div><div><label class="op-label" for="opCompanySlug">Slug</label><input id="opCompanySlug" class="op-field" required maxlength="120" pattern="[a-z0-9]+(?:-[a-z0-9]+)*" placeholder="acme-operations"></div></div>
        <div class="op-grid2"><div><label class="op-label" for="opCompanyTimezone">Timezone</label><input id="opCompanyTimezone" class="op-field" required value="America/Denver"></div><div><label class="op-label" for="opCompanyPlan">Plan code</label><input id="opCompanyPlan" class="op-field" required value="standard" pattern="[a-z0-9][a-z0-9_-]{1,39}"></div></div>
        <div class="op-grid2"><div><label class="op-label" for="opOwnerEmail">Initial owner email (optional)</label><input id="opOwnerEmail" class="op-field" type="email" placeholder="owner@customer.com"></div><div><label class="op-label" for="opTrialDays">Trial days</label><input id="opTrialDays" class="op-field" type="number" min="0" max="365" value="30" required></div></div>
        <label class="op-label"><input id="opSendOwnerInvite" type="checkbox"> Send the owner invitation now</label>
        <div class="op-form-actions"><button class="op-btn primary op-admin-action" type="submit">Provision customer</button><span class="op-inline-note">Retries use one idempotency key until provisioning succeeds.</span></div>
        <div id="opProvisionResult"></div>
      </form>
    </section>
    <section class="op-panel">
      <div class="op-panel-head"><div><h3>Platform operators</h3><p>Independent CTOD identities with no customer membership.</p></div><span class="op-badge warn">Admin only</span></div>
      <div class="op-panel-body"><div id="opOperators"></div>
        <form id="opOperatorForm">
          <h4>Create operator account</h4>
          <div class="op-grid2"><div><label class="op-label" for="opOperatorName">Display name</label><input id="opOperatorName" class="op-field" required maxlength="120"></div><div><label class="op-label" for="opOperatorEmail">Email</label><input id="opOperatorEmail" class="op-field" type="email" required></div></div>
          <div class="op-grid2"><div><label class="op-label" for="opOperatorRole">Role</label><select id="opOperatorRole" class="op-field"><option value="platform_admin">Platform Admin</option><option value="support">Support</option><option value="read_only">Read Only</option></select></div><div><label class="op-label" for="opOperatorPassword">Temporary password</label><input id="opOperatorPassword" class="op-field" type="password" minlength="14" required autocomplete="new-password"></div></div>
          <div class="op-form-actions"><button class="op-btn primary op-admin-action" type="submit">Create operator</button></div>
        </form>
      </div>
    </section>
  </div>
</div>
<div id="opNotice" class="op-notice op-hidden" role="status"></div>`;

const $=selector=>host.querySelector(selector);

function notice(message,error=false){
  const node=$('#opNotice');node.textContent=message;node.classList.toggle('error',error);node.classList.remove('op-hidden');
  clearTimeout(notice.timer);notice.timer=setTimeout(()=>node.classList.add('op-hidden'),5500);
}

async function api(action,payload={}){
  const {data,error}=await sb.functions.invoke('ctod-operator-admin',{body:{action,...payload}});
  if(error){
    let message=error.message||'Operator request failed';
    try{const detail=await error.context?.json();if(detail?.error)message=detail.error}catch{}
    throw new Error(message);
  }
  if(!data?.ok)throw new Error(data?.error||'Operator request failed');
  return data;
}

function isAdmin(){return dashboard?.operator?.role==='platform_admin'}

function renderKpis(){
  const summary=dashboard?.summary||{};
  const items=[['Customers',summary.customers],['Active',summary.active],['Trial',summary.trial],['Suspended',summary.suspended],['Closed',summary.closed],['Need attention',summary.attention,'attention']];
  $('#opKpis').innerHTML=items.map(([label,value,kind])=>`<div class="op-kpi ${kind||''}"><span>${esc(label)}</span><strong>${compact(value)}</strong></div>`).join('');
}

function filteredCustomers(){
  const query=$('#opCustomerSearch').value.trim().toLowerCase();
  const customers=dashboard?.customers||[];
  if(!query)return customers;
  return customers.filter(customer=>[customer.company_name,customer.slug,customer.template_code,customer.plan_code].some(value=>String(value||'').toLowerCase().includes(query)));
}

function renderCustomers(){
  const customers=filteredCustomers();
  $('#opCustomers').innerHTML=customers.length?customers.map(customer=>`
    <button class="op-customer-row ${selectedCompanyId===customer.company_id?'selected':''}" data-company-id="${esc(customer.company_id)}">
      <span class="op-customer-name"><strong>${esc(customer.company_name)}</strong><small>${esc(customer.slug)} · ${esc(customer.template_code||'No template')}</small></span>
      <span><span class="op-badge ${statusClass(customer.account_status)}">${esc(human(customer.account_status))}</span></span>
      <span><span class="op-badge ${statusClass(customer.health_status)}">${esc(human(customer.health_status))}</span></span>
      <span class="op-cell">${esc(customer.core_version||'—')}</span>
      <span class="op-cell">${compact(customer.active_employees)}</span>
      <span class="op-cell">${compact(customer.active_locations)}</span>
    </button>`).join(''):'<div class="op-empty">No customers match this search.</div>';
  $('#opCustomers').querySelectorAll('[data-company-id]').forEach(button=>button.onclick=()=>selectCustomer(button.dataset.companyId));
}

function renderReleases(){
  const releases=dashboard?.releases||[];
  $('#opReleases').innerHTML=releases.length?releases.map(release=>`<div class="op-release"><div><strong>CTOD Core ${esc(release.version_code)}</strong><small>${esc(release.minimum_schema_version?'Schema '+release.minimum_schema_version:'Schema not set')}</small></div><span class="op-badge ${statusClass(release.status)}">${esc(human(release.status))}</span></div><div class="op-inline-note" style="margin:-7px 0 10px">${esc(release.release_notes||'')}</div>`).join(''):'<div class="op-empty">No releases are registered.</div>';
}

function renderOperators(){
  const operators=dashboard?.operators||[];
  $('#opOperators').innerHTML=operators.length?operators.map(operator=>`
    <div class="op-operator" data-operator-id="${esc(operator.user_id)}">
      <div><strong>${esc(operator.display_name||operator.email||'Operator')}</strong><small>${esc(operator.email||operator.user_id)} · Last seen ${esc(fmt(operator.last_seen_at))}</small></div>
      <select class="op-field op-operator-role" ${isAdmin()?'':'disabled'}><option value="platform_admin" ${operator.role==='platform_admin'?'selected':''}>Platform Admin</option><option value="support" ${operator.role==='support'?'selected':''}>Support</option><option value="read_only" ${operator.role==='read_only'?'selected':''}>Read Only</option></select>
      <span class="op-actions"><button class="op-btn op-operator-save" ${isAdmin()?'':'disabled'}>Save role</button><button class="op-btn op-operator-toggle ${operator.active?'danger':''}" ${isAdmin()?'':'disabled'}>${operator.active?'Deactivate':'Reactivate'}</button></span>
    </div>`).join(''):'<div class="op-empty">No operator accounts.</div>';
  $('#opOperators').querySelectorAll('.op-operator-save,.op-operator-toggle').forEach(button=>button.onclick=async()=>{
    const row=button.closest('[data-operator-id]');
    const operator=operators.find(item=>item.user_id===row.dataset.operatorId);
    const toggling=button.classList.contains('op-operator-toggle');
    if(toggling&&operator.active&&!confirm(`Deactivate ${operator.display_name||operator.email}?`))return;
    const nextActive=toggling?!operator.active:operator.active;
    try{
      button.disabled=true;
      await api('update_operator',{user_id:operator.user_id,display_name:operator.display_name||operator.email||'Operator',operator_role:row.querySelector('.op-operator-role').value,active:nextActive});
      notice('Operator account updated.');await refresh();
    }catch(error){notice(error.message,true);button.disabled=false}
  });
}

function renderAdminState(){
  host.querySelectorAll('.op-admin-action').forEach(button=>button.disabled=!isAdmin());
  $('#opProvisionForm').querySelectorAll('input,select').forEach(field=>field.disabled=!isAdmin());
  $('#opOperatorForm').querySelectorAll('input,select').forEach(field=>field.disabled=!isAdmin());
}

function customerFacts(snapshot={}){
  const facts=[['Locations',snapshot.active_locations],['Employees',snapshot.active_employees],['Roles',snapshot.active_roles],['Reviews',snapshot.reviews],['Finalized',snapshot.finalized_reviews],['Leaders',snapshot.active_memberships],['Owner/Admin',snapshot.owner_admin_count],['Pending invites',snapshot.pending_invites]];
  return facts.map(([label,value])=>`<div class="op-fact"><small>${esc(label)}</small><strong>${compact(value)}</strong></div>`).join('');
}

function renderAccess(rows=[]){
  return rows.length?`<div style="overflow:auto"><table class="op-table"><thead><tr><th>Account</th><th>Role</th><th>Status</th><th>Locations</th><th>Created</th></tr></thead><tbody>${rows.map(row=>`<tr><td>${esc(row.email||row.user_id)}</td><td>${esc(human(row.role))}</td><td><span class="op-badge ${row.active?'good':'bad'}">${row.active?'Active':'Inactive'}</span></td><td>${compact(row.location_count)}</td><td>${esc(fmt(row.created_at))}</td></tr>`).join('')}</tbody></table></div>`:'<div class="op-empty">No customer access accounts.</div>';
}

function renderAudit(rows=[]){
  return rows.length?`<div class="op-audit">${rows.map(row=>`<div class="op-audit-row"><strong>${esc(human(String(row.action||'').replaceAll('.',' ')))}</strong><small>${esc(row.actor_email||row.actor_user_id)} · ${esc(fmt(row.occurred_at))}${row.reason?' · '+esc(row.reason):''}</small><details><summary>Audit payload</summary><pre>${esc(JSON.stringify({before:row.before_json,after:row.after_json},null,2))}</pre></details></div>`).join('')}</div>`:'<div class="op-empty">No operator audit events for this customer.</div>';
}

function renderDetail(){
  const customer=(dashboard?.customers||[]).find(item=>item.company_id===selectedCompanyId);
  const detail=diagnostics||{};
  const snapshot=detail.snapshot||customer?.health_summary||{};
  const releases=(dashboard?.releases||[]).filter(release=>release.status==='available');
  const adminDisabled=isAdmin()?'':'disabled';
  const node=$('#opDetail');
  if(!customer){node.classList.remove('visible');node.innerHTML='';return}
  node.classList.add('visible');
  node.innerHTML=`
    <div class="op-detail-head"><div><div class="op-eyebrow">Customer operations</div><h2>${esc(customer.company_name)}</h2><p>${esc(customer.slug)} · ${esc(customer.timezone)} · ${esc(customer.template_name||customer.template_code||'No template')} ${esc(customer.template_version||'')}</p></div><div class="op-actions"><span class="op-badge ${statusClass(customer.account_status)}">${esc(human(customer.account_status))}</span><span class="op-badge ${statusClass(detail.health_status||customer.health_status)}">${esc(human(detail.health_status||customer.health_status))}</span><button id="opRunDiagnostics" class="op-btn">Run diagnostics</button></div></div>
    <div class="op-detail-stats"><div class="op-detail-stat"><small>CORE</small><strong>${esc(customer.core_version)}</strong></div><div class="op-detail-stat"><small>CONFIG</small><strong>${esc(customer.configuration_version||'—')}</strong></div><div class="op-detail-stat"><small>DEPLOYMENT</small><strong>${esc(human(customer.deployment_status))}</strong></div><div class="op-detail-stat"><small>BACKUP</small><strong>${esc(human(customer.backup_status))}</strong></div><div class="op-detail-stat"><small>OWNER / ADMIN</small><strong>${compact(customer.owner_admin_count)}</strong></div><div class="op-detail-stat"><small>LAST HEALTH</small><strong style="font-size:12px">${esc(fmt(customer.last_health_check_at))}</strong></div></div>
    <div class="op-detail-grid">
      <form id="opLifecycleForm" class="op-subpanel"><h3>Customer lifecycle</h3><p>Suspension removes active access and saves an exact reversible hold.</p><label class="op-label">Next status</label><select id="opLifecycleStatus" class="op-field" ${adminDisabled}><option value="trial" ${customer.account_status==='trial'?'selected':''}>Trial</option><option value="active" ${customer.account_status==='active'?'selected':''}>Active</option><option value="suspended" ${customer.account_status==='suspended'?'selected':''}>Suspended</option><option value="closed" ${customer.account_status==='closed'?'selected':''}>Closed</option></select><label class="op-label">Reason</label><textarea id="opLifecycleReason" class="op-field" rows="3" placeholder="Required for suspension or closure" ${adminDisabled}></textarea><div class="op-form-actions"><button class="op-btn ${['suspended','closed'].includes(customer.account_status)?'primary':'danger'}" ${adminDisabled}>Apply lifecycle change</button></div></form>
      <form id="opOperationsForm" class="op-subpanel"><h3>Operational metadata</h3><p>Tracks deployment and backup posture without exposing customer content.</p><div class="op-grid2"><div><label class="op-label">Plan</label><input id="opPlanCode" class="op-field" value="${esc(customer.plan_code)}" ${adminDisabled}></div><div><label class="op-label">Deployment</label><select id="opDeploymentStatus" class="op-field" ${adminDisabled}>${['not_configured','provisioning','ready','degraded','failed'].map(value=>`<option value="${value}" ${customer.deployment_status===value?'selected':''}>${human(value)}</option>`).join('')}</select></div></div><label class="op-label">Deployment URL</label><input id="opDeploymentUrl" class="op-field" type="url" value="${esc(customer.deployment_url||'')}" placeholder="https://customer.example.com" ${adminDisabled}><label class="op-label">Database project reference</label><input id="opDatabaseRef" class="op-field" value="${esc(customer.database_project_ref||'')}" ${adminDisabled}><div class="op-grid2"><div><label class="op-label">Backup</label><select id="opBackupStatus" class="op-field" ${adminDisabled}>${['not_verified','current','stale','failed'].map(value=>`<option value="${value}" ${customer.backup_status===value?'selected':''}>${human(value)}</option>`).join('')}</select></div><div><label class="op-label">Last backup</label><input id="opLastBackup" class="op-field" type="datetime-local" value="${esc(localDateTime(customer.last_backup_at))}" ${adminDisabled}></div></div><label class="op-label">Support notes</label><textarea id="opSupportNotes" class="op-field" rows="3" ${adminDisabled}>${esc(customer.support_notes||'')}</textarea><div class="op-form-actions"><button class="op-btn primary" ${adminDisabled}>Save operations</button></div></form>
      <form id="opReleaseForm" class="op-subpanel"><h3>Core release assignment</h3><p>Records assignment state only; code deployment remains a separate protected workflow.</p><label class="op-label">Action</label><select id="opReleaseAction" class="op-field" ${adminDisabled}><option value="schedule">Schedule</option><option value="activate">Mark activated</option><option value="rollback">Record rollback</option><option value="cancel">Cancel schedule</option></select><label class="op-label">Available version</label><select id="opReleaseVersion" class="op-field" ${adminDisabled}>${releases.map(release=>`<option value="${esc(release.version_code)}">${esc(release.version_code)}</option>`).join('')}</select><label class="op-label">Reason / change reference</label><textarea id="opReleaseReason" class="op-field" rows="3" ${adminDisabled}></textarea><div class="op-form-actions"><button class="op-btn primary" ${adminDisabled}>Record release action</button></div><div class="op-inline-note">Current ${esc(customer.core_version)}${customer.target_core_version?' · Target '+esc(customer.target_core_version):''}${customer.previous_core_version?' · Rollback '+esc(customer.previous_core_version):''}</div></form>
      <section class="op-subpanel op-wide"><div class="op-health"><div class="op-health-score"><span class="op-badge ${statusClass(detail.health_status||customer.health_status)}">Aggregate health</span><strong>${esc(human(detail.health_status||customer.health_status))}</strong><div class="op-inline-note">Checked ${esc(fmt(snapshot.checked_at||customer.last_health_check_at))}</div></div><div class="op-facts">${customerFacts(snapshot)}</div></div></section>
      <section class="op-subpanel op-wide"><h3>Leader and administrator access</h3><p>Account email, role, status, and location count only. No employee identities.</p>${renderAccess(detail.access||[])}</section>
      <section class="op-subpanel op-wide"><h3>Operator audit trail</h3><p>Latest immutable customer-level operator actions.</p>${renderAudit(detail.audit||[])}</section>
    </div>`;
  wireDetailActions();
}

function wireDetailActions(){
  $('#opRunDiagnostics').onclick=async()=>{
    try{$('#opRunDiagnostics').disabled=true;const result=await api('diagnostics',{company_id:selectedCompanyId,record:true});diagnostics=result.diagnostics;notice('Aggregate diagnostics completed.');await refresh({keepSelection:true,skipDiagnostics:true});renderDetail()}catch(error){notice(error.message,true)}finally{const button=$('#opRunDiagnostics');if(button)button.disabled=false}
  };
  $('#opLifecycleForm').onsubmit=async event=>{
    event.preventDefault();const status=$('#opLifecycleStatus').value;const reason=$('#opLifecycleReason').value.trim();
    if(['suspended','closed'].includes(status)&&!reason){notice('A reason is required to suspend or close a customer.',true);return}
    if(!confirm(`Change ${dashboard.customers.find(item=>item.company_id===selectedCompanyId)?.company_name} to ${human(status)}?`))return;
    try{await api('set_status',{company_id:selectedCompanyId,status,reason});notice('Customer lifecycle updated.');await refresh({keepSelection:true})}catch(error){notice(error.message,true)}
  };
  $('#opOperationsForm').onsubmit=async event=>{
    event.preventDefault();
    try{await api('update_customer',{company_id:selectedCompanyId,plan_code:$('#opPlanCode').value,deployment_status:$('#opDeploymentStatus').value,deployment_url:$('#opDeploymentUrl').value,database_project_ref:$('#opDatabaseRef').value,backup_status:$('#opBackupStatus').value,last_backup_at:$('#opLastBackup').value?safeIso($('#opLastBackup').value):null,support_notes:$('#opSupportNotes').value});notice('Customer operations metadata saved.');await refresh({keepSelection:true})}catch(error){notice(error.message,true)}
  };
  $('#opReleaseForm').onsubmit=async event=>{
    event.preventDefault();
    try{await api('set_release',{company_id:selectedCompanyId,release_action:$('#opReleaseAction').value,version:$('#opReleaseVersion').value||null,reason:$('#opReleaseReason').value});notice('Release assignment recorded.');await refresh({keepSelection:true})}catch(error){notice(error.message,true)}
  };
}

function safeIso(value){const date=new Date(value);return Number.isNaN(date.getTime())?null:date.toISOString()}

async function selectCustomer(companyId,{record=false}={}){
  selectedCompanyId=companyId;diagnostics=null;renderCustomers();renderDetail();
  try{const result=await api('diagnostics',{company_id:companyId,record});diagnostics=result.diagnostics;renderDetail();$('#opDetail').scrollIntoView({behavior:'smooth',block:'start'})}catch(error){notice(error.message,true)}
}

async function refresh({keepSelection=true,skipDiagnostics=false}={}){
  const result=await api('dashboard');dashboard=result.dashboard;
  if(!keepSelection||!(dashboard.customers||[]).some(customer=>customer.company_id===selectedCompanyId)){selectedCompanyId=null;diagnostics=null}
  renderKpis();renderCustomers();renderReleases();renderOperators();renderAdminState();renderDetail();
  if(selectedCompanyId&&!skipDiagnostics){const detail=await api('diagnostics',{company_id:selectedCompanyId,record:false});diagnostics=detail.diagnostics;renderDetail()}
}

$('#opIdentity').textContent=[context.email,human(context.role),ctodConfig.environment.toUpperCase(),ctodConfig.projectRef].filter(Boolean).join(' · ');
$('#opRefresh').onclick=async()=>{try{$('#opRefresh').disabled=true;await refresh();notice('Control plane refreshed.')}catch(error){notice(error.message,true)}finally{$('#opRefresh').disabled=false}};
$('#opSignOut').onclick=async()=>{await sb.auth.signOut();location.reload()};
$('#opCustomerSearch').oninput=renderCustomers;
$('#opCompanyName').oninput=()=>{if(!slugTouched)$('#opCompanySlug').value=$('#opCompanyName').value.toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'')};
$('#opCompanySlug').oninput=()=>{slugTouched=true};

$('#opProvisionForm').onsubmit=async event=>{
  event.preventDefault();const button=event.submitter;
  try{
    button.disabled=true;
    const result=await api('provision_customer',{name:$('#opCompanyName').value,slug:$('#opCompanySlug').value,timezone:$('#opCompanyTimezone').value,owner_email:$('#opOwnerEmail').value,plan_code:$('#opCompanyPlan').value,trial_days:Number($('#opTrialDays').value),provisioning_key:provisioningKey,send_owner_invite:$('#opSendOwnerInvite').checked});
    let ownerInviteUrl=result.invite_url;
    if(!ownerInviteUrl&&result.customer?.invite_token){const url=new URL(ctodConfig.appUrl);url.pathname='/';url.search='';url.hash='';url.searchParams.set('invite',result.customer.invite_token);ownerInviteUrl=url.toString()}
    const delivery=result.invite_delivery;
    $('#opProvisionResult').innerHTML=`<div class="op-result"><strong>Customer provisioned.</strong><br>Company ID: ${esc(result.customer.company_id)}<br>Template: ${esc(result.customer.template_code)} ${esc(result.customer.template_version)}${ownerInviteUrl?`<br>Owner activation: <a href="${esc(ownerInviteUrl)}" target="_blank" rel="noreferrer">open invitation link</a>`:''}${delivery?`<br>Delivery: ${esc(delivery.ok?'sent':delivery.error||'not sent')}`:''}</div>`;
    provisioningKey=crypto.randomUUID();slugTouched=false;notice('Customer provisioned from Blank Standard Master.');await refresh();await selectCustomer(result.customer.company_id);
  }catch(error){notice(error.message,true)}finally{button.disabled=!isAdmin()}
};

$('#opOperatorForm').onsubmit=async event=>{
  event.preventDefault();const button=event.submitter;
  try{button.disabled=true;await api('create_operator',{display_name:$('#opOperatorName').value,email:$('#opOperatorEmail').value,operator_role:$('#opOperatorRole').value,password:$('#opOperatorPassword').value});event.target.reset();notice('Platform operator account created.');await refresh()}catch(error){notice(error.message,true)}finally{button.disabled=!isAdmin()}
};

refresh().catch(error=>notice(error.message,true));
