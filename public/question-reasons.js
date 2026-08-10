import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const qr=createClient('https://wezcuprboyvbmlnuqdoi.supabase.co','sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5');
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
const cache=new Map();
async function loadQuestionReasons(questionId,ratingCode){
 const key=questionId+'|'+ratingCode;if(cache.has(key))return cache.get(key);
 const q=await qr.from('question_definitions').select('question_code').eq('id',questionId).single();
 if(q.error)throw q.error;
 const prefix=q.data.question_code+':'+ratingCode+':';
 const r=await qr.from('reason_definitions').select('id,label,sort_order,external_code').eq('active',true).eq('rating_code',ratingCode).like('external_code',prefix+'%').order('sort_order');
 if(r.error)throw r.error;cache.set(key,r.data||[]);return r.data||[];
}
async function syncCard(card){
 const rating=card.querySelector('.qrating'),reason=card.querySelector('.qreason');if(!rating||!reason)return;
 const ratingCode=rating.selectedOptions?.[0]?.dataset?.code||'';if(!ratingCode){reason.innerHTML='<option value="">Choose rating first...</option>';return}
 const prior=reason.value;const rows=await loadQuestionReasons(card.dataset.qid,ratingCode);
 reason.innerHTML='<option value="">Choose reason...</option>'+rows.map(x=>`<option value="${x.id}" ${x.id===prior?'selected':''}>${esc(x.label)}</option>`).join('');
 if(rows.length!==3){const s=card.querySelector('.qstatus');if(s)s.textContent=`Configuration warning: expected 3 tailored reasons, found ${rows.length}.`}
}
async function syncAll(){for(const card of document.querySelectorAll('.qcard')){try{await syncCard(card)}catch(e){const s=card.querySelector('.qstatus');if(s)s.textContent='Could not load tailored reasons: '+e.message}}}
document.addEventListener('change',e=>{if(e.target.matches('.qrating')){const card=e.target.closest('.qcard');setTimeout(()=>syncCard(card),0)}});
let queued=false;const schedule=()=>{if(queued)return;queued=true;setTimeout(async()=>{queued=false;await syncAll()},120)};new MutationObserver(schedule).observe(document.documentElement,{childList:true,subtree:true});setTimeout(schedule,400);