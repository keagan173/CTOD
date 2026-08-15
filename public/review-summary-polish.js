const POLISH_VERSION='20260815-polish2';

function addStyle(){
  if(document.getElementById('ctodSummaryPolishStyles')) return;
  const s=document.createElement('style');
  s.id='ctodSummaryPolishStyles';
  s.textContent=`
  /* PAGE 1: full-width resume rows so questions, reasons and notes never clip. */
  #printPage.review-summary-v6 .p:first-child .summary-grid{display:block!important}
  #printPage.review-summary-v6 .p:first-child .summary-grid .sec{width:100%!important;max-width:100%!important;margin:10px 0!important}
  #printPage.review-summary-v6 .ctod-strength-row{display:block!important;position:relative!important;width:100%!important;max-width:100%!important;padding:10px 0 11px!important;margin:0!important;border-bottom:1px solid #e7eaee!important;break-inside:avoid!important;overflow:visible!important;min-height:0!important;clear:both!important}
  #printPage.review-summary-v6 .ctod-strength-question{display:block!important;position:relative!important;width:100%!important;max-width:100%!important;margin:0 0 6px!important;padding:0!important;font-size:9px!important;line-height:1.34!important;font-weight:800!important;color:#171717!important;white-space:normal!important;overflow-wrap:anywhere!important}
  #printPage.review-summary-v6 .ctod-strength-answer{display:flex!important;flex-direction:column!important;align-items:flex-start!important;gap:5px!important;width:100%!important;max-width:100%!important;margin:0!important;padding:0!important;position:relative!important;min-height:0!important}
  #printPage.review-summary-v6 .ctod-strength-answer .pill{position:relative!important;display:inline-block!important;flex:none!important;margin:0!important;align-self:flex-start!important;white-space:nowrap!important;line-height:1.25!important;z-index:auto!important}
  #printPage.review-summary-v6 .ctod-strength-reason{display:block!important;position:relative!important;width:100%!important;max-width:100%!important;margin:0!important;padding:0!important;color:#4f5660!important;line-height:1.38!important;white-space:normal!important;overflow-wrap:anywhere!important;word-break:normal!important}
  #printPage.review-summary-v6 .ctod-strength-reason:not(:empty)::before{content:'Reason: ';font-weight:800;color:#333}
  #printPage.review-summary-v6 .ctod-strength-note{display:block!important;position:relative!important;width:100%!important;max-width:100%!important;margin:5px 0 0!important;padding:0!important;color:#5d646d!important;line-height:1.38!important;white-space:normal!important;overflow-wrap:anywhere!important}
  #printPage.review-summary-v6 .ctod-strength-note::before{content:'Manager note: ';font-weight:800;color:#333}

  /* PAGE 2: values stay inside the page and wrap instead of clipping. */
  #printPage.review-summary-v6 .p:nth-child(2){padding-bottom:150px!important}
  #printPage.review-summary-v6 .p:nth-child(2) .summary-grid{grid-template-columns:minmax(0,1fr) minmax(0,1fr)!important;gap:10px!important}
  #printPage.review-summary-v6 .fieldbox{display:grid!important;grid-template-columns:minmax(105px,38%) minmax(0,1fr)!important;column-gap:8px!important;align-items:start!important;min-width:0!important;max-width:100%!important;overflow:visible!important}
  #printPage.review-summary-v6 .fieldbox .label{display:block!important;margin:0!important;padding:1px 0!important;color:#765b1e!important;min-width:0!important}
  #printPage.review-summary-v6 .fieldbox b{display:block!important;margin:0!important;padding:0!important;color:#171717!important;line-height:1.28!important;white-space:normal!important;overflow-wrap:anywhere!important;word-break:normal!important;min-width:0!important;max-width:100%!important}
  #printPage.review-summary-v6 .voice{grid-template-columns:minmax(0,1fr) minmax(0,1fr)!important}
  #printPage.review-summary-v6 .career-grid{grid-template-columns:minmax(0,1fr) minmax(0,1fr)!important}
  #printPage.review-summary-v6 .compbox{max-width:100%!important;overflow-wrap:anywhere!important;white-space:normal!important}

  /* Always reserve and show acknowledgment/signatures on page 2. */
  #printPage.review-summary-v6 .p:nth-child(2) .sec.ctod-ack-section{position:absolute!important;left:.38in!important;right:.38in!important;bottom:68px!important;margin:0!important;background:#fff!important}
  #printPage.review-summary-v6 .p:nth-child(2) .sign{position:absolute!important;left:.38in!important;right:.38in!important;bottom:32px!important;display:grid!important;grid-template-columns:1fr 1fr!important;gap:28px!important;margin:0!important}
  #printPage.review-summary-v6 .p:nth-child(2) .sig{display:block!important;border-top:1.5px solid #222!important;padding-top:5px!important;font-size:8.5px!important;color:#222!important;min-height:20px!important}

  #printPage.review-summary-v6 .stat{display:grid!important;grid-template-columns:minmax(70px,42%) minmax(0,1fr)!important;column-gap:6px!important;align-items:start!important}
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

function markAcknowledgment(page2){
  if(!page2) return;
  const ack=[...page2.querySelectorAll('.sec')].find(sec=>/Acknowledgment\s*&\s*Agreement/i.test(sec.querySelector('h2')?.textContent||''));
  if(ack) ack.classList.add('ctod-ack-section');
}

function polish(){
  const host=document.querySelector('#printPage.review-summary-v6');
  if(!host || !host.querySelector('.p')) return;
  addStyle();

  const page1=host.querySelector('.p:first-child');
  if(page1){
    page1.querySelectorAll('.summary-grid .sec .item').forEach(rebuildStrengthItem);
  }

  const page2=host.querySelector('.p:nth-child(2)');
  markAcknowledgment(page2);

  host.querySelectorAll('.fieldbox .label').forEach(colonize);
  host.querySelectorAll('.stat small').forEach(colonize);
  host.dataset.summaryPolish=POLISH_VERSION;
}

new MutationObserver(()=>polish()).observe(document.body,{subtree:true,childList:true});
document.addEventListener('click',()=>setTimeout(polish,0),true);
polish();
