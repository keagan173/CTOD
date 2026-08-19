const sb=window.ctodSupabase;
const root=document.querySelector('#reviewDetail');
let installedFor=null,busy=false,timer=0;

async function currentReviewId(){
  const panel=root?.querySelector('#ctodUnifiedCareerVoice');
  if(panel?.dataset?.reviewId)return panel.dataset.reviewId;
  if(window.ctodCurrentReviewId)return window.ctodCurrentReviewId;
  return null;
}

function fieldFor(source){
  if(source==='safety_priority_response')return root?.querySelector('#ctodUnifiedCareerVoice #voiceSafety');
  if(source==='career_feeling_response')return root?.querySelector('#ctodUnifiedCareerVoice #voiceCareer');
  if(source==='work_preference_response')return root?.querySelector('#ctodUnifiedCareerVoice #voiceWork');
  if(source==='relocation_openness_response')return root?.querySelector('#ctodRelocationComp #voiceRelocate');
  return null;
}

function replaceWithOwnedControl(el){
  if(!el||el.dataset.ctodVoiceCompat==='1')return el;
  const clone=el.cloneNode(true);
  clone.dataset.ctodVoiceCompat='1';
  el.replaceWith(clone);
  return clone;
}

async function install(){
  if(busy||!root||root.classList.contains('hide'))return;
  const id=await currentReviewId();
  if(!id)return;
  const panel=root.querySelector('#ctodUnifiedCareerVoice');
  const relocation=root.querySelector('#ctodRelocationComp #voiceRelocate');
  if(!panel||!relocation)return;
  if(installedFor===id&&root.querySelector('[data-ctod-voice-compat="1"]'))return;
  busy=true;
  try{
    const map=await sb.rpc('get_001_employee_voice_question_map',{p_review_id:id});
    if(map.error)throw map.error;
    const msg=panel.querySelector('#unifiedFieldMsg');
    for(const row of (map.data||[])){
      let el=fieldFor(row.source_field);
      if(!el)continue;
      el=replaceWithOwnedControl(el);
      if(row.current_response&&el.value!==row.current_response)el.value=row.current_response;
      el.addEventListener('change',async()=>{
        const value=el.value||'';
        if(!value)return;
        el.disabled=true;
        if(msg)msg.textContent='Saving Employee Voice...';
        try{
          const save=await sb.rpc('save_001_employee_voice_response',{p_review_id:id,p_question_id:row.question_id,p_response_text:value});
          if(save.error)throw save.error;
          if(msg)msg.textContent='Employee Voice saved.';
          document.dispatchEvent(new CustomEvent('ctod:employee-voice-saved',{detail:{reviewId:id,sourceField:row.source_field}}));
        }catch(e){
          if(msg)msg.textContent='Employee Voice save failed: '+(e.message||e);
        }finally{el.disabled=false}
      });
    }
    installedFor=id;
  }catch(e){console.error('CTOD 001 Employee Voice compatibility',e)}
  finally{busy=false}
}

function schedule(ms=100){clearTimeout(timer);timer=setTimeout(()=>install(),ms)}
if(root){
  new MutationObserver(()=>schedule(80)).observe(root,{childList:true,subtree:true});
  document.addEventListener('click',e=>{if(e.target?.closest('.review,#tabReviews'))schedule(120)},true);
  document.addEventListener('ctod:workspace-ready',()=>schedule(200));
  schedule(300);
}
