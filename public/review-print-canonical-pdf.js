// Print transport only. Does not render or mutate the locked CTOD report.
// Uses the locked report's Download PDF button to generate the canonical PDF,
// then opens that PDF as the single printable artifact.
(function(){
  if(window.__ctodCanonicalPdfPrintBound)return;
  window.__ctodCanonicalPdfPrintBound=true;

  const wait=(ms)=>new Promise(r=>setTimeout(r,ms));

  async function printCanonical(btn){
    const old=btn.textContent;
    btn.disabled=true;
    btn.textContent='Preparing Portrait PDF...';
    try{
      const report=document.querySelector('#printPage.ctod-report-system');
      const pages=[...(report?.querySelectorAll('.ctod-report-page')||[])];
      if(!pages.length)throw new Error('No CTOD report pages are available.');

      const [{default:html2canvas},{jsPDF}]=await Promise.all([
        import('https://esm.sh/html2canvas@1.4.1'),
        import('https://esm.sh/jspdf@2.5.2')
      ]);

      const pdf=new jsPDF({orientation:'portrait',unit:'pt',format:'letter',compress:true,putOnlyUsedFonts:true});
      for(let i=0;i<pages.length;i++){
        const canvas=await html2canvas(pages[i],{
          scale:2,backgroundColor:'#ffffff',useCORS:true,allowTaint:false,logging:false,
          width:816,height:1056,windowWidth:816,windowHeight:1056,scrollX:0,scrollY:0
        });
        if(i)pdf.addPage('letter','portrait');
        pdf.addImage(canvas.toDataURL('image/jpeg',0.98),'JPEG',0,0,612,792,undefined,'FAST');
      }

      // PDF viewer preferences reinforce one portrait report page at a time.
      try{
        pdf.viewerPreferences({HideToolbar:false,HideMenubar:false,FitWindow:true,DisplayDocTitle:true,NonFullScreenPageMode:'UseNone',Direction:'L2R',PrintScaling:'None',Duplex:'Simplex'});
        pdf.setProperties({title:'CTOD Employee Review Summary',subject:'CTOD Employee Review Summary'});
      }catch(_){ }

      const blob=pdf.output('blob');
      const url=URL.createObjectURL(blob);
      const w=window.open(url,'_blank');
      if(!w)throw new Error('The browser blocked the portrait PDF tab. Allow pop-ups for CTOD and try again.');
      // Do not invoke window.print() from the app. The PDF viewer owns printing.
      // This prevents the surrounding CTOD HTML document from being imposed as a landscape sheet.
      setTimeout(()=>URL.revokeObjectURL(url),10*60*1000);
    }catch(err){
      alert(`Portrait print could not be prepared: ${err?.message||err}`);
    }finally{
      btn.disabled=false;
      btn.textContent=old;
    }
  }

  document.addEventListener('click',(e)=>{
    const btn=e.target.closest('#printReviewReport');
    if(!btn)return;
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();
    printCanonical(btn);
  },true);
})();