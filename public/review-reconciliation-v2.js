const sb=window.ctodSupabase;
const $=s=>document.querySelector(s);
function publicBase(){return location.origin}
async function wirePasswordRecovery(){
  const forgot=$('#forgotPassword');
  if(!forgot||!sb)return;
  forgot.onclick=async()=>{const email=$('#email').value.trim();if(!email){$('#authMsg').textContent='Enter your email first, then select Forgot password.';return}forgot.disabled=true;$('#authMsg').textContent='Sending secure reset link...';const {error}=await sb.auth.resetPasswordForEmail(email,{redirectTo:publicBase()+'/?reset=1'});$('#authMsg').textContent=error?error.message:'Password reset email sent. Check your inbox and junk folder.';forgot.disabled=false};
  const params=new URLSearchParams(location.search),isReset=params.get('reset')==='1';
  sb.auth.onAuthStateChange(async event=>{if(event==='PASSWORD_RECOVERY'||isReset){$('#auth').hidden=true;$('#app').hidden=true;$('#resetSetup').hidden=false}});
  const save=$('#saveResetPassword');if(save)save.onclick=async()=>{const p=$('#resetPassword').value,p2=$('#resetPassword2').value;if(p.length<8){$('#resetMsg').textContent='Password must be at least 8 characters.';return}if(p!==p2){$('#resetMsg').textContent='Passwords do not match.';return}save.disabled=true;const {error}=await sb.auth.updateUser({password:p});if(error){$('#resetMsg').textContent=error.message;save.disabled=false;return}$('#resetMsg').textContent='Password updated. Returning to CTOD...';history.replaceState({},'',location.pathname);setTimeout(()=>location.reload(),800)}}
function intro(name){if(name==='Organizational Competencies')return'Core behaviors expected across the organization.';if(name==='Current Role Performance')return'Performance expectations specific to the employee’s current job.';return''}
function reconcile(){const detail=$('#reviewDetail');if(!detail||detail.classList.contains('hide'))return;[...detail.querySelectorAll('div')].filter(x=>['Organizational Competencies','Current Role Performance'].includes(x.textContent.trim())&&x.children.length===0).forEach(h=>{if(h.nextElementSibling?.classList?.contains('ctod-section-intro'))return;const p=document.createElement('div');p.className='sub ctod-section-intro';p.textContent=intro(h.textContent.trim());h.after(p)});$('#fiveYearPosition')?.parentElement?.remove()}
function burst(){[80,180,400,800].forEach(ms=>setTimeout(()=>{try{reconcile()}catch(e){console.error('CTOD review reconciliation',e)}},ms))}
document.addEventListener('click',e=>{if(e.target?.closest('#tabReviews,.review-row,.review-card,.review'))burst()},true);
wirePasswordRecovery();burst();
