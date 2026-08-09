import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const ml3=createClient('https://wezcuprboyvbmlnuqdoi.supabase.co','sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5');
const $m=s=>document.querySelector(s);
let busy=false,timer=0;

function styles(){
 if($m('#masterLayoutV3Styles'))return;
 const s=document.createElement('style');s.id='masterLayoutV3Styles';s.textContent=`
 .master-top-visuals{display:grid;grid-template-columns:minmax(0,1.7fr) minmax(300px,.72fr);gap:14px;margin-bottom:14px;align-items:stretch}
 .master-top-visuals>.master-card{margin:0;min-width:0}.master-top-visuals #ctodMap{height:440px!important}
 .promotion-bench-card{display:flex;flex-direction:column;justify-content:space-between;background:radial-gradient(circle at 50% 12%,rgba(57,198,255,.15),transparent 42%),linear-gradient(180deg,#0a2137,#071827);border:1px solid #214966;border-radius:19px;padding:18px;min-height:100%}
 .promotion-bench-title{font-size:17px;font-weight:900;color:#fff;margin:0}.promotion-bench-sub{font-size:11px;color:#7897ae;margin-top:4px;line-height:1.4}
 .promotion-big-ring{--bench:0;--bench-color:#ff5f68;width:190px;height:190px;border-radius:50%;margin:20px auto 12px;background:conic-gradient(var(--bench-color) calc(var(--bench)*1%),#153149 0);display:grid;place-items:center;position:relative;box-shadow:0 0 36px color-mix(in srgb,var(--bench-color) 25%,transparent)}
 .promotion-big-ring:before{content:"";position:absolute;inset:17px;border-radius:50%;background:linear-gradient(145deg,#071827,#0b2237);border:1px solid #23455f}
 .promotion-big-ring-inner{position:relative;text-align:center}.promotion-big-ring-count{font-size:45px;line-height:1;font-weight:1000;color:#fff}.promotion-big-ring-pct{font-size:16px;font-weight:900;color:var(--bench-color);margin-top:6px}.promotion-big-ring-label{font-size:10px;letter-spacing:.1em;text-transform:uppercase;color:#7897ae;margin-top:5px;font-weight:900}
 .bench-target{display:flex;justify-content:space-between;gap:10px;padding-top:12px;border-top:1px solid #173b58;font-size:11px;color:#819db2}.bench-target b{color:#dcebf6}.bench-status{display:inline-flex;align-items:center;gap:6px;font-weight:900}.bench-status i{width:8px;height:8px;border-radius:50%;background:var(--bench-color);box-shadow:0 0 10px var(--bench-color)}
 #promotionCenter{margin-top:0!important;margin-bottom:14px!important}
 @media(max-width:920px){.master-top-visuals{grid-template-columns:1fr}.promotion-bench-card{min-height:auto}.promotion-big-ring{width:160px;height:160px}.promotion-big-ring-count{font-size:38px}}
 `;document.head.appendChild(s);
}

function makeMasterFirst(){
 const tabs=$m('#app>.tabs'),master=$m('#tabMaster');if(!tabs||!master)return;
 const first=tabs.querySelector('.tab');if(first!==master)tabs.insertBefore(master,first);
}

function readinessColor(p){return p>=25?'#2ad17f':p>=10?'#ffbd52':'#ff5f68'}
function readinessLabel(p){return p>=25?'GOOD BENCH':p>=10?'BUILDING BENCH':'THIN BENCH'}

async function benchCard(){
 const [e,p]=await Promise.all([
   ml3.from('employees').select('id',{count:'exact',head:true}).eq('employment_status','active'),
   ml3.from('v_promotion_readiness').select('employee_id,readiness')
 ]);
 const total=e.count||0;
 const readyIds=new Set((p.data||[]).filter(x=>x.readiness==='Ready Now').map(x=>x.employee_id).filter(Boolean));
 const ready=readyIds.size;
 const percent=total?Math.round(ready/total*1000)/10:0;
 const targetFill=Math.min(100,percent/25*100);
 const color=readinessColor(percent),label=readinessLabel(percent);
 const card=document.createElement('section');card.className='promotion-bench-card';card.id='promotionBenchGauge';
 card.innerHTML=`<div><div class="master-eyebrow">Promotion Capacity</div><h3 class="promotion-bench-title">Ready Now Bench</h3><div class="promotion-bench-sub">25% of the total workforce Ready Now is the healthy CTOD target.</div></div><div class="promotion-big-ring" style="--bench:${targetFill};--bench-color:${color}"><div class="promotion-big-ring-inner"><div class="promotion-big-ring-count">${ready}</div><div class="promotion-big-ring-pct">${percent}% of workforce</div><div class="promotion-big-ring-label">Ready Now</div></div></div><div class="bench-target"><span class="bench-status" style="--bench-color:${color}"><i></i>${label}</span><span><b>${ready}</b> of <b>${total}</b> employees · target <b>25%</b></span></div>`;
 return card;
}

async function arrange(){
 if(busy)return;busy=true;
 try{
   styles();makeMasterFirst();
   const shell=$m('#masterView .master-shell'),map=$m('#ctodMap');if(!shell||!map)return;
   const mapCard=map.closest('.master-card');if(!mapCard)return;
   let visuals=shell.querySelector('.master-top-visuals');
   if(!visuals){visuals=document.createElement('div');visuals.className='master-top-visuals';const kpis=shell.querySelector('.master-kpis');if(kpis)kpis.insertAdjacentElement('afterend',visuals);else shell.querySelector('.master-hero')?.insertAdjacentElement('afterend',visuals)}
   if(mapCard.parentElement!==visuals)visuals.appendChild(mapCard);
   let gauge=$m('#promotionBenchGauge');if(!gauge){gauge=await benchCard();visuals.appendChild(gauge)}
   const pipeline=$m('#promotionCenter');if(pipeline){visuals.insertAdjacentElement('afterend',pipeline)}
   // Keep KPI strip directly under hero, then map + gauge, then talent pipeline.
   const hero=shell.querySelector('.master-hero'),kpis=shell.querySelector('.master-kpis');if(hero&&kpis&&hero.nextElementSibling!==kpis)hero.insertAdjacentElement('afterend',kpis);
   if(kpis&&kpis.nextElementSibling!==visuals)kpis.insertAdjacentElement('afterend',visuals);
   if(pipeline&&visuals.nextElementSibling!==pipeline)visuals.insertAdjacentElement('afterend',pipeline);
 }catch(e){console.error('CTOD Master Layout v3',e)}finally{busy=false}
}

function schedule(){clearTimeout(timer);timer=setTimeout(arrange,180)}
new MutationObserver(schedule).observe(document.documentElement,{childList:true,subtree:true});
setInterval(makeMasterFirst,1500);
schedule();
