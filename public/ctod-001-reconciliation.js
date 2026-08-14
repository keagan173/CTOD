// CTOD 001 reconciliation overlay. Keeps the core multi-tenant engine unchanged.
const sb=window.ctodSupabase;
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
const fmt=d=>d?new Date(d+'T12:00:00').toLocaleDateString():'';
function publicBase(){return location.origin}
async function wirePasswordRecovery(){
 const forgot=$('#forgotPassword'); if(!forgot||!sb)return;
 forgot.onclick=async()=>{const email=$('#email').value.trim();if(!email){$('#authMsg').textContent='Enter your email first, then select Forgot password.';return}forgot.disabled=true;$('#authMsg').textContent='Sending secure reset link...';const {error}=await sb.auth.resetPasswordForEmail(email,{redirectTo:publicBase()+'/?reset=1'});$('#authMsg').textContent=error?error.message:'Password reset email sent. Check your inbox and junk folder.';forgot.disabled=false};
 const params=new URLSearchParams(location.search);const isReset=params.get('reset')==='1';
 sb.auth.onAuthStateChange(async(event)=>{if(event==='PASSWORD_RECOVERY'||isReset){$('#auth').hidden=true;$('#app').hidden=true;$('#resetSetup').hidden=false}});
 const save=$('#saveResetPassword');if(save)save.onclick=async()=>{const p=$('#resetPassword').value,p2=$('#resetPassword2').value;if(p.length<8){$('#resetMsg').textContent='Password must be at least 8 characters.';return}if(p!==p2){$('#resetMsg').textContent='Passwords do not match.';return}save.disabled=true;const {error}=await sb.auth.updateUser({password:p});if(error){$('#resetMsg').textContent=error.message;save.disabled=false;return}$('#resetMsg').textContent='Password updated. Returning to CTOD...';history.replaceState({},'',location.pathname);setTimeout(()=>location.reload(),800)};
}
function dueLabel(r){if(r.status==='finalized')return 'Finalized';const due=r.scheduled_review_date;if(due&&due<new Date().toISOString().slice(0,10))return 'Overdue';if(due&&due===new Date().toISOString().slice(0,10))return 'Due Today';if(r.status==='queued')return 'Due';if(r.status==='not_due')return 'Upcoming';return String(r.status||'').replaceAll('_',' ')}
function sectionIntro(name){if(name==='Organizational Competencies')return 'Core behaviors expected across Commercial Tire.';if(name==='Current Role Performance')return 'Performance expectations specific to the employee’s current job.';return ''}
function reconcileReview(){
 const detail=$('#reviewDetail');if(!detail||detail.classList.contains('hide'))return;
 detail.querySelectorAll(':scope > div').forEach(()=>{});
 const headings=[...detail.querySelectorAll('div')].filter(x=>['Organizational Competencies','Current Role Performance'].includes(x.textContent.trim())&&x.children.length===0);
 headings.forEach(h=>{if(h.nextElementSibling?.classList?.contains('ctod-section-intro'))return;const p=document.createElement('div');p.className='sub ctod-section-intro';p.textContent=sectionIntro(h.textContent.trim());h.after(p)});
 const devHeading=[...detail.querySelectorAll('div')].find(x=>x.textContent.trim()==='Development & Career'&&x.children.length===0);
 const devCard=devHeading?.nextElementSibling;
 if(devCard&&devCard.classList.contains('invite-card')&&!$('#nextYearGoal')){
   devHeading.textContent='Employee Development & Career';
   const c=window.ctodCurrentReviewForm?.career||{};
   const block=document.createElement('div');block.innerHTML='<div class="grid2"><div><label>What is the employee’s goal for the next year?</label><textarea id="nextYearGoal" class="field" rows="3" placeholder="Employee’s one-year development or performance goal...">'+esc(c.next_year_goal||'')+'</textarea></div><div><label>What position would the employee like to be in five years?</label><textarea id="fiveYearPosition" class="field" rows="3" placeholder="Employee’s five-year position or career direction...">'+esc(c.five_year_position||'')+'</textarea></div></div><div class="sub" style="margin-top:10px">Career interest belongs to the employee. Promotion readiness is the manager’s assessment.</div>';
   devCard.insertBefore(block,devCard.firstChild);
 }
}
async function saveCareerPrompts(){if(!sb||!window.ctodCurrentReviewId||!$('#nextYearGoal'))return;return sb.rpc('save_review_career_prompts',{p_review_id:window.ctodCurrentReviewId,p_next_year_goal:$('#nextYearGoal').value,p_five_year_position:$('#fiveYearPosition').value})}
const observer=new MutationObserver(()=>reconcileReview());
observer.observe(document.documentElement,{subtree:true,childList:true});
window.ctod001SaveCareerPrompts=saveCareerPrompts;
wirePasswordRecovery();
