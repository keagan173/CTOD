const root=document.querySelector('#reviewDetail');
const sb=window.ctodSupabase;
if(root&&sb){
  let busy=false,queued=false;
  const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
  const READINESS=['Ready Now','30-90 Days','Within 1 Year','Not Yet Ready'];
  const opts=(vals,cur,ph)=>`<option value="">${esc(ph)}</option>`+vals.map(v=>`<option value="${esc(v)}" ${v===cur?'selected':''}>${esc(v)}</option>`).join('');
  async function repair(){
    if(busy)return;busy=true;
    try{
      const panel=root.querySelector('#ctodUnifiedCareerVoice');
      const direction=panel?.querySelector('#careerDirection');
      if(!panel||direction?.value!=='ADVANCEMENT')return;
      let block=panel.querySelector('#advancementFields');
      const complete=block&&block.querySelector('#nextPositionRole')&&block.querySelector('#finalPositionRole')&&block.querySelector('#careerPromotionReadiness');
      if(complete){block.style.display='block';return;}
      const reviewId=panel.dataset.reviewId;if(!reviewId)return;
      const [career,roles]=await Promise.all([
        sb.from('career_decisions').select('desired_role_id,final_desired_role_id,promotion_readiness').eq('review_id',reviewId).maybeSingle(),
        sb.from('roles').select('id,title,sort_order').eq('active',true).order('sort_order')
      ]);
      const c=career.data||{},rs=roles.data||[];
      if(block)block.remove();
      block=document.createElement('div');
      block.id='advancementFields';
      block.style.display='block';
      block.innerHTML=`<div class="grid2" style="margin-top:12px"><div><label>Next position desired <strong>REQUIRED</strong></label><select id="nextPositionRole" class="field"><option value="">Choose next position...</option>${rs.map(r=>`<option value="${r.id}" ${r.id===c.desired_role_id?'selected':''}>${esc(r.title)}</option>`).join('')}</select></div><div><label>Long-term position desired <strong>REQUIRED</strong></label><select id="finalPositionRole" class="field"><option value="">Choose long-term position...</option>${rs.map(r=>`<option value="${r.id}" ${r.id===c.final_desired_role_id?'selected':''}>${esc(r.title)}</option>`).join('')}</select></div></div><label>Manager readiness for next position <strong>REQUIRED</strong></label><select id="careerPromotionReadiness" class="field">${opts(READINESS,c.promotion_readiness,'Choose readiness...')}</select>`;
      const specialist=panel.querySelector('#specialistFields');
      if(specialist)panel.insertBefore(block,specialist);else panel.querySelector('#nextYearGoal')?.closest('label')?.before(block)||panel.appendChild(block);
      const saveCareer=()=>sb.rpc('save_review_career_path',{p_review_id:reviewId,p_career_direction:'ADVANCEMENT',p_career_direction_reason:panel.querySelector('#careerDirectionReason')?.value||null,p_desired_role_id:block.querySelector('#nextPositionRole')?.value||null,p_final_desired_role_id:block.querySelector('#finalPositionRole')?.value||null});
      block.querySelector('#nextPositionRole')?.addEventListener('change',saveCareer);
      block.querySelector('#finalPositionRole')?.addEventListener('change',saveCareer);
      block.querySelector('#careerPromotionReadiness')?.addEventListener('change',e=>sb.rpc('save_review_promotion_readiness',{p_review_id:reviewId,p_promotion_readiness:e.target.value}));
    }finally{busy=false}
  }
  function audit(){if(queued)return;queued=true;queueMicrotask(async()=>{queued=false;await repair().catch(e=>console.error('CTOD career structure guard',e))})}
  new MutationObserver(audit).observe(root,{childList:true,subtree:true});
  root.addEventListener('change',e=>{if(e.target?.id==='careerDirection')setTimeout(audit,0)});
  document.addEventListener('click',e=>{if(e.target?.closest('.review,#tabReviews'))setTimeout(audit,80)});
  setTimeout(audit,250);
}
