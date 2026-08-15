const POLISH_VERSION='20260815-polish3';

function addStyle(){
  if(document.getElementById('ctodSummaryPolishStyles')) return;
  const s=document.createElement('style');
  s.id='ctodSummaryPolishStyles';
  s.textContent=`
  #printPage.review-summary-v6 .ctod-strength-row{display:block!important;position:relative!important;width:100%!important;max-width:100%!important;padding:10px 0 11px!important;margin:0!important;border-bottom:1px solid #e7eaee!important;break-inside:avoid!important;overflow:visible!important;min-height:0!important;clear:both!important}
  #printPage.review-summary-v6 .ctod-strength-question{display:block!important;width:100%!important;margin:0 0 6px!important;padding:0!important;font-size:9px!important;line-height:1.34!important;font-weight:800!important;color:#171717!important;white-space:normal!important;overflow-wrap:anywhere!important}
  #printPage.review-summary-v6 .ctod-strength-answer{display:flex!important;flex-direction:column!important;align-items:flex-start!important;gap:5px!important;width:100%!important;margin:0!important;padding:0!important;min-height:0!important}
  #printPage.review-summary-v6 .ctod-strength-answer .pill{display:inline-block!important;flex:none!important;margin:0!important;align-self:flex-start!important;white-space:nowrap!important;line-height:1.25!important}
  #printPage.review-summary-v6 .ctod-strength-reason{display:block!important;width:100%!important;margin:0!important;padding:0!important;color:#4f5660!important;line-height:1.38!important;white-space:normal!important;overflow-wrap:anywhere!important}
  #printPage.review-summary-v6 .ctod-strength-reason:not(:empty)::before{content:'Reason: ';font-weight:800;color:#333}
  #printPage.review-summary-v6 .ctod-strength-note{display:block!important;width:100%!important;margin:5px 0 0!important;padding:0!important;color:#5d646d!important;line-height:1.38!important;white-space:normal!important;overflow-wrap:anywhere!important}
  #printPage.review-summary-v6 .ctod-strength-note::before{content:'Manager note: ';font-weight:800;color:#333}
  #printPage.review-summary-v6 .fieldbox{display:grid!important;grid-template-columns:minmax(105px,38%) minmax(0,1fr)!important;column-gap:8px!important;align-items:start!important;min-width:0!important;max-width:100%!important;overflow:visible!important}
  #printPage.review-summary-v6 .fieldbox b{white-space:normal!important;overflow-wrap:anywhere!important;min-width:0!important;max-width:100%!important}
  #printPage.review-summary-v6 .voice,#printPage.review-summary-v6 .career-grid{grid-template-columns:minmax(0,1fr) minmax(0,1fr)!important}
  #printPage.review-summary-v6 .compbox{max-width:100%!important;overflow-wrap:anywhere!important;white-space:normal!important}
  #printPage.review-summary-v6 .stat{display:grid!important;grid-template-columns:minmax(70px,42%) minmax(0,1fr)!important;column-gap:6px!important;align-items:start!important}
  `;
  document.head.appendChild(s);
}
function colonize(el){if(!el||el.dataset.ctodColonized==='1')return;const t=(el.textContent||'').trim();if(t&&!/[?:：]$/.test(t))el.textContent=t+':';el.dataset.ctodColonized='1'}
function rebuildStrengthItem(item){
  if(!item||item.dataset.ctodPolished==='1'||item.classList.contains('empty'))return;
  const q=item.querySelector('.question'),pill=item.querySelector('.pill'),reason=item.querySelector('.reason'),note=item.querySelector('.note');if(!q||!pill)return;
  const question=document.createElement('div');question.className='ctod-strength-question';question.textContent=(q.textContent||'').trim();
  const answer=document.createElement('div');answer.className='ctod-strength-answer';const badge=pill.cloneNode(true);const why=document.createElement('div');why.className='ctod-strength-reason';why.textContent=(reason?.textContent||'').trim();answer.append(badge,why);
  item.innerHTML='';item.className='item ctod-strength-row';item.append(question,answer);
  if(note&&(note.textContent||'').trim()){const n=document.createElement('div');n.className='ctod-strength-note';n.textContent=(note.textContent||'').trim();item.appendChild(n)}
  item.dataset.ctodPolished='1';
}
function polish(){
  const host=document.querySelector('#printPage.review-summary-v6');if(!host||!host.querySelector('.p')||host.dataset.ctodAdaptive==='1')return;addStyle();
  const page1=host.querySelector('.p:first-child');if(page1)page1.querySelectorAll('.summary-grid .sec .item').forEach(rebuildStrengthItem);
  host.querySelectorAll('.fieldbox .label').forEach(colonize);host.querySelectorAll('.stat small').forEach(colonize);host.dataset.summaryPolish=POLISH_VERSION;
}
new MutationObserver(()=>polish()).observe(document.body,{subtree:true,childList:true});document.addEventListener('click',()=>setTimeout(polish,0),true);polish();
