const sb=window.ctodSupabase;
const root=document.querySelector('#reviewDetail');
if(sb&&root){
  async function persistCanonical(){
    const panel=root.querySelector('#ctodUnifiedCareerVoiceV4');
    const id=panel?.dataset?.reviewId;
    if(!panel||!id)return {ok:true};
    const v=s=>root.querySelector(s)?.value||'';
    const direction=v('#careerDirection');
    const reason=v('#careerDirectionReason');
    const calls=[];
    calls.push(sb.rpc('save_review_career_path',{p_review_id:id,p_career_direction:direction||null,p_career_direction_reason:reason||null,p_desired_role_id:direction==='ADVANCEMENT'?(v('#nextPositionRole')||null):null,p_final_desired_role_id:direction==='ADVANCEMENT'?(v('#finalPositionRole')||null):null}));
    if(v('#careerPromotionReadiness'))calls.push(sb.rpc('save_review_promotion_readiness',{p_review_id:id,p_promotion_readiness:v('#careerPromotionReadiness')}));
    if(v('#specialistGrowthPath'))calls.push(sb.rpc('save_review_specialist_growth',{p_review_id:id,p_specialist_growth_path:v('#specialistGrowthPath')}));
    if(v('#nextYearGoal'))calls.push(sb.rpc('save_review_career_prompts',{p_review_id:id,p_next_year_goal:v('#nextYearGoal'),p_five_year_position:null}));
    const settled=await Promise.all(calls);
    const failed=settled.find(x=>x?.error);
    if(failed)return {ok:false,error:failed.error.message};
    if(window.ctodQuestionEngine){
      for(const el of root.querySelectorAll('.ctod-v4-voice,.ctod-v4-mobility')){
        if(!el.value)continue;
        try{await window.ctodQuestionEngine.save(id,el.dataset.questionId,el.value)}catch(e){return {ok:false,error:e.message||String(e)}}
      }
    }
    return {ok:true};
  }
  function wrapButton(btn){
    if(!btn||btn.dataset.ctodCanonicalGuardV2==='1'||typeof btn.onclick!=='function')return;
    const original=btn.onclick;
    btn.dataset.ctodCanonicalGuardV2='1';
    btn.onclick=async function(ev){
      const msg=root.querySelector('#reviewSaveMsg');
      if(msg)msg.textContent='Saving career and intelligence fields...';
      this.disabled=true;
      try{
        const r=await persistCanonical();
        if(!r.ok){if(msg)msg.textContent='Career/intelligence save failed: '+r.error;return}
        return await original.call(this,ev);
      }finally{this.disabled=false}
    };
  }
  function install(){wrapButton(root.querySelector('#saveReviewDraft'));wrapButton(root.querySelector('#finalizeCurrentReview'))}
  let queued=false;
  const schedule=()=>{if(queued)return;queued=true;setTimeout(()=>{queued=false;install()},80)};
  document.addEventListener('click',e=>{if(e.target.closest('.review,#tabReviews'))schedule()},true);
  document.addEventListener('ctod:workspace-ready',schedule);
  [100,300,700,1300].forEach(setTimeout.bind(null,schedule));
}