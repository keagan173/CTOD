import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const sbm=createClient('https://wezcuprboyvbmlnuqdoi.supabase.co','sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5');
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));

// City-center fallback coordinates keep every active location visible immediately.
// Exact latitude/longitude stored on a location always wins over the fallback.
const CITY={
'boise|ID':[43.6150,-116.2023],'burley|ID':[42.5357,-113.7928],'twin falls|ID':[42.5629,-114.4609],
'pocatello|ID':[42.8713,-112.4455],'gooding|ID':[42.9388,-114.7131],'nampa|ID':[43.5407,-116.5635],
'idaho falls|ID':[43.4917,-112.0339],'caldwell|ID':[43.6629,-116.6874],'grandview|ID':[43.2271,-116.1007],
'lewiston|ID':[46.4166,-117.0177],'mtn home|ID':[43.1329,-115.6912],'aberdeen|ID':[42.9441,-112.8383],
'emmett|ID':[43.8735,-116.4993],'meridian|ID':[43.6121,-116.3915],'rexburg|ID':[43.8260,-111.7897],
'kuna|ID':[43.4918,-116.4201],'buhl|ID':[42.5991,-114.7595],'eagle|ID':[43.6954,-116.3540],
'lagrande|OR':[45.3246,-118.0877],'la grande|OR':[45.3246,-118.0877],'ontario|OR':[44.0266,-116.9629],'baker city|OR':[44.7749,-117.8344],
'hermiston|OR':[45.8404,-119.2895],'portland|OR':[45.5152,-122.6784],
'sunnyside|WA':[46.3237,-120.0087],'pasco|WA':[46.2396,-119.1006],'othello|WA':[46.8259,-119.1753],
'moses lake|WA':[47.1301,-119.2781],'yakima|WA':[46.6021,-120.5059],'basin city|WA':[46.5943,-119.1522],
'quincy|WA':[47.2343,-119.8526],'kennewick|WA':[46.2087,-119.1190],'ellensburg|WA':[46.9965,-120.5478],
'spokane|WA':[47.6588,-117.4260],'n salt lake|UT':[40.8486,-111.9069],'ogden|UT':[41.2230,-111.9738],
'west jordan|UT':[40.6097,-111.9391],'vernal|UT':[40.4555,-109.5287],'orem|UT':[40.2969,-111.6946],
'wellsville|UT':[41.6385,-111.9330],'roosevelt|UT':[40.2994,-109.9888]
};
const STATE={ID:[44.10,-114.55],OR:[44.10,-120.55],WA:[47.35,-120.75],UT:[39.50,-111.55]};
const cleanCity=s=>String(s||'').trim().toLowerCase().replace(/\./g,'').replace(/\s+/g,' ').replace('mountain home','mtn home');
function jitter(code){const n=Number(String(code||'0').replace(/\D/g,''))||0;return [((n%7)-3)*.025,(((n*3)%7)-3)*.035]}
function coords(loc){if(Number(loc.latitude)&&Number(loc.longitude))return [Number(loc.latitude),Number(loc.longitude),'exact'];const key=`${cleanCity(loc.city)}|${String(loc.state_code||'').toUpperCase()}`;let base=CITY[key];if(!base){const st=String(loc.state_code||'').toUpperCase();base=STATE[st]}if(!base)return null;const j=jitter(loc.location_code);return [base[0]+j[0],base[1]+j[1],'city']}
function hc(v){return v>=80?'#2ad17f':v>=60?'#ffbd52':'#ff5f68'}
function pct(n,d){return d?Math.round(n/d*100):0}

async function ensureLeaflet(){if(window.L)return;await new Promise((resolve,reject)=>{if(!document.querySelector('link[data-ctod-leaflet]')){const css=document.createElement('link');css.rel='stylesheet';css.href='https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';css.dataset.ctodLeaflet='1';document.head.appendChild(css)}const existing=document.querySelector('script[data-ctod-leaflet]');if(existing){if(window.L)resolve();else existing.addEventListener('load',resolve,{once:true});return}const s=document.createElement('script');s.src='https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';s.dataset.ctodLeaflet='1';s.onload=resolve;s.onerror=reject;document.head.appendChild(s)})}
function styles(){if(document.querySelector('#ctodMapV2Styles'))return;const s=document.createElement('style');s.id='ctodMapV2Styles';s.textContent=`
.map-commandbar{display:flex;gap:9px;align-items:center;flex-wrap:wrap;margin-top:12px;padding:10px;background:linear-gradient(180deg,#091e32,#071827);border:1px solid #183d5b;border-radius:13px}.map-stat{padding:7px 10px;border:1px solid #1e4769;border-radius:10px;background:#0b253c;color:#a9c9df;font-size:11px;font-weight:800}.map-stat b{color:#fff}.map-filter{margin-left:auto;display:flex;gap:8px}.map-filter select{background:#081b2c;color:#d9e9f6;border:1px solid #24506f;border-radius:9px;padding:7px 28px 7px 9px;font-size:11px}.map-legend{display:flex;gap:11px;align-items:center;margin-top:8px;color:#7798b1;font-size:10px}.map-legend i{width:8px;height:8px;border-radius:50%;display:inline-block;margin-right:4px}.map-popup-title{font-size:14px;font-weight:900;margin-bottom:3px}.map-popup-sub{color:#8ba9be;margin-bottom:9px}.map-popup-grid{display:grid;grid-template-columns:1fr 1fr;gap:5px 12px;font-size:11px}.map-popup-grid b{color:white}.map-focus{width:100%;border:0;border-radius:8px;padding:7px;margin-top:10px;background:#1f6feb;color:white;font-weight:800;cursor:pointer}.location-table tbody tr.ctod-map-focus{outline:2px solid #39c6ff;outline-offset:-2px;background:rgba(57,198,255,.08)}
@media(max-width:700px){.map-filter{margin-left:0;width:100%}.map-filter select{flex:1}}
`;document.head.appendChild(s)}

async function data(){const [l,a,r,c,p]=await Promise.all([
 sbm.from('locations').select('id,location_code,name,city,state_code,latitude,longitude,market_name,area_name').eq('status','active').order('location_code'),
 sbm.from('employment_assignments').select('employee_id,location_id,effective_to').is('effective_to',null),
 sbm.from('reviews').select('location_id,status'),
 sbm.from('coaching_moments').select('employee_id,type,active_carry_forward'),
 sbm.from('v_promotion_readiness').select('location_code,readiness')
]);if(l.error)throw l.error;return{locations:l.data||[],assignments:a.data||[],reviews:r.data||[],coach:c.data||[],promo:p.data||[]}}
function metrics(d,loc){const ids=new Set(d.assignments.filter(x=>x.location_id===loc.id).map(x=>x.employee_id));const rv=d.reviews.filter(x=>x.location_id===loc.id),fin=rv.filter(x=>x.status==='finalized').length,completion=pct(fin,rv.length);const corrective=d.coach.filter(x=>ids.has(x.employee_id)&&x.type==='corrective'&&x.active_carry_forward).length;const ready=d.promo.filter(x=>String(x.location_code||'').padStart(3,'0')===String(loc.location_code).padStart(3,'0')&&x.readiness==='Ready Now').length;const bench=pct(ready,Math.max(1,ids.size));const health=Math.max(0,Math.min(100,Math.round(completion*.55+Math.min(100,bench*2)*.25+(100-Math.min(100,corrective*18))*.20)));return{employees:ids.size,completion,corrective,ready,health}}

window.ctodFocusLocation=code=>{const rows=[...document.querySelectorAll('.location-table tbody tr')];const row=rows.find(r=>r.textContent.includes('LOC '+String(code).padStart(3,'0')));if(!row)return;rows.forEach(r=>r.classList.remove('ctod-map-focus'));row.classList.add('ctod-map-focus');row.scrollIntoView({behavior:'smooth',block:'center'});setTimeout(()=>row.classList.remove('ctod-map-focus'),3500)};

let timer=0,rendering=false,lastHost=null,expectedCount=0;
async function upgrade(force=false){const old=document.querySelector('#ctodMap');if(!old||rendering)return;const markerCount=old.querySelectorAll('.leaflet-marker-icon').length;const healthyV2=old.dataset.mapV2==='1'&&expectedCount>0&&markerCount>=Math.min(expectedCount,10);if(!force&&healthyV2)return;rendering=true;try{styles();const d=await data();expectedCount=d.locations.length;await ensureLeaflet();const fresh=document.createElement('div');fresh.id='ctodMap';fresh.dataset.mapV2='1';fresh.style.height='430px';fresh.style.borderRadius='14px';fresh.style.overflow='hidden';old.replaceWith(fresh);lastHost=fresh;
 const parent=fresh.parentElement;parent.querySelector('.map-commandbar')?.remove();parent.querySelector('.map-legend')?.remove();
 const states=[...new Set(d.locations.map(x=>x.state_code).filter(Boolean))].sort(),areas=[...new Set(d.locations.map(x=>x.area_name).filter(Boolean))].sort();
 const bar=document.createElement('div');bar.className='map-commandbar';bar.innerHTML=`<span class="map-stat"><b>${d.locations.length}</b> ACTIVE LOCATIONS</span><span class="map-stat"><b>${states.length}</b> STATES</span><span class="map-stat"><b>${areas.length}</b> AREAS</span><span class="map-stat"><b>${new Set(d.locations.map(x=>x.market_name).filter(Boolean)).size}</b> MARKETS</span><div class="map-filter"><select id="mapStateFilter"><option value="">All States</option>${states.map(x=>`<option>${esc(x)}</option>`).join('')}</select><select id="mapAreaFilter"><option value="">All Areas</option>${areas.map(x=>`<option>${esc(x)}</option>`).join('')}</select></div>`;parent.insertBefore(bar,fresh);
 const legend=document.createElement('div');legend.className='map-legend';legend.innerHTML='<span><i style="background:#2ad17f"></i>Strong</span><span><i style="background:#ffbd52"></i>Needs attention</span><span><i style="background:#ff5f68"></i>Risk</span><span style="margin-left:auto">Exact coordinates used when available · city placement otherwise</span>';fresh.after(legend);
 const map=L.map(fresh,{zoomControl:true,attributionControl:true});L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',{maxZoom:19,attribution:'&copy; OpenStreetMap &copy; CARTO'}).addTo(map);const group=L.layerGroup().addTo(map);
 function draw(){group.clearLayers();const st=document.querySelector('#mapStateFilter')?.value||'',ar=document.querySelector('#mapAreaFilter')?.value||'';const visible=d.locations.filter(x=>(!st||x.state_code===st)&&(!ar||x.area_name===ar));const bounds=[];visible.forEach(loc=>{const co=coords(loc);if(!co)return;const [lat,lng,quality]=co,m=metrics(d,loc);bounds.push([lat,lng]);const icon=L.divIcon({className:'',html:`<div style="width:32px;height:32px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);background:${hc(m.health)};border:3px solid #eaf5ff;box-shadow:0 0 16px ${hc(m.health)}88"><span style="display:block;transform:rotate(45deg);font-size:8px;color:#06111f;font-weight:1000;text-align:center;line-height:26px">${esc(loc.location_code)}</span></div>`,iconSize:[32,32],iconAnchor:[16,32]});const pop=`<div class="map-popup-title">Location ${esc(loc.location_code)} · ${esc(loc.name)}</div><div class="map-popup-sub">${esc(loc.city)}, ${esc(loc.state_code)} · Area ${esc(loc.area_name||'—')} · Market ${esc(loc.market_name||'—')}</div><div class="map-popup-grid"><span>Employees <b>${m.employees}</b></span><span>Health <b>${m.health}</b></span><span>Reviews <b>${m.completion}%</b></span><span>Ready Now <b>${m.ready}</b></span><span>Corrective <b>${m.corrective}</b></span><span>Map <b>${quality==='exact'?'Exact':'City'}</b></span></div><button class="map-focus" onclick="window.ctodFocusLocation('${esc(loc.location_code)}')">View in Performance Matrix</button>`;L.marker([lat,lng],{icon}).addTo(group).bindPopup(pop)});if(bounds.length){map.fitBounds(bounds,{padding:[34,34],maxZoom:7});if(bounds.length===1)map.setZoom(8)}fresh.dataset.markerCount=String(bounds.length)}
 draw();document.querySelector('#mapStateFilter').onchange=draw;document.querySelector('#mapAreaFilter').onchange=draw;setTimeout(()=>map.invalidateSize(),120);
 }catch(e){console.error('CTOD Master Map v2',e)}finally{rendering=false}}
function schedule(){clearTimeout(timer);timer=setTimeout(()=>upgrade(false),220)}
new MutationObserver(schedule).observe(document.documentElement,{childList:true,subtree:true});
// Self-healing guard: if the base Master renderer ever replaces the full map with its legacy one-pin map,
// CTOD automatically restores the company-wide map without requiring another deploy or tab switch.
setInterval(()=>{const host=document.querySelector('#ctodMap');if(!host)return;const markers=host.querySelectorAll('.leaflet-marker-icon').length;if(host.dataset.mapV2!=='1'||markers<10)upgrade(true)},1200);
schedule();