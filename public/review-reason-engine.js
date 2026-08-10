import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const rr=createClient('https://wezcuprboyvbmlnuqdoi.supabase.co','sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5');
let loaded=false,loading=false,questionCode=new Map(),reasonRows=[];
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
async function load(){if(loaded||loading)return;loading=true;try{const [q,r]=await Promise.all([rr.from('question_definitions').select('id,question_code').eq('active',true),rr.from('reason_definitions').select('id,label,rating_code,category,sort_order').eq('active',true).in('reason_type',['review_org','review_role']).order('sort_order')]);for(const x of q.data||[])questionCode.set(x.id,x.question_code);reasonRows=r.data||[];loaded=true}finally{loading=false}}
function ratingCode(card){const opt=card.querySelector('.qrating')?.selectedOptions?.[0];return opt?.dataset?.code||''}
function populate(card){const code=questionCode.get(card.dataset.qid),rating=ratingCode(card),sel=card.querySelector('.qreason');if(!code||!sel)return;const prior=sel.value;const rows=reasonRows.filter(x=>x.category===code&&x.rating_code===rating);sel.innerHTML='<option value="">Choose reason...</option>'+rows.map(x=>`<option value="${x.id}" ${x.id===prior?'selected':''}>${esc(x.label)}</option>`).join('');if(prior&&!rows.some(x=>x.id===prior))sel.value=''}
async function syncAll(){await load();document.querySelectorAll('.qcard').forEach(populate)}
document.addEventListener('change',e=>{if(!e.target.matches('.qrating'))return;const card=e.target.closest('.qcard');setTimeout(async()=>{await load();populate(card)},0)},true);
new MutationObserver(()=>setTimeout(syncAll,20)).observe(document.documentElement,{childList:true,subtree:true});
setTimeout(syncAll,300);setTimeout(syncAll,900);
