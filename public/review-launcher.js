import { ctodSupabase as rl } from './ctod-config.js';
const $=s=>document.querySelector(s);const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
let rows=[],installing=false,refreshing=false,launching=false;
async function roster(){if(window.ctodWorkspaceReady)await window.ctodWorkspaceReady;const session=await rl.auth.getSession();if(session.error)throw session.error;if(!session.data.session)throw new Error('CTOD session is not ready.');const r=await rl.rpc('manager_workspace_employees');if(r.error)throw r.error;rows=r.data||[];return rows}
function options(selected=''){return '<option value="">Select employee...</option>'+rows.map(e=>`<option value="${e.employee_id}" ${selected===e.employee_id?'selected':''}>${esc((e.first_name||'')+' '+(e.last_name||''))} · #${esc(e.employee_code||'------')} · ${esc(e.role_title||'')} · Loc ${esc(e.location_code||'')}</option>`).join('')}
async function launch(employeeId,msg){
  if(!employeeId){msg.textContent='Choose an employee.';return}
  if(launching)return;
  const button=msg?.parentElement?.querySelector('button');
  launching=true;if(button)button.disabled=true;
  try{
    msg.textContent='Preparing review...';
    const p=await rl.rpc('manager_prepare_review',{p_employee_id:employeeId});
    if(p.error)throw p.error;
    const reviewId=p.data;
    const s=await rl.rpc('start_review',{p_review_id:reviewId});
    if(s.error)throw s.error;
    msg.textContent='Opening review workspace...';
    if(typeof window.ctodOpenReview==='function'){
      await window.ctodOpenReview(reviewId);
      msg.textContent='Review workspace opened.';
    }else{
      sessionStorage.setItem('ctodPendingReviewId',reviewId);
      location.reload();
    }
  }catch(error){
    msg.textContent=error?.message||'Review could not be opened.';
  }finally{
    launching=false;if(button)button.disabled=false;
  }
}
function cleanupDuplicates(){const cards=[...document.querySelectorAll('#reviewsView #ctodReviewLauncher,.ctod-review-launcher')];cards.slice(1).forEach(x=>x.remove())}
async function refreshLauncher(){const select=$('#reviewsView #reviewLaunchEmployee');if(!select||refreshing)return;refreshing=true;const selected=select.value,msg=$('#reviewLaunchMsg'),button=$('#reviewLaunchBtn');try{select.disabled=true;if(button)button.disabled=true;if(msg)msg.textContent='Loading employees...';await roster();select.innerHTML=options(selected);select.disabled=!rows.length;if(button)button.disabled=!rows.length;if(msg)msg.textContent=rows.length?'':'No active employees are available.'}catch(e){select.innerHTML='<option value="">Employee list unavailable</option>';select.disabled=true;if(button)button.disabled=true;if(msg)msg.textContent='Employee list could not be loaded. Refresh the page or sign in again.'}finally{refreshing=false}}
async function installReviewsLauncher(){const view=$('#reviewsView');if(!view)return;cleanupDuplicates();if(view.querySelector('#ctodReviewLauncher')){await refreshLauncher();return}if(installing)return;installing=true;try{const card=document.createElement('section');card.id='ctodReviewLauncher';card.className='card section ctod-review-launcher';card.innerHTML=`<div class="workspace-head"><div><h3>Start / Find Employee Review</h3><div class="sub">Choose any active employee, including newly added employees or employees whose review is not due yet.</div></div></div><div class="grid2" style="margin-top:12px"><div><label>Employee</label><select id="reviewLaunchEmployee" class="field" disabled><option value="">Loading employees...</option></select></div><div style="display:flex;align-items:end;gap:10px"><button id="reviewLaunchBtn" class="btn primary" disabled>Start / Open Review</button><span id="reviewLaunchMsg" class="sub">Loading employees...</span></div></div>`;const first=view.querySelector('.kpis');if(first)first.insertAdjacentElement('afterend',card);else view.prepend(card);card.querySelector('#reviewLaunchBtn').onclick=()=>launch(card.querySelector('#reviewLaunchEmployee').value,card.querySelector('#reviewLaunchMsg'));view.dataset.reviewLauncherInstalled='1';await refreshLauncher()}finally{installing=false;cleanupDuplicates()}}
async function enhanceSchedule(){const table=$('.schedule-table');if(!table)return;if(!rows.length){try{await roster()}catch{return}}const trs=[...table.querySelectorAll('tbody tr')];for(const [idx,tr] of trs.entries()){if(tr.querySelector('.schedStartNow'))continue;const e=rows[idx];if(!e)continue;const cell=tr.lastElementChild;if(!cell)continue;const b=document.createElement('button');b.className='btn secondary schedStartNow';b.style.marginTop='6px';b.textContent='Start Review Now';b.onclick=()=>launch(e.employee_id,cell.querySelector('.schedMsg')||document.createElement('span'));cell.appendChild(b)}}
async function run(){cleanupDuplicates();await installReviewsLauncher();await enhanceSchedule()}
run();setTimeout(run,500);setTimeout(run,1500);
$('#tabReviews')?.addEventListener('click',()=>setTimeout(installReviewsLauncher,0));
document.addEventListener('ctod:workspace-ready',()=>setTimeout(installReviewsLauncher,0));
const obs=new MutationObserver(()=>{if(document.querySelector('#reviewsView')&&!document.querySelector('#reviewsView #ctodReviewLauncher'))requestAnimationFrame(run);if(document.querySelector('.schedule-table'))requestAnimationFrame(enhanceSchedule)});obs.observe(document.documentElement,{childList:true,subtree:true});
