// CTOD print owner: one printable summary document, any number of full-size Letter portrait pages.
function isReportPrintButton(el){const btn=el?.closest?.('button,a');if(!btn)return null;const text=(btn.textContent||'').trim().toLowerCase();if(!btn.closest('#printPage.ctod-report-system'))return null;if(btn.id==='printReviewReport'||text.includes('print portrait report')||text==='print'||text.includes('print / save pdf'))return btn;return null}
function buildPrintDocument(){
  const pages=[...document.querySelectorAll('#printPage.ctod-report-system .ctod-report-page')];
  if(!pages.length)throw new Error('No report pages are available. Generate the review summary first.');
  const reportStyle=document.getElementById('ctodReportSystemStyle')?.textContent||'';
  const pageHtml=pages.map(p=>p.outerHTML).join('');
  const w=window.open('','_blank');
  if(!w)throw new Error('Please allow pop-ups for CTOD and try Print Portrait Report again.');
  w.document.open();
  w.document.write(`<!doctype html><html><head><meta charset="utf-8"><base href="${location.origin}/"><title>CTOD Employee Review Summary</title><style>${reportStyle}</style><style>
*{box-sizing:border-box!important}html,body{margin:0!important;padding:0!important;background:#fff!important;width:8.5in!important}body{display:block!important;overflow:visible!important}#printPage.ctod-report-system{display:block!important;width:8.5in!important;margin:0!important;padding:0!important;background:#fff!important;color:#171717!important}.ctod-report-page{display:block!important;position:relative!important;width:8.5in!important;height:11in!important;min-height:11in!important;max-height:11in!important;margin:0!important;padding:.30in .38in .36in!important;border:0!important;box-shadow:none!important;background:#fff!important;overflow:hidden!important;break-after:page!important;page-break-after:always!important;-webkit-print-color-adjust:exact!important;print-color-adjust:exact!important}.ctod-report-page:last-child{break-after:auto!important;page-break-after:auto!important}.ctod-report-actions{display:none!important}@page{size:8.5in 11in portrait;margin:0!important}@media print{html,body,#printPage.ctod-report-system{width:8.5in!important;margin:0!important;padding:0!important}.ctod-report-page{width:8.5in!important;height:11in!important;min-height:11in!important;max-height:11in!important;margin:0!important;transform:none!important;zoom:1!important}}
</style></head><body><main id="printPage" class="ctod-report-system">${pageHtml}</main></body></html>`);
  w.document.close();
  const start=async()=>{try{if(w.document.fonts?.ready)await w.document.fonts.ready;const imgs=[...w.document.images];await Promise.all(imgs.map(img=>img.complete?Promise.resolve():new Promise(r=>{img.onload=r;img.onerror=r})));setTimeout(()=>{w.focus();w.print()},250)}catch{setTimeout(()=>{w.focus();w.print()},250)}};
  start();
}
if(!window.__ctodUnifiedPortraitPrintV1){window.__ctodUnifiedPortraitPrintV1=true;document.addEventListener('click',e=>{const btn=isReportPrintButton(e.target);if(!btn)return;e.preventDefault();e.stopPropagation();e.stopImmediatePropagation();const old=btn.textContent;btn.disabled=true;btn.textContent='Preparing Full Report...';try{buildPrintDocument()}catch(err){alert(`Print report could not be prepared: ${err.message||err}`)}finally{setTimeout(()=>{btn.disabled=false;btn.textContent=old},500)}},true)}
