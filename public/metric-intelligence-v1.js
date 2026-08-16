const sb=window.ctodSupabase;
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
let payload=null,role='';
function tone(v){return v>=80?'#2ad17f':v>=60?'#ffbd52':'#ff5f68'}
function byMetric(rows,key){return (rows||[]).filter(x=>x.metric_key===key)}
function counts(rows){const m=new Map();for(const r of rows||[])m.set(String(r.response_value??'Not set'),Number(r.n||0));return m}
function total(map){let n=0;for(const v of map.values())n+=v;return n}
function pct(n,d){return d?Math.round(n/d*100):0}
function positivePercent(def,rows){const c=counts(rows),n=total(c),pos=(def.positive_values||[]).reduce((s,v)=>s+(c.get(String(v))||0),0);return {value:pct(pos,n),n,c}}
function ring(def,rows){const x=positivePercent(def,rows);return `<div class="ctod-gauge"><div class="ctod-ring" style="--p:${x.value};--ring:${tone(x.value)}"><div><b>${x.value}%</b><span>${esc(def.label)}</span></div></div><small>${x.n} finalized response${x.n===1?'':'s'}</small></div>`}
function distribution(def,rows){const c=counts(rows),n=total(c);const bars=[...c.entries()].sort((a,b)=>b[1]-a[1]).map(([label,count])=>`<div class="ctod-bar-row"><div class="ctod-bar-label"><span>${esc(label)}</span><b>${pct(count,n)}%</b></div><div class="ctod-track"><i style="width:${pct(count,n)}%;background:#39c6ff"></i></div></div>`).join('');return `<div class="ctod-bar-panel"><h4>${esc(def.label)}</h4>${bars||'<div class="sub">No finalized responses yet.</div>'}</div>`}
function roleRows(def){if(!role)return byMetric(payload?.overall,def.metric_key);return (payload?.by_role||[]).filter(x=>x.metric_key===def.metric_key&&x.role_title===role)}
function roleOptions(){return [...new Set((payload?.by_role||[]).map(x=>x.role_title).filter(Boolean))].sort()}
function html(){const defs=(payload?.definitions||[]).filter(d=>d.feeds_master);const gauges=defs.filter(d=>d.visualization==='gauge'||d.aggregation==='percent_positive');const distributions=defs.filter(d=>!gauges.includes(d));return `<div class="ctod-dashboard-head"><div><div class="ctod-eyebrow">CTOD Metric Intelligence</div><div class="ctod-title">People Pulse</div><div class="sub">Generated from configurable metric definitions. Question wording can vary by customer while the intelligence pathway remains the same.</div></div><select id="metricRoleFilter" class="field" style="max-width:310px"><option value="">All job roles</option>${roleOptions().map(r=>`<option value="${esc(r)}" ${r===role?'selected':''}>${esc(r)}</option>`).join('')}</select></div>${gauges.length?`<div class="ctod-gauges">${gauges.map(d=>ring(d,roleRows(d))).join('')}</div>`:''}${distributions.length?`<div class="ctod-bars">${distributions.map(d=>distribution(d,roleRows(d))).join('')}</div>`:''}<div class="sub" style="margin-top:12px">${defs.length} Master metric${defs.length===1?'':'s'} active. New metrics flagged “feeds Master” render here automatically.</div>`}
function wire(host){const s=host?.querySelector('#metricRoleFilter');if(s)s.onchange=()=>{role=s.value;host.innerHTML=html();wire(host)}}
function render(){for(const sel of ['#masterPulse','#peoplePulse']){const host=document.querySelector(sel);if(host){host.className='ctod-section';host.innerHTML=html();wire(host)}}}
async function load(){if(!sb)return;const r=await sb.rpc('metric_intelligence',{p_metric_keys:null});if(r.error){console.warn('CTOD metric intelligence fallback:',r.error.message);return}payload=r.data||{definitions:[],overall:[],by_role:[],by_location:[]};window.ctodMetricIntelligence=payload;render();document.dispatchEvent(new CustomEvent('ctod:metric-intelligence-ready',{detail:payload}))}
window.ctodReloadMetricIntelligence=load;
document.addEventListener('ctod:workspace-ready',()=>setTimeout(load,350));
document.addEventListener('click',e=>{if(e.target.closest('#tabMaster,#tabReviews'))setTimeout(()=>{if(payload)render();else load()},150)});
setTimeout(load,700);
