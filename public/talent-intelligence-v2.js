import { ctodSupabase as sbt } from './ctod-config.js';
import { formatDate,uniqueGoals } from './display-utils.js?v=20260810-001';

const $t=s=>document.querySelector(s);
const $$t=s=>[...document.querySelectorAll(s)];
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
const fmt=formatDate;
let roster=[];
const profileLoads=new WeakMap();

function injectStyles(){
  if($t('#talentV2Styles'))return;
  const s=document.createElement('style');s.id='talentV2Styles';s.textContent=`
  .tv2-hero{background:radial-gradient(circle at 82% 0%,rgba(57,198,255,.14),transparent 35%),linear-gradient(135deg,#0b2944,#071a2c);border:1px solid #1a4769;border-radius:20px;padding:18px;margin-bottom:14px}.tv2-eyebrow{font-size:10px;letter-spacing:.16em;text-transform:uppercase;color:#70c8ff;font-weight:900}.tv2-title{font-size:28px;font-weight:950;color:#fff;margin-top:4px}.tv2-sub{color:#7f9eb5;font-size:12px;margin-top:5px}
  .tv2-kpis{display:grid;grid-template-columns:repeat(5,1fr);gap:10px;margin:14px 0}.tv2-kpi{background:#081d31;border:1px solid #173a57;border-radius:14px;padding:12px}.tv2-kpi small{display:block;color:#6f8ea6;font-size:9px;text-transform:uppercase;letter-spacing:.08em;font-weight:900}.tv2-kpi b{display:block;color:#fff;font-size:25px;margin-top:5px}.tv2-kpi span{display:block;color:#7a98af;font-size:10px;margin-top:3px}
  .tv2-grid{display:grid;grid-template-columns:1.25fr .75fr;gap:12px}.tv2-card{background:#081d31;border:1px solid #173a57;border-radius:15px;padding:14px}.tv2-card h4{margin:0;color:#f4faff;font-size:15px}.tv2-caption{color:#708ea5;font-size:11px;margin-top:3px}.tv2-role{border-top:1px solid #14344e;padding:12px 0}.tv2-role:first-child{border-top:0}.tv2-role-head{display:flex;justify-content:space-between;gap:10px}.tv2-role-head b{color:#eaf4fc}.tv2-gap{font-size:10px;font-weight:900;padding:5px 8px;border-radius:999px}.tv2-gap.green{background:rgba(42,209,127,.12);color:#70e9aa}.tv2-gap.yellow{background:rgba(255,189,82,.12);color:#ffd277}.tv2-gap.red{background:rgba(255,95,104,.12);color:#ff9298}.tv2-bench{display:grid;grid-template-columns:repeat(3,1fr);gap:7px;margin-top:8px}.tv2-bucket{background:#0a253d;border:1px solid #173b59;border-radius:10px;padding:8px}.tv2-bucket small{display:block;color:#6f8ea6;font-size:8px;text-transform:uppercase;font-weight:900}.tv2-bucket b{display:block;color:#fff;font-size:18px;margin-top:3px}.tv2-person{padding:7px 0;border-top:1px solid #13334c}.tv2-person:first-child{border-top:0}.tv2-person strong{color:#e7f2fb;font-size:12px}.tv2-person span{display:block;color:#7896ac;font-size:10px;margin-top:2px}
  .tv2-alert{display:flex;gap:9px;padding:9px 0;border-bottom:1px solid #14344e}.tv2-alert:last-child{border-bottom:0}.tv2-dot{width:8px;height:8px;border-radius:50%;background:#ffbd52;margin-top:5px;flex:0 0 auto}.tv2-dot.red{background:#ff5f68}.tv2-alert b{color:#eaf4fc;font-size:11px}.tv2-alert span{display:block;color:#7694aa;font-size:10px;margin-top:2px}
  .tv2-profile-addon{margin-top:14px;border-top:1px solid #173a57;padding-top:14px}.tv2-profile-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:9px}.tv2-stat{background:#081d31;border:1px solid #173a57;border-radius:11px;padding:10px}.tv2-stat small{display:block;color:#6f8ea6;font-size:8px;text-transform:uppercase;font-weight:900}.tv2-stat b{display:block;color:#fff;font-size:19px;margin-top:4px}.tv2-progress{height:8px;background:#112e46;border-radius:999px;overflow:hidden;margin-top:7px}.tv2-progress>i{display:block;height:100%;background:linear-gradient(90deg,#1f6feb,#39c6ff)}.tv2-section-title{color:#dcebf6;font-size:12px;font-weight:900;margin:14px 0 7px}.tv2-minirow{display:flex;justify-content:space-between;gap:8px;padding:7px 0;border-bottom:1px solid #14344e;font-size:10px;color:#7896ac}.tv2-minirow b{color:#dcebf6}
  @media(max-width:850px){.tv2-kpis{grid-template-columns:repeat(2,1fr)}.tv2-grid{grid-template-columns:1fr}.tv2-bench{grid-template-columns:1fr}.tv2-profile-grid{grid-template-columns:1fr}}
  `;document.head.appendChild(s);
}

async function loadRoster(){const r=await sbt.rpc('manager_workspace_employees');if(r.error)throw r.error;roster=r.data||[];return roster}

async function successionData(){
  await loadRoster();const ids=roster.map(x=>x.employee_id);
  const [reviews,coach,goals,roles]=await Promise.all([
    ids.length?sbt.from('reviews').select('id,employee_id,status,finalized_at,promotion_readiness,overall_percent,role_id,location_id').in('employee_id',ids).order('finalized_at',{ascending:false}):Promise.resolve({data:[]}),
    ids.length?sbt.from('coaching_moments').select('id,employee_id,type,active_carry_forward,resolved_streak,include_in_review').in('employee_id',ids):Promise.resolve({data:[]}),
    ids.length?sbt.from('goals').select('id,employee_id,status').in('employee_id',ids):Promise.resolve({data:[]}),
    sbt.from('roles').select('id,title,sort_order').eq('active',true).order('sort_order')
  ]);
  const latest={};for(const r of reviews.data||[]){if(!latest[r.employee_id]&&r.status==='finalized')latest[r.employee_id]=r}
  return {reviews:reviews.data||[],coach:coach.data||[],goals:uniqueGoals(goals.data||[]),roles:roles.data||[],latest};
}

function readiness(r){const x=String(r||'').toLowerCase();if(x.includes('ready now'))return'now';if(x.includes('1 year')||x.includes('≤ 1')||x.includes('within 1'))return'year';if(x.includes('2')||x.includes('3'))return'later';return'not'}

async function renderSuccessionV2(){
  const host=$t('#successionView');if(!host)return;
  host.innerHTML='<section class="card section"><div class="sub">Loading succession intelligence...</div></section>';
  try{const d=await successionData();const byRole={};for(const e of roster){(byRole[e.role_title]??=[]).push(e)}
    let readyNow=0,readyYear=0,gaps=0;const roleBlocks=[];const alerts=[];
    for(const [role,people] of Object.entries(byRole)){
      const buckets={now:[],year:[],later:[],not:[]};for(const p of people){const rr=readiness(d.latest[p.employee_id]?.promotion_readiness);buckets[rr].push(p);if(rr==='now')readyNow++;if(rr==='year')readyYear++;}
      const gap=buckets.now.length===0&&buckets.year.length===0;const thin=buckets.now.length===0&&buckets.year.length>0;if(gap){gaps++;alerts.push({sev:'red',text:`No near-term successor bench for ${role}`,sub:`${people.length} current employee${people.length===1?'':'s'} in role`})}else if(thin)alerts.push({sev:'',text:`${role} bench is future-only`,sub:`${buckets.year.length} candidate${buckets.year.length===1?'':'s'} within 1 year`});
      const cls=gap?'red':thin?'yellow':'green',label=gap?'Critical gap':thin?'Developing':'Covered';
      roleBlocks.push(`<div class="tv2-role"><div class="tv2-role-head"><b>${esc(role)}</b><span class="tv2-gap ${cls}">${label}</span></div><div class="tv2-bench"><div class="tv2-bucket"><small>Ready Now</small><b>${buckets.now.length}</b>${buckets.now.slice(0,3).map(p=>`<div class="tv2-person"><strong>${esc(p.first_name)} ${esc(p.last_name)}</strong><span>#${esc(p.employee_code||'------')} · ${esc(p.location_code)}</span></div>`).join('')}</div><div class="tv2-bucket"><small>≤ 1 Year</small><b>${buckets.year.length}</b>${buckets.year.slice(0,3).map(p=>`<div class="tv2-person"><strong>${esc(p.first_name)} ${esc(p.last_name)}</strong><span>#${esc(p.employee_code||'------')} · ${esc(p.location_code)}</span></div>`).join('')}</div><div class="tv2-bucket"><small>2–3 Years</small><b>${buckets.later.length}</b>${buckets.later.slice(0,3).map(p=>`<div class="tv2-person"><strong>${esc(p.first_name)} ${esc(p.last_name)}</strong><span>#${esc(p.employee_code||'------')} · ${esc(p.location_code)}</span></div>`).join('')}</div></div></div>`)
    }
    const openCorrective=(d.coach||[]).filter(c=>c.type==='corrective'&&c.active_carry_forward).length;const activeGoals=(d.goals||[]).filter(g=>['not_started','in_progress'].includes(g.status)).length;
    host.innerHTML=`<section class="card section"><div class="tv2-hero"><div class="tv2-eyebrow">CTOD Succession Intelligence</div><div class="tv2-title">Bench Strength & Depth</div><div class="tv2-sub">Live readiness by role, anchored to finalized reviews and the 6-digit employee record.</div></div><div class="tv2-kpis"><div class="tv2-kpi"><small>Ready Now</small><b>${readyNow}</b><span>immediate bench</span></div><div class="tv2-kpi"><small>Ready ≤ 1 Year</small><b>${readyYear}</b><span>near-term bench</span></div><div class="tv2-kpi"><small>Critical Role Gaps</small><b>${gaps}</b><span>no near-term successor</span></div><div class="tv2-kpi"><small>Open Corrective</small><b>${openCorrective}</b><span>development risk</span></div><div class="tv2-kpi"><small>Active Goals</small><b>${activeGoals}</b><span>pipeline activity</span></div></div><div class="tv2-grid"><div class="tv2-card"><h4>Role Depth Chart</h4><div class="tv2-caption">Each role shows the current succession pipeline.</div>${roleBlocks.join('')||'<div class="sub">No role data available.</div>'}</div><div class="tv2-card"><h4>Leadership Attention</h4><div class="tv2-caption">Gaps and weak benches that need action.</div>${alerts.length?alerts.map(a=>`<div class="tv2-alert"><i class="tv2-dot ${a.sev}"></i><div><b>${esc(a.text)}</b><span>${esc(a.sub)}</span></div></div>`).join(''):'<div class="sub" style="margin-top:12px">No critical bench alerts.</div>'}</div></div></section>`;
  }catch(e){host.innerHTML=`<section class="card section"><div class="issue">${esc(e.message)}</div></section>`}
}

async function profileAddon(employeeId){
  const host=$t('#personProfile');if(!host||host.querySelector('.tv2-profile-addon'))return;
  const pending=profileLoads.get(host);if(pending?.employeeId===employeeId)return;
  const token=Symbol(employeeId);profileLoads.set(host,{employeeId,token});
  try{
    const [reviews,coach,goals,assign]=await Promise.all([
      sbt.from('reviews').select('id,status,finalized_at,review_date,overall_percent,promotion_readiness,overall_rating_label').eq('employee_id',employeeId).order('finalized_at',{ascending:false}),
      sbt.from('coaching_moments').select('id,type,category,active_carry_forward,resolved_streak,include_in_review,occurred_at').eq('employee_id',employeeId).order('occurred_at',{ascending:false}),
      sbt.from('goals').select('id,employee_id,goal_text,status,target_date,completed_at').eq('employee_id',employeeId).order('created_at',{ascending:false}),
      sbt.from('employment_assignments').select('id,effective_from,effective_to,locations(location_code,name),roles(title)').eq('employee_id',employeeId).order('effective_from',{ascending:false})
    ]);
    if(profileLoads.get(host)?.token!==token||!host.isConnected||host.querySelector('.tv2-profile-addon'))return;
    const goalRows=uniqueGoals(goals.data||[]),finals=(reviews.data||[]).filter(r=>r.status==='finalized');const latest=finals[0];const prior=finals[1];const score=Number(latest?.overall_percent||0);const delta=latest&&prior?Math.round(score-Number(prior.overall_percent||0)):null;const recognition=(coach.data||[]).filter(c=>c.type==='recognition').length;const corrective=(coach.data||[]).filter(c=>c.type==='corrective'&&c.active_carry_forward).length;const activeGoals=goalRows.filter(g=>['not_started','in_progress'].includes(g.status)).length;const completedGoals=goalRows.filter(g=>g.status==='completed').length;
    const div=document.createElement('div');div.className='tv2-profile-addon';div.innerHTML=`<div class="tv2-section-title">Talent Trajectory</div><div class="tv2-profile-grid"><div class="tv2-stat"><small>Latest Review</small><b>${latest?Math.round(score)+'%':'—'}</b><div class="tv2-progress"><i style="width:${Math.max(0,Math.min(100,score))}%"></i></div></div><div class="tv2-stat"><small>Score Movement</small><b>${delta===null?'—':(delta>0?'+':'')+delta}</b></div><div class="tv2-stat"><small>Promotion Readiness</small><b style="font-size:14px">${esc(latest?.promotion_readiness||'Not set')}</b></div><div class="tv2-stat"><small>Recognition</small><b>${recognition}</b></div><div class="tv2-stat"><small>Open Corrective</small><b>${corrective}</b></div><div class="tv2-stat"><small>Goals</small><b>${activeGoals}</b><span style="display:block;color:#6f8ea6;font-size:9px">${completedGoals} completed</span></div></div><div class="tv2-section-title">Career Movement</div>${(assign.data||[]).slice(0,6).map(a=>`<div class="tv2-minirow"><b>${esc(a.roles?.title||'Role')}</b><span>${esc(a.locations?.location_code||'')} · ${fmt(a.effective_from)}${a.effective_to?' → '+fmt(a.effective_to):' → Current'}</span></div>`).join('')||'<div class="sub">No assignment history.</div>'}<div class="tv2-section-title">Latest Review Trend</div>${finals.slice(0,4).map(r=>`<div class="tv2-minirow"><b>${fmt(r.finalized_at||r.review_date)} · ${esc(r.overall_rating_label||'Finalized')}</b><span>${r.overall_percent==null?'—':Math.round(Number(r.overall_percent))+'%'} · ${esc(r.promotion_readiness||'')}</span></div>`).join('')||'<div class="sub">No finalized reviews yet.</div>'}`;host.appendChild(div);
  }finally{if(profileLoads.get(host)?.token===token)profileLoads.delete(host)}
}

function wirePeopleAddon(){
  const people=$t('#peopleView');if(!people)return;new MutationObserver(()=>{const active=$t('#peopleList .person-row.active');if(active?.dataset.id)setTimeout(()=>profileAddon(active.dataset.id),80)}).observe(people,{childList:true,subtree:true});
  people.addEventListener('click',e=>{const row=e.target.closest('.person-row');if(row?.dataset.id)setTimeout(()=>profileAddon(row.dataset.id),120)});
}

async function init(){injectStyles();for(let i=0;i<40;i++){if($t('#tabSuccession')&&$t('#peopleView'))break;await new Promise(r=>setTimeout(r,250))}wirePeopleAddon();$t('#tabSuccession')?.addEventListener('click',()=>setTimeout(renderSuccessionV2,120));$t('#tabPeople')?.addEventListener('click',()=>setTimeout(()=>{const active=$t('#peopleList .person-row.active');if(active?.dataset.id)profileAddon(active.dataset.id)},200));}

init();
