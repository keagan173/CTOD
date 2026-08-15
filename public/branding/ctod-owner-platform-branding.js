(()=>{
  const PRIMARY='/branding/ctod-logo-1-primary.svg?v=20260815-owner';
  const PEOPLE='/branding/ctod-logo-2-people-shield.svg?v=20260815-owner';
  const PERFORMANCE='/branding/ctod-logo-4-performance-mark.svg?v=20260815-owner';
  if(!document.querySelector('link[data-ctod-owner-theme]')){
    const l=document.createElement('link');l.rel='stylesheet';l.href='/branding/ctod-owner-platform-theme.css?v=20260815';l.dataset.ctodOwnerTheme='1';document.head.appendChild(l);
  }
  function install(){
    const main=document.querySelector('main');if(!main)return;
    if(!main.querySelector(':scope > .ctod-owner-brandbar')){
      const bar=document.createElement('div');bar.className='ctod-owner-brandbar';bar.innerHTML=`<img src="${PRIMARY}" alt="CTOD — Building People. Driving Performance."><div class="ctod-owner-brandcopy"><div class="ctod-owner-eyebrow">Platform Owner Control Plane</div><div class="ctod-owner-tagline">BUILDING PEOPLE. DRIVING PERFORMANCE.</div></div>`;main.prepend(bar);
      const rule=document.createElement('div');rule.className='ctod-owner-rule';bar.insertAdjacentElement('afterend',rule);
    }
    if(!main.querySelector(':scope > .ctod-owner-nav')){
      const nav=document.createElement('nav');nav.className='ctod-owner-nav';nav.setAttribute('aria-label','Platform Owner');
      const customer=new URLSearchParams(location.search).get('company');
      nav.innerHTML='<a href="/owner">Owner Console</a><a href="/owner-support">System Health</a><a href="/owner-industry-builder">Industry Builder</a>'+(customer?`<a href="/owner-customer?company=${encodeURIComponent(customer)}">Customer Management</a>`:'');
      const rule=main.querySelector(':scope > .ctod-owner-rule');
      if(rule)rule.insertAdjacentElement('afterend',nav);else main.prepend(nav);
      const here=location.pathname.replace(/\.html$/,'');
      nav.querySelectorAll('a').forEach(a=>{if(here===new URL(a.href,location.origin).pathname)a.classList.add('active')});
    }
    document.querySelectorAll('.card h2').forEach((h,i)=>{
      const card=h.closest('.card');if(!card||card.querySelector(':scope > .ctod-section-mark'))return;
      if(i===0)return;
      const img=document.createElement('img');img.className='ctod-section-mark';img.src=i%2?PEOPLE:PERFORMANCE;img.alt='';img.setAttribute('aria-hidden','true');card.prepend(img);
    });
  }
  install();
  new MutationObserver(()=>requestAnimationFrame(install)).observe(document.documentElement,{childList:true,subtree:true});
})();
