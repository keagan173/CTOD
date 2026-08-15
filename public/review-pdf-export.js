const PDF_VERSION='20260815-pdf3';
let generating=false;

async function libs(){
  const [{default:html2canvas},{jsPDF}]=await Promise.all([
    import('https://esm.sh/html2canvas@1.4.1'),
    import('https://esm.sh/jspdf@2.5.2')
  ]);
  return {html2canvas,jsPDF};
}

function safeName(){
  const raw=(document.querySelector('#printPage .identity .name')?.textContent||'Employee').trim();
  return raw.replace(/[^a-z0-9 _-]/gi,'').replace(/\s+/g,'_')||'Employee';
}

async function rasterLogo(){
  try{
    const res=await fetch('/branding/ctod-logo-1-primary.svg',{cache:'force-cache'});
    if(!res.ok)return null;
    const svg=await res.text();
    const blob=new Blob([svg],{type:'image/svg+xml'});
    const url=URL.createObjectURL(blob);
    const img=new Image();
    await new Promise((resolve,reject)=>{img.onload=resolve;img.onerror=reject;img.src=url;});
    const canvas=document.createElement('canvas');
    canvas.width=290;canvas.height=96;
    const ctx=canvas.getContext('2d');
    ctx.clearRect(0,0,canvas.width,canvas.height);
    ctx.drawImage(img,0,0,canvas.width,canvas.height);
    URL.revokeObjectURL(url);
    return canvas.toDataURL('image/png');
  }catch{return null;}
}

function copyComputedTree(source,clone){
  const copy=(s,c)=>{
    const cs=getComputedStyle(s);
    for(const prop of cs){
      try{c.style.setProperty(prop,cs.getPropertyValue(prop),cs.getPropertyPriority(prop));}catch{}
    }
    const sa=[...s.children],ca=[...c.children];
    for(let i=0;i<Math.min(sa.length,ca.length);i++)copy(sa[i],ca[i]);
  };
  copy(source,clone);
}

function lockSummaryLayout(page){
  Object.assign(page.style,{
    width:'816px',height:'1056px',minWidth:'816px',maxWidth:'816px',
    minHeight:'1056px',maxHeight:'1056px',margin:'0',padding:'29px 36px',
    boxSizing:'border-box',overflow:'hidden',position:'relative',transform:'none',zoom:'1',
    background:'#ffffff',color:'#171717',pageBreakAfter:'auto',fontFamily:'Arial,Helvetica,sans-serif'
  });

  page.querySelectorAll('*').forEach(el=>{
    el.style.transform='none';
    el.style.zoom='1';
    el.style.textShadow='none';
    if(!el.closest('.brandhead')){
      const c=getComputedStyle(el).color;
      if(c==='rgba(0, 0, 0, 0)'||c==='transparent')el.style.color='#171717';
    }
  });

  const head=page.querySelector('.brandhead');
  if(head){
    Object.assign(head.style,{
      display:'grid',gridTemplateColumns:'150px 1fr',gap:'16px',alignItems:'center',
      height:'70px',minHeight:'70px',maxHeight:'70px',padding:'10px 12px',overflow:'hidden',
      background:'#111820',border:'1px solid #d7b85f',borderRadius:'12px',marginBottom:'10px'
    });
  }
  page.querySelectorAll('.brandcopy').forEach(x=>x.style.color='#ffffff');
  page.querySelectorAll('.doctype').forEach(x=>x.style.color='#e5c767');
  page.querySelectorAll('.company').forEach(x=>x.style.color='#ffffff');

  page.querySelectorAll('.item').forEach(item=>{
    Object.assign(item.style,{
      display:'block',position:'static',width:'100%',clear:'both',padding:'7px 0',
      overflow:'visible',breakInside:'avoid',color:'#171717',lineHeight:'1.32'
    });
  });
  page.querySelectorAll('.question').forEach(q=>{
    Object.assign(q.style,{
      display:'block',position:'static',width:'100%',maxWidth:'100%',float:'none',clear:'both',
      margin:'0 0 5px 0',padding:'0',fontWeight:'800',lineHeight:'1.28',whiteSpace:'normal',
      overflowWrap:'break-word',color:'#171717'
    });
  });
  page.querySelectorAll('.answerline').forEach(row=>{
    Object.assign(row.style,{
      display:'grid',gridTemplateColumns:'max-content minmax(0,1fr)',columnGap:'8px',rowGap:'0',
      alignItems:'start',position:'static',width:'100%',maxWidth:'100%',margin:'0',padding:'0',
      float:'none',clear:'both',overflow:'visible'
    });
  });
  page.querySelectorAll('.pill').forEach(p=>{
    Object.assign(p.style,{
      display:'inline-block',position:'static',float:'none',width:'max-content',maxWidth:'190px',
      margin:'0',whiteSpace:'nowrap',zIndex:'auto',lineHeight:'1.25'
    });
  });
  page.querySelectorAll('.reason').forEach(r=>{
    Object.assign(r.style,{
      display:'block',position:'static',float:'none',minWidth:'0',width:'auto',margin:'0',
      whiteSpace:'normal',overflowWrap:'break-word',wordBreak:'normal',lineHeight:'1.32',color:'#4f5660'
    });
  });
  page.querySelectorAll('.note').forEach(n=>{
    Object.assign(n.style,{
      display:'block',position:'static',float:'none',clear:'both',width:'100%',margin:'5px 0 0',
      whiteSpace:'normal',overflowWrap:'break-word',lineHeight:'1.32',color:'#5d646d'
    });
  });
  page.querySelectorAll('.identity,.stat,.fieldbox,.compbox,.ack').forEach(x=>{
    x.style.color='#171717';
  });
  page.querySelectorAll('.identity .sub,.identity .right').forEach(x=>x.style.color='#4f5660');
  page.querySelectorAll('.sec h2').forEach(x=>x.style.color='#6d500e');
  page.querySelectorAll('.label').forEach(x=>x.style.color='#765b1e');
  page.querySelectorAll('.foot').forEach(x=>x.style.color='#777777');
  page.querySelectorAll('.empty').forEach(x=>x.style.color='#747b84');
  page.querySelectorAll('.actions').forEach(x=>x.remove());
}

function exportFrame(source,logoData){
  const wrap=document.createElement('div');
  wrap.className='review-summary-v6 ctod-pdf-export-frame';
  Object.assign(wrap.style,{
    position:'fixed',left:'-20000px',top:'0',width:'816px',height:'1056px',
    margin:'0',padding:'0',background:'#fff',overflow:'hidden',zIndex:'-1',transform:'none',zoom:'1'
  });

  const page=source.cloneNode(true);
  copyComputedTree(source,page);
  page.className='p';
  lockSummaryLayout(page);

  const logo=page.querySelector('.brandhead img');
  if(logo){
    if(logoData)logo.src=logoData;
    Object.assign(logo.style,{
      width:'145px',height:'48px',minWidth:'145px',maxWidth:'145px',minHeight:'48px',maxHeight:'48px',
      objectFit:'contain',objectPosition:'left center',display:'block',margin:'0'
    });
    logo.removeAttribute('srcset');
  }

  wrap.appendChild(page);
  document.body.appendChild(wrap);
  return {wrap,page};
}

async function buildPdf(){
  if(generating)return null;
  generating=true;
  try{
    const pages=[...document.querySelectorAll('#printPage.review-summary-v6 .p')];
    if(pages.length!==2)throw new Error(`Expected 2 review pages, found ${pages.length}.`);
    const {html2canvas,jsPDF}=await libs();
    const logoData=await rasterLogo();
    const pdf=new jsPDF({orientation:'portrait',unit:'pt',format:'letter',compress:true});

    for(let i=0;i<pages.length;i++){
      if(i)pdf.addPage('letter','portrait');
      const {wrap,page}=exportFrame(pages[i],logoData);
      try{
        await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));
        const canvas=await html2canvas(page,{
          scale:2,
          backgroundColor:'#ffffff',
          useCORS:true,
          allowTaint:false,
          logging:false,
          width:816,
          height:1056,
          windowWidth:816,
          windowHeight:1056,
          scrollX:0,
          scrollY:0,
          x:0,
          y:0
        });
        const img=canvas.toDataURL('image/jpeg',0.98);
        pdf.addImage(img,'JPEG',0,0,612,792,undefined,'FAST');
      }finally{wrap.remove();}
    }
    return pdf;
  }finally{generating=false;}
}

async function downloadPdf(btn){
  const old=btn.textContent;btn.disabled=true;btn.textContent='Building PDF...';
  try{const pdf=await buildPdf();if(!pdf)return;pdf.save(`${safeName()}_CTOD_Review.pdf`);}
  catch(e){alert(`PDF could not be generated: ${e.message||e}`)}
  finally{btn.disabled=false;btn.textContent=old}
}

async function printPdf(btn){
  const old=btn.textContent;btn.disabled=true;btn.textContent='Preparing Print...';
  try{
    const pdf=await buildPdf();if(!pdf)return;
    const blob=pdf.output('blob');const url=URL.createObjectURL(blob);const w=window.open(url,'_blank');
    if(!w){
      const a=document.createElement('a');a.href=url;a.download=`${safeName()}_CTOD_Review.pdf`;a.click();
      alert('CTOD created the two-page portrait PDF. Open the downloaded PDF and print it at 1 page per sheet.');
    }else{
      setTimeout(()=>{try{w.focus();w.print()}catch{}},1200);
      setTimeout(()=>URL.revokeObjectURL(url),120000);
    }
  }catch(e){alert(`PDF could not be prepared for printing: ${e.message||e}`)}
  finally{btn.disabled=false;btn.textContent=old}
}

function install(){
  const host=document.querySelector('#printPage.review-summary-v6');
  if(!host||!host.querySelector('.p'))return;
  const actions=host.querySelector('.actions');if(!actions)return;
  if(actions.dataset.pdfExport===PDF_VERSION)return;
  actions.dataset.pdfExport=PDF_VERSION;
  actions.innerHTML=`<button id="downloadReviewPdf" class="btn primary">Download PDF</button><button id="printReviewPdf" class="btn primary">Print 2 Portrait Pages</button><button id="backReviewPdf" class="btn secondary">Back to Review</button>`;
  actions.querySelector('#downloadReviewPdf').onclick=e=>downloadPdf(e.currentTarget);
  actions.querySelector('#printReviewPdf').onclick=e=>printPdf(e.currentTarget);
  actions.querySelector('#backReviewPdf').onclick=()=>{host.style.display='none';host.innerHTML='';host.className='printpage';const app=document.querySelector('#app');if(app)app.hidden=false};
}

new MutationObserver(()=>install()).observe(document.body,{subtree:true,childList:true});
document.addEventListener('click',()=>setTimeout(install,0),true);
install();