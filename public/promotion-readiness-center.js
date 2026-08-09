import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const prc=createClient('https://wezcuprboyvbmlnuqdoi.supabase.co','sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5');
const $p=s=>document.querySelector(s), escp=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
let roleCache=null,currentCareerReview=null,careerSaveBusy=false;

async function roles(){if(roleCache)return roleCache;const r=await prc.from('roles').select('id,title,sort_order').eq('active',true).order('sort_order');roleCache=r.data||[];return roleCache}
function roleOptions(list,selected,label='Choose position...'){return `<option value="">${label}</option>`+list.map(r=>`<option value="${r.id}" ${r.id===selected?'selected':''}>${escp(r.title)}</option>`).join('')}

async function resolveActiveReview(){
 const root=$p('#reviewDetail');if(!root||!$p('#promotionReadiness'))return null;
 const name=root.querySelector('h3')?.textContent?.trim();const meta=root.querySelector('.meta')?.textContent||'';const loc=(meta.match(/Location\s+(\d+)/i)||[])[1];if(!name)return null;
 const q=await prc.from('reviews').select('id,status,employee_id,location_id,employees!reviews_employee_id_fkey(first_name,last_name),locations(location_code)').neq('status','finalized').order('updated_at',{ascending:false}).limit(100);
 return (q.data||[]).find(r=>`${r.employees?.first_name||''} ${r.employees?.last_name||''}`.trim()===name&&(!loc||String(r.locations?.location_code||'').padStart(3,'0')===String(loc).padStart(3,'0')))||null;
}

async function installCareerSelectors(){
 const ready=$p('#promotionReadiness'),root=$p('#reviewDetail');if(!ready||!root||root.dataset.careerPathEnhanced==='1')return;
 const review=await resolveActiveReview();if(!review)return;currentCareerReview=review.id;
 const [rs,cd]=await Promise.all([roles(),prc.from('career_decisions').select('desired_role_id,final_desired_role_id').eq('review_id',review.id).maybeSingle()]);
 const current=cd.data||{};const promoGrid=ready.closest('.grid2');if(!promoGrid)return;
 const path=document.createElement('div');path.className='grid2 career-path-grid';path.style.marginTop='12px';path.innerHTML=`<div><label>Next position desired</label><select id="nextPositionRole" class="field">${roleOptions(rs,current.desired_role_id,'Choose next position...')}</select><div class="sub">The employee's next intended position in CTOD.</div></div><div><label>10-year / final position desired</label><select id="finalPositionRole" class="field">${roleOptions(rs,current.final_desired_role_id,'Choose long-term position...')}</select><div class="sub">Long-term destination or final desired company role.</div></div>`;
 promoGrid.insertAdjacentElement('afterend',path);root.dataset.careerPathEnhanced='1';
 const save=()=>saveCareerRoles(review.id);$p('#nextPositionRole').onchange=save;$p('#finalPositionRole').onchange=save;
 const msg=$p('#reviewSaveMsg');if(msg){new MutationObserver(()=>{const t=msg.textContent||'';if(t.includes('Draft saved')||t.includes('Review finalized'))saveCareerRoles(review.id)}).observe(msg,{childList:true,subtree:true,characterData:true})}
}
async function saveCareerRoles(reviewId){
 if(careerSaveBusy)return;const next=$p('#nextPositionRole'),final=$p('#finalPositionRole');if(!next||!final)return;careerSaveBusy=true;
 const r=await prc.rpc('save_review_career_roles',{p_review_id:reviewId,p_desired_role_id:next.value||null,p_final_desired_role_id:final.value||null});careerSaveBusy=false;
 if(r.error){const msg=$p('#reviewSaveMsg');if(msg)msg.textContent='Career path save failed: '+r.error.message}
}

function injectStyles(){if($p('#promotionReadinessStyles'))return;const s=document.createElement('style');s.id='promotionReadinessStyles';s.textContent=`
 .promotion-center{margin-bottom:14px;background:linear-gradient(135deg,rgba(11,38,62,.98),rgba(8,26,44,.98));border:1px solid #24537a;border-radius:19px;padding:16px;box-shadow:inset 0 1px rgba(255,255,255,.04)}
 .promotion-head{display:flex;justify-content:space-between;gap:16px;align-items:flex-end;flex-wrap:wrap}.promotion-head h3{margin:3px 0 0;color:#fff;font-size:20px}.promotion-filters{display:flex;gap:10px;flex-wrap:wrap}.promotion-filters select{min-width:220px;background:#091d31!important;color:#eaf2fb!important;border-color:#28506e!important}.promotion-results{margin-top:14px;display:grid;gap:8px}.promotion-row{display:grid;grid-template-columns:1.5fr .8fr 1fr 1fr .8fr;gap:12px;align-items:center;padding:11px 12px;background:#091d31;border:1px solid #173b58;border-radius:13px;color:#dce9f4}.promotion-row small{display:block;color:#7897ae;margin-top:2px}.promotion-badge{display:inline-flex;padding:5px 9px;border-radius:999px;background:#102d48;color:#b9dcf7;font-size:11px;font-weight:900}.promotion-empty{padding:22px;text-align:center;color:#7897ae;border:1px dashed #28506e;border-radius:13px}.career-path-grid select{font-weight:700}
 @media(max-width:850px){.promotion-row{grid-template-columns:1fr 1fr}.promotion-row>div:first-child{grid-column:1/-1}}
 `;document.head.appendChild(s)}

async function installPromotionCenter(){
 const shell=$p('#masterView .master-shell');if(!shell||$p('#promotionCenter'))return;injectStyles();
 const rs=await roles();const box=document.createElement('section');box.id='promotionCenter';box.className='promotion-center';box.innerHTML=`<div class="promotion-head"><div><div class="master-eyebrow">Promotion Readiness</div><h3>Company Talent Pipeline</h3><div class="master-sub">Select a target role to see every employee who chose it as their next position on their latest finalized review.</div></div><div class="promotion-filters"><select id="pipelineRole" class="field">${roleOptions(rs,null,'All next positions')}</select><select id="pipelineReadiness" class="field"><option value="">All readiness levels</option>${['Ready Now','Ready in 1 Year','Ready in 2-3 Years','Not Yet Ready','Not set'].map(x=>`<option>${x}</option>`).join('')}</select></div></div><div id="promotionResults" class="promotion-results"><div class="promotion-empty">Choose a role or view the complete pipeline.</div></div>`;
 const hero=shell.querySelector('.master-hero');hero?.insertAdjacentElement('afterend',box);$p('#pipelineRole').onchange=renderPipeline;$p('#pipelineReadiness').onchange=renderPipeline;await renderPipeline();
}
async function renderPipeline(){
 const host=$p('#promotionResults');if(!host)return;host.innerHTML='<div class="promotion-empty">Loading talent pipeline...</div>';
 const role=$p('#pipelineRole')?.value||'',readiness=$p('#pipelineReadiness')?.value||'';let q=prc.from('v_promotion_pipeline').select('*').order('last_name');if(role)q=q.eq('desired_role_id',role);if(readiness)q=q.eq('readiness',readiness);const r=await q;
 if(r.error){host.innerHTML=`<div class="promotion-empty">${escp(r.error.message)}</div>`;return}const rows=r.data||[];
 host.innerHTML=rows.length?rows.map(x=>`<div class="promotion-row"><div><strong>${escp(x.first_name)} ${escp(x.last_name)}</strong><small>#${escp(x.employee_code)} · Location ${escp(x.location_code||'')}</small></div><div><small>Current</small><strong>${escp(x.current_role||'—')}</strong></div><div><small>Next Position</small><strong>${escp(x.next_role||'—')}</strong></div><div><small>Long-Term</small><strong>${escp(x.final_desired_role||'—')}</strong></div><div><span class="promotion-badge">${escp(x.readiness||'Not set')}</span></div></div>`).join(''):`<div class="promotion-empty">No employees match these promotion filters yet.</div>`;
}

const obs=new MutationObserver(()=>{installCareerSelectors();installPromotionCenter()});obs.observe(document.documentElement,{childList:true,subtree:true});injectStyles();setTimeout(()=>{installCareerSelectors();installPromotionCenter()},800);
