import { ctodSupabase as sbd } from './ctod-config.js';
const $d=s=>document.querySelector(s);
const escd=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
let masterLoaded=false;

function injectMasterStyles(){
  if(document.querySelector('#ctodMasterStyles'))return;
  const style=document.createElement('style');style.id='ctodMasterStyles';style.textContent=`
  #masterView{--mnavy:#071525;--mnavy2:#0d2238;--mblue:#1f6feb;--mcyan:#39c6ff;--mgreen:#2ad17f;--mamber:#ffbd52;--mred:#ff5f68;color:#eaf2fb}
  .master-shell{background:radial-gradient(circle at 12% 0%,rgba(31,111,235,.25),transparent 36%),radial-gradient(circle at 88% 8%,rgba(57,198,255,.14),transparent 30%),linear-gradient(145deg,#06111f,#091a2c 55%,#071420);border:1px solid #17334f;border-radius:24px;padding:20px;box-shadow:0 25px 80px rgba(1,10,20,.28);overflow:hidden}
  .master-hero{display:flex;justify-content:space-between;gap:18px;align-items:flex-start;margin-bottom:18px}.master-eyebrow{font-size:12px;font-weight:900;letter-spacing:.18em;color:#79bfff;text-transform:uppercase}.master-title{font-size:34px;line-height:1.02;margin:6px 0;color:white}.master-sub{color:#8fa7bd;font-size:14px}.live-chip{border:1px solid #24537a;background:#0b263e;border-radius:999px;padding:9px 13px;color:#a9d8ff;font-weight:800;font-size:12px}.live-dot{display:inline-block;width:8px;height:8px;border-radius:50%;background:#2ad17f;box-shadow:0 0 13px #2ad17f;margin-right:7px}
  .master-kpis{display:grid;grid-template-columns:repeat(6,1fr);gap:10px;margin-bottom:14px}.mkpi{position:relative;background:linear-gradient(180deg,rgba(16,43,68,.88),rgba(8,29,48,.88));border:1px solid #1b3f5e;border-radius:17px;padding:15px;min-height:104px}.mkpi:after{content:"";position:absolute;left:14px;right:14px;bottom:0;height:2px;background:linear-gradient(90deg,#1f6feb,#39c6ff);opacity:.7}.mkpi small{display:block;color:#7794ac;font-size:10px;font-weight:900;letter-spacing:.09em}.mkpi strong{display:block;color:white;font-size:29px;margin-top:8px}.mkpi .delta{font-size:11px;color:#8fa7bd;margin-top:4px}
  .master-grid{display:grid;grid-template-columns:1.55fr .95fr;gap:14px}.master-card{background:rgba(7,28,47,.88);border:1px solid #183d5b;border-radius:19px;padding:16px;box-shadow:inset 0 1px rgba(255,255,255,.03)}.master-card h3{color:white;margin:0;font-size:17px}.master-card .caption{color:#7893aa;font-size:12px;margin-top:3px}.wide{grid-column:1/-1}
  #ctodMap{height:365px;border-radius:14px;margin-top:12px;overflow:hidden;background:#061522}.leaflet-container{font-family:Inter,ui-sans-serif,system-ui;background:#071525}.leaflet-popup-content-wrapper,.leaflet-popup-tip{background:#0b2135;color:#eaf2fb}.leaflet-control-attribution{font-size:9px!important}
  .gauge-row{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-top:14px}.ring-wrap{text-align:center;background:#091d31;border:1px solid #183b58;border-radius:15px;padding:12px}.ring{--v:0;--ring:#2ad17f;width:92px;height:92px;margin:auto;border-radius:50%;background:conic-gradient(var(--ring) calc(var(--v)*1%),#173047 0);display:grid;place-items:center;position:relative}.ring:before{content:"";position:absolute;inset:9px;border-radius:50%;background:#081a2c}.ring b{position:relative;color:white;font-size:21px}.ring-label{color:#89a6bd;font-size:11px;font-weight:800;margin-top:8px}
  .metric-list{margin-top:10px}.metric-line{display:grid;grid-template-columns:120px 1fr 44px;gap:8px;align-items:center;padding:7px 0}.metric-line span{font-size:11px;color:#9ab2c5}.track{height:8px;background:#122f48;border-radius:999px;overflow:hidden}.fill{height:100%;border-radius:999px;background:linear-gradient(90deg,#1f6feb,#39c6ff)}.metric-line b{font-size:11px;color:#d9e8f5;text-align:right}
  .intel-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:14px}.intel{background:#091e32;border:1px solid #183b58;border-radius:14px;padding:12px}.intel .num{font-size:25px;font-weight:900;color:white}.intel .lbl{font-size:10px;letter-spacing:.07em;color:#7895ad;text-transform:uppercase;font-weight:900}.intel .note{font-size:11px;color:#8ba4b8;margin-top:5px}
  .location-table{width:100%;border-collapse:collapse;margin-top:10px}.location-table th,.location-table td{border-bottom:1px solid #17344f;padding:10px 8px;text-align:left;font-size:12px}.location-table th{color:#67869f;text-transform:uppercase;font-size:10px;letter-spacing:.08em}.location-table td{color:#d9e6f1}.health{display:inline-flex;align-items:center;gap:6px}.health i{width:8px;height:8px;border-radius:50%;display:inline-block}.health.green i{background:#2ad17f;box-shadow:0 0 8px #2ad17f}.health.yellow i{background:#ffbd52}.health.red i{background:#ff5f68}.health.green,.health.yellow,.health.red{background:none}
  .activity{margin-top:10px}.activity-row{display:grid;grid-template-columns:10px 1fr auto;gap:10px;align-items:start;padding:9px 0;border-bottom:1px solid #14314b}.activity-row:last-child{border-bottom:0}.activity-dot{width:8px;height:8px;border-radius:50%;background:#39c6ff;margin-top:5px;box-shadow:0 0 9px rgba(57,198,255,.7)}.activity-main{font-size:12px;color:#d6e4ef}.activity-main small{display:block;color:#738fa6;margin-top:2px}.activity-time{font-size:10px;color:#607f97}
  .master-footer-note{margin-top:12px;color:#627f96;font-size:10px;text-align:right}.compat-master{display:none!important}
  @media(max-width:1000px){.master-kpis{grid-template-columns:repeat(3,1fr)}.master-grid{grid-template-columns:1fr}.intel-grid{grid-template-columns:repeat(2,1fr)}}
  @media(max-width:650px){.master-shell{padding:12px}.master-title{font-size:26px}.master-kpis{grid-template-columns:repeat(2,1fr)}.gauge-row{grid-template-columns:1fr}.intel-grid{grid-template-columns:1fr}.master-hero{display:block}.live-chip{display:inline-block;margin-top:10px}}
  `;document.head.appendChild(style);
}

function pct(n,d){return d?Math.round(n/d*100):0}
function clamp(n){return Math.max(0,Math.min(100,Math.round(Number(n)||0)))}
function ageText(d){if(!d)return'';const ms=Date.now()-new Date(d).getTime(),m=Math.round(ms/60000);if(m<60)return m+'m';if(m<1440)return Math.round(m/60)+'h';return Math.round(m/1440)+'d'}

async function getMasterData(){
  const [locations,assignments,reviews,coach,goals,promo,employees]=await Promise.all([
    sbd.from('locations').select('id,location_code,name,status,address_line1,city,state_code,latitude,longitude,market_name,area_name').eq('status','active').order('location_code'),
    sbd.from('employment_assignments').select('employee_id,location_id,effective_to').is('effective_to',null),
    sbd.from('reviews').select('id,employee_id,location_id,status,finalized_at,review_date,next_review_date,overall_rating_label,promotion_readiness,updated_at'),
    sbd.from('coaching_moments').select('id,employee_id,type,category,active_carry_forward,resolved_streak,occurred_at,created_at'),
    sbd.from('goals').select('id,employee_id,status,target_date,created_at'),
    sbd.from('v_promotion_readiness').select('*'),
    sbd.from('employees').select('id,employee_code,first_name,last_name,employment_status').eq('employment_status','active')
  ]);
  for(const r of [locations,assignments,reviews,coach,goals,employees])if(r.error)throw r.error;
  return {locations:locations.data||[],assignments:assignments.data||[],reviews:reviews.data||[],coach:coach.data||[],goals:goals.data||[],promo:promo.data||[],employees:employees.data||[]};
}

function locationMetrics(d,loc){
  const empIds=new Set(d.assignments.filter(a=>a.location_id===loc.id).map(a=>a.employee_id));
  const reviews=d.reviews.filter(r=>r.location_id===loc.id),final=reviews.filter(r=>r.status==='finalized'),open=reviews.filter(r=>r.status!=='finalized');
  const coach=d.coach.filter(c=>empIds.has(c.employee_id)&&c.active_carry_forward),goals=d.goals.filter(g=>empIds.has(g.employee_id)&&['not_started','in_progress'].includes(g.status));
  const ready=d.promo.filter(p=>String(p.location_code||'').padStart(3,'0')===String(loc.location_code).padStart(3,'0')&&p.readiness==='Ready Now').length;
  const completion=pct(final.length,reviews.length),bench=pct(ready,Math.max(1,empIds.size)),coachRisk=clamp(coach.filter(c=>c.type!=='recognition').length*12),goalEnergy=clamp(goals.length*12);
  const health=clamp(completion*.45+Math.min(100,bench*2)*.25+(100-coachRisk)*.2+Math.min(100,goalEnergy)*.1);
  return {employees:empIds.size,reviews:reviews.length,finalized:final.length,open:open.length,coach:coach.length,goals:goals.length,ready,completion,health};
}

function healthClass(v){return v>=80?'green':v>=60?'yellow':'red'}
function ring(v,label,color='#2ad17f'){return `<div class="ring-wrap"><div class="ring" style="--v:${clamp(v)};--ring:${color}"><b>${clamp(v)}%</b></div><div class="ring-label">${escd(label)}</div></div>`}
function metric(label,value,max=100){const v=clamp(value);return `<div class="metric-line"><span>${escd(label)}</span><div class="track"><div class="fill" style="width:${v}%"></div></div><b>${v}%</b></div>`}

function buildActivity(d){
  const events=[];
  d.reviews.filter(r=>r.finalized_at).forEach(r=>events.push({date:r.finalized_at,text:'Review finalized',sub:r.overall_rating_label||'Completed review'}));
  d.coach.forEach(c=>events.push({date:c.created_at||c.occurred_at,text:'Coaching moment recorded',sub:`${String(c.type||'').replaceAll('_',' ')} · ${c.category||''}`}));
  d.goals.forEach(g=>events.push({date:g.created_at,text:'Development goal created',sub:g.status||'active'}));
  return events.sort((a,b)=>new Date(b.date)-new Date(a.date)).slice(0,8);
}

async function loadMasterCommandCenter(force=false){
  if(masterLoaded&&!force)return;
  injectMasterStyles();const host=$d('#masterView');if(!host)return;
  host.innerHTML='<div class="master-shell"><div style="padding:40px;color:#7fa0ba">Loading executive intelligence...</div></div><div class="compat-master"><span id="gNow"></span><span id="gYear"></span><span id="gLater"></span><span id="gNot"></span><tbody id="promoBody"></tbody><div id="masterReviews"></div></div>';
  try{const d=await getMasterData();const locMetrics=d.locations.map(l=>({loc:l,m:locationMetrics(d,l)}));
    const totalEmployees=d.employees.length,totalLoc=d.locations.length,totalReviews=d.reviews.length,finalized=d.reviews.filter(r=>r.status==='finalized').length,open=d.reviews.filter(r=>r.status!=='finalized').length,activeCoach=d.coach.filter(c=>c.active_carry_forward).length,activeGoals=d.goals.filter(g=>['not_started','in_progress'].includes(g.status)).length,readyNow=d.promo.filter(p=>p.readiness==='Ready Now').length,ready1=d.promo.filter(p=>p.readiness==='Ready in 1 Year').length;
    const reviewCompletion=pct(finalized,totalReviews),benchStrength=pct(readyNow+ready1,Math.max(1,totalEmployees)),coachingResolution=pct(d.coach.filter(c=>!c.active_carry_forward||c.resolved_streak>=2).length,Math.max(1,d.coach.filter(c=>c.type!=='recognition').length)),goalCoverage=pct(new Set(d.goals.filter(g=>['not_started','in_progress'].includes(g.status)).map(g=>g.employee_id)).size,totalEmployees);
    const atRisk=locMetrics.filter(x=>x.m.health<60).length,healthy=locMetrics.filter(x=>x.m.health>=80).length,recognition=d.coach.filter(c=>c.type==='recognition').length,corrective=d.coach.filter(c=>c.type==='corrective'&&c.active_carry_forward).length;
    const locRows=locMetrics.sort((a,b)=>b.m.health-a.m.health).map(({loc,m})=>`<tr><td><strong>LOC ${escd(loc.location_code)}</strong><br><span style="color:#6f91aa">${escd(loc.city||loc.name)}${loc.state_code?', '+escd(loc.state_code):''}</span></td><td>${m.employees}</td><td>${m.completion}%</td><td>${m.ready}</td><td>${m.coach}</td><td><span class="health ${healthClass(m.health)}"><i></i>${m.health}</span></td></tr>`).join('');
    const activity=buildActivity(d).map(a=>`<div class="activity-row"><i class="activity-dot"></i><div class="activity-main">${escd(a.text)}<small>${escd(a.sub)}</small></div><div class="activity-time">${escd(ageText(a.date))}</div></div>`).join('')||'<div class="master-sub">Activity will populate as CTOD is used.</div>';
    host.innerHTML=`<div class="master-shell">
      <div class="master-hero"><div><div class="master-eyebrow">CTOD Executive Intelligence</div><h2 class="master-title">Talent Command Center</h2><div class="master-sub">Company-wide people readiness, development velocity, coaching health and succession depth in one live view.</div></div><div class="live-chip"><span class="live-dot"></span>LIVE · SUPABASE</div></div>
      <div class="master-kpis">
        <div class="mkpi"><small>ACTIVE EMPLOYEES</small><strong>${totalEmployees}</strong><div class="delta">6-digit identity records</div></div>
        <div class="mkpi"><small>ACTIVE LOCATIONS</small><strong>${totalLoc}</strong><div class="delta">${healthy} high-health</div></div>
        <div class="mkpi"><small>REVIEW COMPLETION</small><strong>${reviewCompletion}%</strong><div class="delta">${finalized} finalized · ${open} open</div></div>
        <div class="mkpi"><small>READY NOW</small><strong>${readyNow}</strong><div class="delta">succession bench</div></div>
        <div class="mkpi"><small>ACTIVE COACHING</small><strong>${activeCoach}</strong><div class="delta">${corrective} corrective open</div></div>
        <div class="mkpi"><small>ACTIVE GOALS</small><strong>${activeGoals}</strong><div class="delta">development pipeline</div></div>
      </div>
      <div class="master-grid">
        <section class="master-card"><h3>Location Intelligence Map</h3><div class="caption">Live health pins across every CTOD location. Green is strong, amber needs attention, red is risk.</div><div id="ctodMap"></div></section>
        <section class="master-card"><h3>Enterprise Pulse</h3><div class="caption">Four signals that tell leadership whether the organization is developing forward.</div><div class="gauge-row">${ring(reviewCompletion,'Review Completion','#39c6ff')}${ring(benchStrength,'Bench Strength','#2ad17f')}${ring(coachingResolution,'Coaching Resolution','#ffbd52')}</div><div class="metric-list">${metric('Goal Coverage',goalCoverage)}${metric('Location Health',totalLoc?locMetrics.reduce((s,x)=>s+x.m.health,0)/totalLoc:0)}${metric('Ready ≤ 1 Year',pct(readyNow+ready1,totalEmployees))}</div></section>
        <section class="master-card"><h3>People Intelligence</h3><div class="caption">Fast executive read on talent depth and development activity.</div><div class="intel-grid"><div class="intel"><div class="lbl">Ready Now</div><div class="num">${readyNow}</div><div class="note">immediate promotion bench</div></div><div class="intel"><div class="lbl">Ready in 1 Year</div><div class="num">${ready1}</div><div class="note">near-term pipeline</div></div><div class="intel"><div class="lbl">Recognition</div><div class="num">${recognition}</div><div class="note">positive coaching records</div></div><div class="intel"><div class="lbl">Locations at Risk</div><div class="num">${atRisk}</div><div class="note">health score below 60</div></div></div></section>
        <section class="master-card"><h3>Live Activity Stream</h3><div class="caption">Newest signals entering CTOD from managers and reviews.</div><div class="activity">${activity}</div></section>
        <section class="master-card wide"><h3>Location Performance Matrix</h3><div class="caption">A command-level comparison of every location using the same CTOD signals.</div><div class="tablewrap"><table class="location-table"><thead><tr><th>Location</th><th>Employees</th><th>Review Completion</th><th>Ready Now</th><th>Active Coaching</th><th>Health Score</th></tr></thead><tbody>${locRows}</tbody></table></div></section>
        <div class="master-footer-note">CTOD Master · Identity anchored to 6-digit employee number · data refreshes from production</div>
      </div>
    </div><div class="compat-master"><span id="gNow"></span><span id="gYear"></span><span id="gLater"></span><span id="gNot"></span><table><tbody id="promoBody"></tbody></table><div id="masterReviews"></div></div>`;
    masterLoaded=true;
    document.dispatchEvent(new CustomEvent('ctod:master-rendered'));
    if(window.ctodRenderMasterMap)setTimeout(()=>window.ctodRenderMasterMap(true),30);
  }catch(e){host.innerHTML=`<div class="master-shell"><div class="issue">Could not load Master intelligence: ${escd(e.message)}</div></div><div class="compat-master"><span id="gNow"></span><span id="gYear"></span><span id="gLater"></span><span id="gNot"></span><table><tbody id="promoBody"></tbody></table><div id="masterReviews"></div></div>`}
}

async function initMaster(){
  injectMasterStyles();for(let i=0;i<40;i++){const b=$d('#tabMaster');if(b)break;await new Promise(r=>setTimeout(r,250))}
  const b=$d('#tabMaster');if(!b)return;b.addEventListener('click',()=>setTimeout(()=>loadMasterCommandCenter(true),20));
  const u=(await sbd.auth.getUser()).data.user;if(!u)return;const m=await sbd.from('company_memberships').select('role').eq('user_id',u.id).eq('active',true).maybeSingle();if(['owner','admin','executive'].includes(m.data?.role))loadMasterCommandCenter();
}
initMaster();
