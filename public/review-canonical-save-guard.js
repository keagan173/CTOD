const sb=window.ctodSupabase;
const root=document.querySelector('#reviewDetail');
if(!sb||!root){}else{
  async function persistCanonical(){
    const panel=root.querySelector('#ctodUnifiedCareerVoice');
    const id=panel?.dataset?.reviewId;
    if(!panel||!id)return {ok:true};
    const v=s=>root.querySelector(s)?.value||'';
    const direction=v('#careerDirection');
    const reason=v('#careerDirectionReason');
    const desired=direction==='ADVANCEMENT'?(v('#nextPositionRole')||null):null;
    const finalDesired=direction==='ADVANCEMENT'?(v('#finalPositionRole')||null):null;
    const readiness=v('#careerPromotionReadiness');
    const specialist=v('#specialistGrowthPath');
    const nextYear=v('#nextYearGoal');
    const safety=v('#voiceSafety');
    const career=v('#voiceCareer');
    const work=v('#voiceWork');
    const relocate=v('#ctodRelocationComp #voiceRelocate');
    const calls=[];
    calls.push(sb.rpc('save_review_career_path',{p_review_id:id,p_career_direction:direction||null,p_career_direction_reason:reason||null,p_desired_role_id:desired,p_final_desired_role_id:finalDesired}));
    if(readiness)calls.push(sb.rpc('save_review_promotion_readiness',{p_review_id:id,p_promotion_readiness:readiness}));
    if(specialist)calls.push(sb.rpc('save_review_specialist_growth',{p_review_id:id,p_specialist_growth_path:specialist}));
    if(nextYear)calls.push(sb.rpc('save_review_career_prompts',{p_review_id:id,p_next_year_goal:nextYear,p_five_year_position:null}));
    if(safety&&career&&work&&relocate)calls.push(sb.rpc('save_review_employee_voice',{p_review_id:id,p_safety_priority_response:safety,p_career_feeling_response:career,p_work_preference_response:work,p_relocation_openness_response:relocate}));
    const results=await Promise.all(calls);
    const failed=results.find(x=>x?.error);
    return failed?{ok:false,error:failed.error.message}:{ok:true};
  }
  function wrapButton(btn){
    if(!btn||btn.dataset.ctodCanonicalGuard==='1'||typeof btn.onclick!=='function')return;
    const original=btn.onclick;
    btn.dataset.ctodCanonicalGuard='1';
    btn.onclick=async function(ev){
      const msg=root.querySelector('#reviewSaveMsg');
      if(msg)msg.textContent='Saving career and Employee Voice...';
      this.disabled=true;
      try{
        const r=await persistCanonical();
        if(!r.ok){if(msg)msg.textContent='Career/Employee Voice save failed: '+r.error;return}
        return await original.call(this,ev);
      }finally{this.disabled=false}
    };
  }
  function install(){wrapButton(root.querySelector('#saveReviewDraft'));wrapButton(root.querySelector('#finalizeCurrentReview'))}
  new MutationObserver(()=>queueMicrotask(install)).observe(root,{childList:true,subtree:true});
  install();
}
