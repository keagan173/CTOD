import { assertSandboxEmailAllowed,ctodConfig,ctodSupabase as sb } from './ctod-config.js';
import { formatDate,uniqueGoals } from './display-utils.js?v=20260810-001';

const SUPABASE_URL=ctodConfig.supabaseUrl;
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
const fmt=formatDate;
const today=()=>new Date().toISOString().slice(0,10);
let membership=null,locations=[],currentReview=null,currentForm=null;
const params=new URLSearchParams(location.search); const inviteToken=params.get('invite');
const pendingReviewKey='ctodPendingReviewId';
let resolveWorkspaceReady,workspaceReadyResolved=false;
window.ctodWorkspaceReady=new Promise(resolve=>{resolveWorkspaceReady=resolve});

function publishWorkspaceContext(user,scopeRows=[]){
  const role=membership?.role||null;
  const isMaster=['owner','admin','executive'].includes(role);
  const scopedLocations=(scopeRows||[]).map(row=>{
    const loc=Array.isArray(row.locations)?row.locations[0]:row.locations;
    return loc?{id:row.location_id,location_code:loc.location_code,name:loc.name,access_role:row.access_role}:null;
  }).filter(Boolean);
  const one=scopedLocations.length===1?scopedLocations[0]:null;
  const workspaceLabel=isMaster?'Master Workspace · Company-wide':one?`LOC${String(one.location_code).padStart(3,'0')} Workspace · ${one.name}`:scopedLocations.length?`${scopedLocations.length} Location Workspace`:'No active location access';
  const context={companyId:membership?.company_id||null,role,isMaster,isOperator:false,isActiveCompany:true,locations:scopedLocations,userId:user?.id||null,email:user?.email||null,workspaceLabel};
  window.ctodWorkspaceContext=context;
  document.documentElement.dataset.ctodWorkspace=isMaster?'master':'location';
  document.documentElement.dataset.ctodRole=role||'none';
  const title=$('.top h2');if(title)title.textContent=isMaster?'CTOD Master':one?`LOC${String(one.location_code).padStart(3,'0')} Workspace`:'CTOD Location Workspace';
  const who=$('#who');if(who)who.textContent=[user?.email,workspaceLabel].filter(Boolean).join(' · ');
  if(!workspaceReadyResolved){workspaceReadyResolved=true;resolveWorkspaceReady(context)}
  document.dispatchEvent(new CustomEvent('ctod:workspace-ready',{detail:context}));
  return context;
}

function publishOperatorContext(user,operator){
  const role=operator?.role||'read_only';
  const workspaceLabel='CTOD Platform · Operator Control Plane';
  const context={companyId:null,role,isMaster:false,isOperator:true,isActiveCompany:false,locations:[],userId:user?.id||null,email:user?.email||null,workspaceLabel,operator};
  window.ctodWorkspaceContext=context;
  document.documentElement.dataset.ctodWorkspace='operator';
  document.documentElement.dataset.ctodRole=role;
  if(!workspaceReadyResolved){workspaceReadyResolved=true;resolveWorkspaceReady(context)}
  document.dispatchEvent(new CustomEvent('ctod:workspace-ready',{detail:context}));
  return context;
}

function publishInactiveContext(user,latestMembership,company){
  const companyName=company?.name||'CTOD customer workspace';
  const isSuspended=company?.status==='inactive';
  const workspaceLabel=isSuspended?`${companyName} · Access paused`:'No active customer workspace';
  const context={companyId:latestMembership?.company_id||null,role:latestMembership?.role||null,isMaster:false,isOperator:false,isActiveCompany:false,locations:[],userId:user?.id||null,email:user?.email||null,workspaceLabel,companyStatus:company?.status||null};
  window.ctodWorkspaceContext=context;
  document.documentElement.dataset.ctodWorkspace='inactive';
  document.documentElement.dataset.ctodRole=latestMembership?.role||'none';
  $('#accountStateTitle').textContent=isSuspended?'Customer access is paused':'No workspace is assigned';
  $('#accountStateMessage').textContent=isSuspended
    ? `${companyName} is currently suspended or closed. Your sign-in remains intact, but customer data is unavailable until a CTOD platform administrator reactivates the account.`
    : 'This sign-in is valid, but it does not have an active customer workspace. Contact your company owner or CTOD support.';
  $('#accountStateWho').textContent=user?.email||'';
  $('#accountState').hidden=false;
  if(!workspaceReadyResolved){workspaceReadyResolved=true;resolveWorkspaceReady(context)}
  document.dispatchEvent(new CustomEvent('ctod:workspace-ready',{detail:context}));
  return context;
}

async function probeOperator(){
  const {data}=await sb.functions.invoke('ctod-operator-admin',{body:{action:'context'}});
  return data?.ok&&data?.operator?data:null;
}

function setTab(which){
  for(const x of ['reviews','master','access']) $('#'+x+'View').classList.toggle('hidden',x!==which);
  for(const [id,x] of [['tabReviews','reviews'],['tabMaster','master'],['tabAccess','access']]) $('#'+id).classList.toggle('active',x===which);
}

async function boot(){
  if(inviteToken){await showInviteSetup();return}
  const s=await sb.auth.getSession();
  if(s.data.session) await showApp(); else $('#auth').hidden=false;
}

async function showInviteSetup(){
  $('#inviteSetup').hidden=false;
  try{
    const r=await fetch(SUPABASE_URL+'/functions/v1/complete-ctod-invite?token='+encodeURIComponent(inviteToken));
    const data=await r.json();
    if(!r.ok||!data.ok){$('#inviteMsg').textContent=data.error||'Invite is invalid.';$('#activateInvite').disabled=true;return}
    if(!data.active){$('#inviteMsg').textContent=data.accepted?'Invite already accepted. Sign in with your CTOD password.':'Invite is no longer active.';$('#activateInvite').disabled=true;return}
    $('#inviteEmail').textContent=data.email+' • '+String(data.role||'').replaceAll('_',' ');
    $('#inviteMsg').textContent='Invitation verified. Create your password below.';
  }catch(e){$('#inviteMsg').textContent='Could not validate invitation.';$('#activateInvite').disabled=true}
}

async function activateInvite(){
  const p=$('#invitePassword').value,p2=$('#invitePassword2').value;
  if(p.length<8){$('#inviteMsg').textContent='Password must be at least 8 characters.';return}
  if(p!==p2){$('#inviteMsg').textContent='Passwords do not match.';return}
  $('#activateInvite').disabled=true;$('#inviteMsg').textContent='Activating access...';
  const r=await fetch(SUPABASE_URL+'/functions/v1/complete-ctod-invite',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({token:inviteToken,password:p})});
  const data=await r.json();
  if(!r.ok||!data.ok){$('#inviteMsg').textContent=data.error||'Could not activate invite.';$('#activateInvite').disabled=false;return}
  const s=await sb.auth.signInWithPassword({email:data.email,password:p});
  if(s.error){$('#inviteMsg').textContent='Access activated. Return to sign in.';setTimeout(()=>location.href='/',1200);return}
  history.replaceState({},'',location.pathname);$('#inviteSetup').hidden=true;await showApp();
}

async function signin(){
  const r=await sb.auth.signInWithPassword({email:$('#email').value.trim(),password:$('#password').value});
  if(r.error){$('#authMsg').textContent=r.error.message;return}
  await showApp();
}

async function showApp(){
  $('#auth').hidden=true;$('#inviteSetup').hidden=true;$('#app').hidden=true;$('#operatorApp').hidden=true;$('#accountState').hidden=true;
  const u=await sb.auth.getUser();const user=u.data.user;
  if(!user){await sb.auth.signOut();location.reload();return}
  const operator=await probeOperator();
  if(operator){
    publishOperatorContext(user,operator.operator);
    $('#operatorApp').hidden=false;
    return;
  }
  const context=await loadMembership(user);
  if(!context?.isActiveCompany)return;
  $('#app').hidden=false;
  await loadAll();await resumePendingReview();
}

async function loadMembership(u){
  const r=await sb.from('company_memberships').select('company_id,role,active,created_at').eq('user_id',u.id).eq('active',true).order('created_at',{ascending:false}).limit(1).maybeSingle();
  membership=r.data;
  if(!membership){
    const latest=await sb.from('company_memberships').select('company_id,role,active,created_at').eq('user_id',u.id).order('created_at',{ascending:false}).limit(1).maybeSingle();
    const company=latest.data?.company_id
      ? await sb.from('companies').select('id,name,status').eq('id',latest.data.company_id).maybeSingle()
      : {data:null};
    return publishInactiveContext(u,latest.data,company.data);
  }
  const isOwner=['owner','admin','executive'].includes(membership?.role);
  const access=membership?await sb.from('user_location_access').select('location_id,access_role,locations(location_code,name)').eq('company_id',membership.company_id).eq('user_id',u.id).eq('active',true):{data:[]};
  const context=publishWorkspaceContext(u,access.data||[]);
  $('#tabMaster').style.display=isOwner?'':'none';
  $('#tabAccess').style.display=['owner','admin'].includes(membership?.role)?'':'none';
  setTab(isOwner?'master':'reviews');
  return context;
}

async function loadAll(){
  const [reviews,coach,goals,promo]=await Promise.all([
    sb.from('reviews').select('id,employee_id,status,review_date,next_review_date,finalized_at,overall_rating_label,promotion_readiness,raise_recommendation,employees!reviews_employee_id_fkey(first_name,last_name),locations(name,location_code)').order('updated_at',{ascending:false}),
    sb.from('coaching_moments').select('id',{count:'exact',head:true}).eq('active_carry_forward',true),
    sb.from('goals').select('id,employee_id,goal_text,status,target_date').in('status',['not_started','in_progress']),
    sb.from('v_promotion_readiness').select('*').order('readiness_score',{ascending:false})
  ]);
  if(reviews.error){$('#openReviews').innerHTML='<div class="issue">'+esc(reviews.error.message)+'</div>';return}
  const rows=reviews.data||[];const open=rows.filter(x=>x.status!=='finalized'),done=rows.filter(x=>x.status==='finalized');
  $('#kOpen').textContent=open.length;$('#kFinal').textContent=done.length;$('#kCoach').textContent=coach.count||0;$('#kGoals').textContent=uniqueGoals(goals.data||[]).length;
  renderReviews(open,$('#openReviews'));renderReviews(done,$('#doneReviews'));renderReviews(done,$('#masterReviews'));renderMaster(promo.data||[]);
  if(['owner','admin'].includes(membership?.role)) await loadAccess();
}

function nameOf(r){const e=r.employees||{};return ((e.first_name||'')+' '+(e.last_name||'')).trim()||'Employee'}
function statusLabel(s){return String(s||'').replaceAll('_',' ')}
function renderReviews(rows,host){
  host.innerHTML=rows.length?'':'<div class="sub">No reviews.</div>';
  rows.forEach(r=>{const b=document.createElement('button');b.className='review';
    const when=r.status==='finalized'?'Finalized '+fmt(r.finalized_at||r.review_date):(r.status==='not_due'?'Next '+fmt(r.next_review_date):statusLabel(r.status));
    b.innerHTML='<div><strong>'+esc(nameOf(r))+'</strong><span>'+esc((r.locations?.location_code?'Location '+r.locations.location_code+' • ':'')+when)+'</span></div><span class="pill">'+esc(r.status==='finalized'?(r.overall_rating_label||'Finalized'):statusLabel(r.status))+'</span>';
    b.onclick=()=>openReview(r.id);host.appendChild(b)});
}

function renderMaster(rows){
  let n=0,y=0,l=0,not=0;rows.forEach(r=>{if(r.readiness==='Ready Now')n++;else if(r.readiness==='Ready in 1 Year')y++;else if(r.readiness==='Ready in 2-3 Years')l++;else not++});
  $('#gNow').textContent=n;$('#gYear').textContent=y;$('#gLater').textContent=l;$('#gNot').textContent=not;
  $('#promoBody').innerHTML=rows.map(r=>'<tr><td><strong>'+esc(r.employee_name)+'</strong></td><td>'+esc(r.location_code||'')+'</td><td>'+esc(r.current_job_title||'')+'</td><td>'+esc(r.target_role||'')+'</td><td><span class="pill '+esc(r.readiness_light||'red')+'">'+esc(r.readiness||'Not set')+'</span></td><td>'+esc(r.active_goals||0)+'</td><td>'+esc(r.active_coaching||0)+'</td><td>'+esc(fmt(r.last_review_date))+'</td></tr>').join('');
}

async function openReview(id){
  currentReview=id;$('#reviewDetail').classList.remove('hide');$('#reviewDetail').innerHTML='<div class="sub">Loading review workspace...</div>';$('#reviewDetail').scrollIntoView({behavior:'smooth'});
  const {data,error}=await sb.rpc('get_review_form',{p_review_id:id});
  if(error){$('#reviewDetail').innerHTML='<div class="issue">'+esc(error.message)+'</div>';return}
  currentForm=data;
  if(data.review.status==='finalized'){renderFinalizedReview(data);return}
  if(['not_due','queued','reopened'].includes(data.review.status)){renderStartReview(data);return}
  await renderReviewEditor(data);
}

async function openPreparedReview(id,{refresh=true}={}){
  if(!id)throw new Error('Review ID is required.');
  setTab('reviews');
  if(refresh)await loadAll();
  await openReview(id);
}

async function resumePendingReview(){
  const id=sessionStorage.getItem(pendingReviewKey);
  if(!id)return;
  sessionStorage.removeItem(pendingReviewKey);
  try{await openPreparedReview(id,{refresh:false})}
  catch(error){
    $('#reviewDetail').classList.remove('hide');
    $('#reviewDetail').innerHTML='<div class="issue">Could not reopen the prepared review. Select it under Open Reviews and try again.</div>';
  }
}

window.ctodOpenReview=openPreparedReview;

function renderStartReview(f){
  $('#reviewDetail').innerHTML='<div style="display:flex;justify-content:space-between;gap:16px;align-items:flex-start;flex-wrap:wrap"><div><h3>'+esc(f.employee.name)+'</h3><div class="meta">'+esc(f.employee.role)+' • Location '+esc(f.employee.location_code)+' • '+esc(statusLabel(f.review.status))+'</div><p><strong>Scheduled next review:</strong> '+esc(fmt(f.review.next_review_date))+'</p><p class="sub">The scheduled date is a planning date only. Managers can begin the review early when needed.</p></div><div class="actions"><button id="startCurrentReview" class="btn primary">Start Review</button><button id="quickCoach" class="btn secondary">Add Coaching Moment</button></div></div><div id="coachQuickHost"></div>';
  $('#startCurrentReview').onclick=async()=>{const r=await sb.rpc('start_review',{p_review_id:currentReview});if(r.error){alert(r.error.message);return}await openReview(currentReview);await loadAll()};
  $('#quickCoach').onclick=()=>renderQuickCoach(f);
}

function renderQuickCoach(f){
  $('#coachQuickHost').innerHTML='<div class="invite-card" style="margin-top:16px"><h4 style="margin-top:0">New Coaching Moment</h4><label>Type</label><select id="qcType" class="field"><option value="recognition">Recognition</option><option value="development">Development</option><option value="corrective">Corrective</option></select><label>Category</label><input id="qcCategory" class="field" placeholder="Leadership, attendance, customer service, safety..."><label>Notes</label><textarea id="qcNotes" class="field" rows="4"></textarea><label>Expected outcome / follow-up</label><textarea id="qcOutcome" class="field" rows="3"></textarea><button id="saveQuickCoach" class="btn primary" style="margin-top:14px">Save Coaching Moment</button><span id="qcMsg" class="sub" style="margin-left:10px"></span></div>';
  $('#saveQuickCoach').onclick=async()=>{const u=(await sb.auth.getUser()).data.user;const category=$('#qcCategory').value.trim(),notes=$('#qcNotes').value.trim();if(!category||!notes){$('#qcMsg').textContent='Category and notes are required.';return}const {data,error}=await sb.from('coaching_moments').insert({company_id:membership.company_id,employee_id:f.employee.id,created_by_user_id:u.id,occurred_at:new Date().toISOString(),type:$('#qcType').value,category,notes,expected_outcome:$('#qcOutcome').value.trim()||null,include_in_review:true,record_status:'active',resolved_streak:0,active_carry_forward:true}).select('id').single();if(error){$('#qcMsg').textContent=error.message;return}$('#qcMsg').textContent='Saved.';await loadAll()};
}

async function renderReviewEditor(f){
  const coaching=await sb.rpc('get_review_coaching_items',{p_review_id:currentReview});
  const questions=f.questions||[],ratings=f.ratings||[],reasons=f.reasons||[];
  const sections=[...new Set(questions.map(q=>q.section))];
  let h='<div style="display:flex;justify-content:space-between;gap:16px;align-items:flex-start;flex-wrap:wrap"><div><h3>'+esc(f.employee.name)+'</h3><div class="meta">'+esc(f.employee.role)+' • Location '+esc(f.employee.location_code)+' • '+esc(statusLabel(f.review.status))+'</div><div class="good">Review workspace active. Save anytime and return later.</div></div><div class="actions"><button id="saveReviewDraft" class="btn secondary">Save Draft</button><button id="finalizeCurrentReview" class="btn primary">Finalize Review</button></div></div><div id="reviewSaveMsg" class="sub" style="margin:10px 0"></div>';
  h+='<h4>Performance Review</h4>';
  sections.forEach(section=>{h+='<div style="margin:18px 0 8px;font-weight:900;font-size:18px">'+esc(section)+'</div>';questions.filter(q=>q.section===section).forEach((q,i)=>{const a=q.answer||{};h+=questionCard(q,a,ratings,reasons,i)})});
  h+=developmentPanel(f);
  h+=coachingPanel(coaching.data||[]);
  $('#reviewDetail').innerHTML=h;
  wireQuestionReasonFilters(questions,ratings,reasons);
  $('#saveReviewDraft').onclick=()=>saveReviewWorkspace(false);
  $('#finalizeCurrentReview').onclick=()=>saveReviewWorkspace(true);
  const add=$('#addCoachInReview');if(add)add.onclick=()=>showCoachFormInReview(f);
  document.querySelectorAll('.coachDisposition').forEach(s=>s.onchange=async()=>{const coachingId=s.dataset.id;const {error}=await sb.rpc('set_review_coaching_disposition',{p_review_id:currentReview,p_coaching_id:coachingId,p_disposition:s.value,p_included_on_summary:true});if(error)alert(error.message)});
}

function questionCard(q,a,ratings,reasons,i){
  const ratingOpts=['<option value="">Choose rating...</option>'].concat(ratings.map(r=>'<option value="'+r.id+'" data-code="'+esc(r.code)+'" '+(a.rating_id===r.id?'selected':'')+'>'+esc(r.label)+'</option>')).join('');
  const chosenRating=ratings.find(r=>r.id===a.rating_id);const rs=filteredReasons(reasons,q,chosenRating?.code);
  const reasonOpts=['<option value="">Choose reason...</option>'].concat(rs.map(r=>'<option value="'+r.id+'" '+(a.primary_reason_id===r.id?'selected':'')+'>'+esc(r.label)+'</option>')).join('');
  const status=chosenRating?.code&&rs.length!==3?'Configuration warning: '+rs.length+' tailored reasons found; expected 3.':'';
  return '<div class="invite-card qcard" data-qid="'+q.id+'" data-category="'+esc(q.category||'')+'"><div style="display:flex;gap:10px"><div class="pill">'+(i+1)+'</div><strong style="line-height:1.35">'+esc(q.text)+'</strong></div><div class="grid2" style="margin-top:10px"><div><label>Rating</label><select class="field qrating">'+ratingOpts+'</select></div><div><label>Reason</label><select class="field qreason">'+reasonOpts+'</select></div></div><label>Manager note</label><textarea class="field qnote" rows="3" placeholder="Add specific examples or context...">'+esc(a.manager_note||'')+'</textarea><label style="display:flex;gap:8px;align-items:center;font-weight:700"><input type="checkbox" class="qconfirm" '+(a.confirmed?'checked':'')+'> Confirm this answer for the current review cycle</label><div class="sub qstatus">'+esc(status)+'</div></div>';
}

function filteredReasons(reasons,q,ratingCode){
  if(!ratingCode)return [];
  return reasons.filter(r=>r.rating_code===ratingCode && r.question_id===q.id);
}

function wireQuestionReasonFilters(questions,ratings,reasons){
  document.querySelectorAll('.qcard').forEach(card=>{const q=questions.find(x=>x.id===card.dataset.qid);const rating=card.querySelector('.qrating'),reason=card.querySelector('.qreason'),status=card.querySelector('.qstatus');rating.onchange=()=>{const rr=ratings.find(x=>x.id===rating.value);const opts=filteredReasons(reasons,q,rr?.code);reason.innerHTML='<option value="">Choose reason...</option>'+opts.map(r=>'<option value="'+r.id+'">'+esc(r.label)+'</option>').join('');status.textContent=rr?.code&&opts.length!==3?'Configuration warning: '+opts.length+' tailored reasons found; expected 3.':''}});
}

function developmentPanel(f){
  const c=f.career||{},s=f.summary||{},comp=f.compensation||{},goal=(f.goals||[]).find(g=>g.origin_review_id===currentReview)||(f.goals||[])[0]||{};
  return '<div style="margin:24px 0 8px;font-weight:900;font-size:18px">Development & Career</div><div class="invite-card"><label>Manager summary</label><textarea id="managerSummary" class="field" rows="4" placeholder="Overall performance summary and key discussion points...">'+esc(s.manager_summary||'')+'</textarea><label>Employee comments</label><textarea id="employeeComments" class="field" rows="3" placeholder="Employee feedback, comments, or response...">'+esc(s.employee_comments||'')+'</textarea><div class="grid2"><div><label>Development goal</label><input id="goalText" class="field" value="'+esc(goal.goal_text||'')+'"></div><div><label>Goal target date</label><input id="goalDate" type="date" class="field" value="'+esc(goal.target_date||'')+'"></div></div><div class="grid2"><div><label>Promotion readiness</label><select id="promotionReadiness" class="field"><option value="">Not set</option>'+['Ready Now','Ready in 1 Year','Ready in 2-3 Years','Not Yet Ready'].map(v=>'<option '+(c.promotion_readiness===v?'selected':'')+'>'+v+'</option>').join('')+'</select></div><div><label style="display:flex;gap:8px;align-items:center;margin-top:38px"><input id="promotionInterest" type="checkbox" '+(c.promotion_interest?'checked':'')+'> Interested in promotion / advancement</label></div></div></div><div style="margin:24px 0 8px;font-weight:900;font-size:18px">Compensation Discussion</div><div class="invite-card"><label style="display:flex;gap:8px;align-items:center"><input id="raiseRequested" type="checkbox" '+(comp.raise_requested?'checked':'')+'> Employee requested / manager recommends a raise</label><label>Raise basis / manager explanation</label><textarea id="raiseBasis" class="field" rows="3">'+esc(comp.raise_basis||'')+'</textarea><div id="raiseDetails" class="grid2"><div><label>Reason code</label><select id="raiseReason" class="field"><option value="PERFORMANCE">Performance</option><option value="PROMOTION">Promotion</option><option value="MARKET">Market adjustment</option><option value="RETENTION">Retention</option><option value="EQUITY">Internal equity</option><option value="OTHER">Other</option></select></div><div><label>Requested timing</label><select id="raiseTiming" class="field"><option value="IMMEDIATE">Immediate</option><option value="NEXT_PAY_PERIOD">Next pay period</option><option value="NEXT_REVIEW">Next review</option><option value="SPECIFIC_DATE">Specific date</option></select></div><div><label>Specific date if applicable</label><input id="raiseSpecificDate" type="date" class="field"></div><div><label>Employee explanation</label><textarea id="raiseEmployeeNote" class="field" rows="2"></textarea></div></div></div>';
}

function coachingPanel(items){
  let h='<div style="margin:24px 0 8px;font-weight:900;font-size:18px">Coaching Moments</div><div class="invite-card"><div style="display:flex;justify-content:space-between;gap:10px;align-items:center"><div><strong>Coaching linked to this employee</strong><div class="sub">Active items must be addressed before finalization. Two consecutive resolved cycles close a carried item.</div></div><button id="addCoachInReview" class="btn secondary">Add Coaching Moment</button></div><div id="coachFormHost"></div>';
  if(!items.length)h+='<p class="sub">No active coaching moments.</p>';
  else h+=items.map(c=>'<div style="border-top:1px solid #edf1f5;padding:12px 0;margin-top:12px"><strong>'+esc(c.category||'Coaching')+'</strong><div class="sub">'+esc(c.coaching_type||'')+' • '+esc(fmt(c.occurred_at))+' • '+esc(c.resolution_progress||'Active')+'</div><p>'+esc(c.notes||'')+'</p><label>Disposition for this review</label><select class="field coachDisposition" data-id="'+c.coaching_id+'"><option value="">Choose...</option><option value="carry_forward" '+(c.current_disposition==='carry_forward'?'selected':'')+'>Carry forward</option><option value="resolved" '+(c.current_disposition==='resolved'?'selected':'')+'>Resolved this cycle</option><option value="escalated" '+(c.current_disposition==='escalated'?'selected':'')+'>Escalated</option></select></div>').join('');
  return h+'</div>';
}

function showCoachFormInReview(f){
  $('#coachFormHost').innerHTML='<div style="border-top:1px solid #edf1f5;margin-top:14px;padding-top:14px"><div class="grid2"><div><label>Type</label><select id="irCoachType" class="field"><option value="recognition">Recognition</option><option value="development">Development</option><option value="corrective">Corrective</option></select></div><div><label>Category</label><input id="irCoachCategory" class="field"></div></div><label>Notes</label><textarea id="irCoachNotes" class="field" rows="3"></textarea><label>Expected outcome</label><textarea id="irCoachOutcome" class="field" rows="2"></textarea><button id="saveIrCoach" class="btn primary" style="margin-top:12px">Save Coaching Moment</button><span id="irCoachMsg" class="sub" style="margin-left:10px"></span></div>';
  $('#saveIrCoach').onclick=async()=>{const u=(await sb.auth.getUser()).data.user,category=$('#irCoachCategory').value.trim(),notes=$('#irCoachNotes').value.trim();if(!category||!notes){$('#irCoachMsg').textContent='Category and notes required.';return}const {data,error}=await sb.from('coaching_moments').insert({company_id:membership.company_id,employee_id:f.employee.id,created_by_user_id:u.id,occurred_at:new Date().toISOString(),type:$('#irCoachType').value,category,notes,expected_outcome:$('#irCoachOutcome').value.trim()||null,include_in_review:true,record_status:'active',resolved_streak:0,active_carry_forward:true}).select('id').single();if(error){$('#irCoachMsg').textContent=error.message;return}await sb.rpc('set_review_coaching_disposition',{p_review_id:currentReview,p_coaching_id:data.id,p_disposition:'carry_forward',p_included_on_summary:true});await openReview(currentReview);await loadAll()};
}

async function saveReviewWorkspace(finalize){
  const msg=$('#reviewSaveMsg');msg.textContent='Saving...';
  const cards=[...document.querySelectorAll('.qcard')];
  for(const card of cards){
    const rating=card.querySelector('.qrating').value||null,reason=card.querySelector('.qreason').value||null,note=card.querySelector('.qnote').value.trim(),confirmed=card.querySelector('.qconfirm').checked;
    if(!rating&&!reason&&!note&&!confirmed)continue;
    const {error}=await sb.rpc('save_review_answer',{p_review_id:currentReview,p_question_id:card.dataset.qid,p_rating_id:rating,p_primary_reason_id:reason,p_additional_reason_id:null,p_manager_note:note||null,p_confirmed:confirmed});
    if(error){msg.textContent='Save stopped: '+error.message;return}
  }
  const raiseRequested=$('#raiseRequested')?.checked||false;
  const dev=await sb.rpc('save_review_development',{p_review_id:currentReview,p_manager_summary:$('#managerSummary')?.value||null,p_employee_comments:$('#employeeComments')?.value||null,p_goal_text:$('#goalText')?.value||null,p_goal_target_date:$('#goalDate')?.value||null,p_promotion_interest:$('#promotionInterest')?.checked||false,p_desired_role_id:null,p_promotion_readiness:$('#promotionReadiness')?.value||null,p_raise_requested:raiseRequested,p_raise_basis:$('#raiseBasis')?.value||null});
  if(dev.error){msg.textContent='Development save failed: '+dev.error.message;return}
  if(raiseRequested){const payload={raise_reason_code:$('#raiseReason').value,employee_raise_note:$('#raiseEmployeeNote').value.trim()||null,requested_timing:$('#raiseTiming').value,requested_specific_date:$('#raiseTiming').value==='SPECIFIC_DATE'?($('#raiseSpecificDate').value||null):null};const u=await sb.from('compensation_decisions').update(payload).eq('review_id',currentReview);if(u.error){msg.textContent='Raise details failed: '+u.error.message;return}}
  if(!finalize){msg.textContent='Draft saved '+new Date().toLocaleTimeString([], {hour:'numeric',minute:'2-digit'})+'.';await loadAll();return}
  msg.textContent='Checking required items...';
  const [issues,coachIssues]=await Promise.all([sb.rpc('get_review_validation_issues',{p_review_id:currentReview}),sb.rpc('get_review_coaching_validation_issues',{p_review_id:currentReview})]);
  if(issues.error){msg.textContent=issues.error.message;return}
  if(coachIssues.error){msg.textContent=coachIssues.error.message;return}
  if((issues.data||[]).length||(coachIssues.data||[]).length){
    let html='<div class="issue"><strong>Review is not ready to finalize.</strong><ul>'+(issues.data||[]).slice(0,20).map(i=>'<li>'+esc(i.section_name)+': '+esc(i.issue_message)+'</li>').join('')+(coachIssues.data||[]).slice(0,20).map(i=>'<li>Coaching: '+esc(i.issue_message||'Choose a disposition for each active coaching item')+'</li>').join('')+'</ul></div>';
    msg.innerHTML=html;return;
  }
  const f=await sb.rpc('finalize_review',{p_review_id:currentReview});
  if(f.error){msg.textContent='Could not finalize: '+f.error.message;return}
  msg.textContent='Review finalized.';await loadAll();await openReview(currentReview);
}

function renderFinalizedReview(f){
  const ans=(f.questions||[]).filter(q=>q.answer),ratings=f.ratings||[],reasons=f.reasons||[];
  let h='<h3>'+esc(f.employee.name)+'</h3><div class="meta">'+esc(f.employee.role)+' • Location '+esc(f.employee.location_code)+' • Finalized '+esc(fmt(f.review.review_date))+'</div><div class="good">Finalized review</div><p><strong>Promotion readiness:</strong> '+esc(f.career?.promotion_readiness||'Not set')+'</p>';
  h+='<h4>Review Answers</h4>'+ans.map(q=>{const r=ratings.find(x=>x.id===q.answer.rating_id),re=reasons.find(x=>x.id===q.answer.primary_reason_id);return '<div class="invite-card"><strong>'+esc(q.text)+'</strong><div>'+esc(r?.label||'No rating')+(re?' • '+esc(re.label):'')+'</div>'+(q.answer.manager_note?'<div class="sub">'+esc(q.answer.manager_note)+'</div>':'')+'</div>'}).join('');
  h+='<div class="printbox"><button id="previewSummary" class="btn primary">Print 2-Page Review Summary</button></div>';
  $('#reviewDetail').innerHTML=h;$('#previewSummary').onclick=()=>printFinalized(currentReview);
}

async function printFinalized(id){
  const {data,error}=await sb.rpc('review_print_summary',{p_review_id:id});if(error){alert(error.message);return}
  const strengths=data.strengths||[],dev=data.development||[],goals=data.goals||[];
  $('#printPage').innerHTML='<div class="page"><h1>Employee Review Summary</h1><p><strong>'+esc(data.employee)+'</strong><br>'+esc(data.role||'')+' • '+esc(data.location||'')+'</p><hr><h2>Review Overview</h2><p><strong>Review Date:</strong> '+esc(fmt(data.review_date))+'<br><strong>Overall Rating:</strong> '+esc(data.overall_rating||'Completed')+'</p><h2>Key Strengths</h2>'+(strengths.length?'<ul>'+strengths.map(a=>'<li>'+esc(a.question)+' — '+esc(a.rating)+(a.reason?' • '+esc(a.reason):'')+'</li>').join('')+'</ul>':'<p>No specific strengths flagged.</p>')+'<h2>Development Areas</h2>'+(dev.length?'<ul>'+dev.map(a=>'<li>'+esc(a.question)+' — '+esc(a.rating)+(a.reason?' • '+esc(a.reason):'')+'</li>').join('')+'</ul>':'<p>No critical development areas flagged.</p>')+'</div><div class="page"><h1>Development & Acknowledgment</h1><h2>Manager Summary</h2><p>'+esc(data.manager_summary||'')+'</p><h2>Goals</h2>'+(goals.length?'<ul>'+goals.map(g=>'<li>'+esc(g.text)+' '+(g.target_date?'('+esc(fmt(g.target_date))+')':'')+'</li>').join('')+'</ul>':'<p>No goals recorded.</p>')+'<h2>Acknowledgment</h2><p>Employee acknowledgment confirms the review was discussed. Signature does not necessarily indicate agreement with every rating or comment.</p><div class="sig">Employee Signature / Date</div><div class="sig">Manager Signature / Date</div><div class="printbox"><button id="doPrint" class="btn primary">Print / Save PDF</button><button id="backPrint" class="btn secondary">Back to Review</button></div></div>';
  $('#app').hidden=true;$('#printPage').style.display='block';$('#doPrint').onclick=()=>window.print();$('#backPrint').onclick=()=>{$('#printPage').style.display='none';$('#app').hidden=false};
}

async function loadAccess(){
  const [locs,inv]=await Promise.all([sb.from('locations').select('id,location_code,name').eq('status','active').order('location_code'),sb.from('access_invites').select('id,email,intended_role,token,accepted_at,revoked_at,expires_at,created_at,access_invite_locations(location_id,locations(location_code,name))').order('created_at',{ascending:false}).limit(25)]);
  locations=locs.data||[];$('#locationOptions').innerHTML=locations.map(l=>'<label class="location-option"><input type="checkbox" value="'+esc(l.id)+'"> <strong>Location '+esc(l.location_code)+'</strong> '+esc(l.name)+'</label>').join('');
  $('#inviteList').innerHTML=(inv.data||[]).map(i=>'<div class="invite-card"><strong>'+esc(i.email)+'</strong><div class="sub">'+esc(String(i.intended_role).replaceAll('_',' '))+' • '+esc(i.accepted_at?'Accepted':i.revoked_at?'Revoked':'Pending')+'</div>'+(i.accepted_at||i.revoked_at?'':'<button class="btn secondary copyInvite" data-token="'+esc(i.token)+'" style="margin-top:8px">Copy Link</button>')+'</div>').join('');
  document.querySelectorAll('.copyInvite').forEach(b=>b.onclick=async()=>{const url=location.origin+'/?invite='+b.dataset.token;await navigator.clipboard.writeText(url);$('#accessMsg').textContent='Invite link copied.'});
}

async function sendInvite(){
  const email=$('#inviteTargetEmail').value.trim(),role=$('#inviteRole').value,ids=[...document.querySelectorAll('#locationOptions input:checked')].map(x=>x.value);
  if(!email){$('#accessMsg').textContent='Enter an email.';return}
  try{assertSandboxEmailAllowed(email)}catch(error){$('#accessMsg').textContent=error.message;return}
  const cr=await sb.rpc('create_access_invite',{p_email:email,p_role:role,p_location_ids:ids});if(cr.error){$('#accessMsg').textContent=cr.error.message;return}
  const session=(await sb.auth.getSession()).data.session;
  const deliveryRequestId=crypto.randomUUID();
  const er=await fetch(SUPABASE_URL+'/functions/v1/send-ctod-invite',{method:'POST',headers:{authorization:'Bearer '+session.access_token,'content-type':'application/json'},body:JSON.stringify({invite_id:cr.data.invite_id,delivery_request_id:deliveryRequestId})});
  const data=await er.json();
  if(data.email_sent)$('#accessMsg').textContent=cr.data?.reused?'Invite email resent.':'Invite email sent.';else if(data.existing_user_updated)$('#accessMsg').textContent=data.already_company_wide?'This user already has company-wide access.':'Existing CTOD user updated with the selected access.';else $('#accessMsg').textContent='Invite created. Email could not be sent automatically; use Copy Link.';
  await loadAccess();
}

$('#activateInvite').onclick=activateInvite;$('#signin').onclick=signin;$('#logout').onclick=async()=>{await sb.auth.signOut();location.reload()};$('#accountLogout').onclick=async()=>{await sb.auth.signOut();location.reload()};$('#tabReviews').onclick=()=>setTab('reviews');$('#tabMaster').onclick=()=>setTab('master');$('#tabAccess').onclick=()=>setTab('access');$('#sendInvite').onclick=sendInvite;boot();
