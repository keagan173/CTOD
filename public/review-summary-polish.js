const POLISH_VERSION='20260815-polish1';

function addStyle(){
  if(document.getElementById('ctodSummaryPolishStyles')) return;
  const s=document.createElement('style');
  s.id='ctodSummaryPolishStyles';
  s.textContent=`
  #printPage.review-summary-v6 .ctod-strength-row{display:block!important;position:relative!important;padding:10px 0!important;border-bottom:1px solid #e7eaee!important;break-inside:avoid!important;overflow:visible!important;min-height:0!important}
  #printPage.review-summary-v6 .ctod-strength-question{display:block!important;position:relative!important;margin:0 0 7px!important;padding:0!important;font-size:9px!important;line-height:1.32!important;font-weight:800!important;color:#171717!important;white-space:normal!important;overflow-wrap:anywhere!important}
  #printPage.review-summary-v6 .ctod-strength-answer{display:grid!important;grid-template-columns:max-content minmax(0,1fr)!important;align-items:start!important;column-gap:8px!important;row-gap:0!important;margin:0!important;padding:0!important;position:relative!important;min-height:22px!important}
  #printPage.review-summary-v6 .ctod-strength-answer .pill{position:relative!important;display:inline-block!important;margin:0!important;align-self:start!important;white-space:nowrap!important;line-height:1.25!important;z-index:auto!important}
  #printPage.review-summary-v6 .ctod-strength-reason{display:block!important;position:relative!important;margin:0!important;padding:2px 0 0!important;color:#4f5660!important;line-height:1.35!important;white-space:normal!important;overflow-wrap:anywhere!important;min-width:0!important}
  #printPage.review-summary-v6 .ctod-strength-note{display:block!important;position:relative!important;margin:6px 0 0!important;padding:0!important;color:#5d646d!important;line-height:1.35!important;white-space:normal!important;overflow-wrap:anywhere!important}
  #printPage.review-summary-v6 .fieldbox{display:grid!important;grid-template-columns:minmax(90px,42%) minmax(0,1fr)!important;column-gap:8px!important;align-items:start!important}
  #printPage.review-summary-v6 .fieldbox .label{display:block!important;margin:0!important;padding:1px 0!important;color:#765b1e!important}
  #printPage.review-summary-v6 .fieldbox b{display:block!important;margin:0!important;padding:0!important;color:#171717!important;line-height:1.28!important;overflow-wrap:anywhere!important}
  #printPage.review-summary-v6 .stat{display:grid!important;grid-template-columns:minmax(62px,42%) minmax(0,1fr)!important;column-gap:6px!important;align-items:start!important}
  #printPage.review-summary-v6 .stat small{display:block!important;margin:0!important;padding:1px 0!important}
  #printPage.review-summary-v6 .stat b{display:block!important;margin:0!important;padding:0!important;color:#171717!important;line-height:1.25!important;overflow-wrap:anywhere!important}
  `;
  document.head.appendChild(s);
}

function colonize(el){
  if(!el || el.dataset.ctodColonized==='1') return;
  const t=(el.textContent||'').trim();
  if(t && !/[?:：]$/.test(t)) el.textContent=t+':';
  el.dataset.ctodColonized='1';
}

function rebuildStrengthItem(item){
  if(!item || item.dataset.ctodPolished==='1' || item.classList.contains('empty')) return;
  const q=item.querySelector('.question');
  const pill=item.querySelector('.pill');
  const reason=item.querySelector('.reason');
  const note=item.querySelector('.note');
  if(!q || !pill) return;

  const question=document.createElement('div');
  question.className='ctod-strength-question';
  question.textContent=(q.textContent||'').trim();

  const answer=document.createElement('div');
  answer.className='ctod-strength-answer';
  const badge=pill.cloneNode(true);
  const why=document.createElement('div');
  why.className='ctod-strength-reason';
  why.textContent=(reason?.textContent||'').trim();
  answer.append(badge,why);

  item.innerHTML='';
  item.className='item ctod-strength-row';
  item.append(question,answer);
  if(note && (note.textContent||'').trim()){
    const n=document.createElement('div');
    n.className='ctod-strength-note';
    n.textContent=(note.textContent||'').trim();
    item.appendChild(n);
  }
  item.dataset.ctodPolished='1';
}

function polish(){
  const host=document.querySelector('#printPage.review-summary-v6');
  if(!host || !host.querySelector('.p')) return;
  addStyle();

  const page1=host.querySelector('.p:first-child');
  if(page1){
    page1.querySelectorAll('.summary-grid .sec .item').forEach(rebuildStrengthItem);
  }

  host.querySelectorAll('.fieldbox .label').forEach(colonize);
  host.querySelectorAll('.stat small').forEach(colonize);
  host.dataset.summaryPolish=POLISH_VERSION;
}

new MutationObserver(()=>polish()).observe(document.body,{subtree:true,childList:true});
document.addEventListener('click',()=>setTimeout(polish,0),true);
polish();
