const BRAND_VERSION='20260815-0200';
const PRIMARY=`/branding/ctod-logo-1-primary.svg?v=${BRAND_VERSION}`;
const PEOPLE=`/branding/ctod-logo-2-people-shield.svg?v=${BRAND_VERSION}`;
const CITY=`/branding/ctod-logo-3-city-ring.svg?v=${BRAND_VERSION}`;
const PERFORMANCE=`/branding/ctod-logo-4-performance-mark.svg?v=${BRAND_VERSION}`;

function installBrandStyles(){
  if(document.querySelector('#ctodBrandStyles'))return;
  const s=document.createElement('style');s.id='ctodBrandStyles';s.textContent=`
  body{background:#07111d!important}.brand{display:none!important}
  #app{position:relative}.ctod-app-brandbar{display:flex;align-items:center;justify-content:space-between;gap:18px;margin:0 0 14px;padding:14px 20px;background:linear-gradient(135deg,#050607,#0a1522 58%,#0b1d2d);border:1px solid rgba(214,166,45,.45);border-radius:18px;box-shadow:0 12px 30px rgba(0,0,0,.18);overflow:visible!important;min-height:106px}
  .ctod-primary-brand{display:block;width:360px!important;max-width:48vw!important;height:88px!important;object-fit:contain!important;object-position:left center!important;overflow:visible!important;flex:0 0 auto;padding:3px 0}
  .ctod-brandbar-copy{text-align:right;min-width:250px}.ctod-brandbar-kicker{font-size:10px;font-weight:900;letter-spacing:.18em;text-transform:uppercase;color:#d6a62d}.ctod-brandbar-name{margin-top:4px;color:#f4f7fb;font-size:13px;font-weight:800;letter-spacing:.04em}
  .ctod-view-brand{position:relative;overflow:hidden}.ctod-view-brandmark{position:absolute;right:18px;top:14px;width:110px;height:62px;object-fit:contain;opacity:.52;pointer-events:none;z-index:0}.ctod-view-brand>*:not(.ctod-view-brandmark){position:relative;z-index:1}
  .master-shell>.ctod-view-brandmark{width:132px;height:74px;opacity:.58}.test-review-shell>.ctod-view-brandmark{width:118px;height:66px;opacity:.56}
  .ctod-brand-ribbon{display:flex;align-items:center;justify-content:flex-end;min-height:42px;margin:0 0 10px;padding:6px 10px;border:1px solid rgba(214,166,45,.28);border-radius:12px;background:linear-gradient(90deg,rgba(5,6,7,.15),rgba(5,6,7,.65));overflow:hidden}.ctod-brand-ribbon img{display:block;width:92px;height:42px;object-fit:contain;opacity:.82}
  .ctod-gold-rule{height:2px;background:linear-gradient(90deg,transparent,#d6a62d 18%,#f3d36b 50%,#d6a62d 82%,transparent);opacity:.72;margin:4px 0 14px}
  @media(max-width:760px){.ctod-app-brandbar{padding:10px 14px;min-height:84px}.ctod-primary-brand{width:265px!important;height:68px!important;max-width:78vw!important}.ctod-brandbar-copy{display:none}.ctod-view-brandmark{width:78px;height:44px;right:10px;top:9px;opacity:.42}}
  `;document.head.appendChild(s);
}
function installMainBrandbar(){
  const app=document.querySelector('#app');if(!app)return;
  const stable=app.querySelector(':scope > .ctod-customer-brandbar');
  const generated=[...app.querySelectorAll(':scope > .ctod-app-brandbar')];
  if(stable){generated.forEach(x=>x.remove());return}
  if(generated.length){generated.slice(1).forEach(x=>x.remove());return}
  const bar=document.createElement('div');bar.className='ctod-app-brandbar';bar.innerHTML=`<img class="ctod-primary-brand" src="${PRIMARY}" alt="CTOD — Building People. Driving Performance."><div class="ctod-brandbar-copy"><div class="ctod-brandbar-kicker">Career & Talent Optimization Dashboard</div><div class="ctod-brandbar-name">Building People. Driving Performance.</div></div>`;app.prepend(bar)
}
function addWatermark(host,src){if(!host||host.querySelector(':scope > .ctod-view-brandmark'))return;host.classList.add('ctod-view-brand');const img=document.createElement('img');img.className='ctod-view-brandmark';img.src=src;img.alt='';img.setAttribute('aria-hidden','true');host.prepend(img)}
function addRibbon(host,src){if(!host||host.querySelector(':scope > .ctod-brand-ribbon'))return;const r=document.createElement('div');r.className='ctod-brand-ribbon';r.innerHTML=`<img src="${src}" alt="" aria-hidden="true">`;host.prepend(r)}
function decorateViews(){const master=document.querySelector('#masterView .master-shell');if(master){addWatermark(master,PEOPLE);if(!master.querySelector(':scope > .ctod-gold-rule')){const rule=document.createElement('div');rule.className='ctod-gold-rule';master.querySelector('.master-hero')?.insertAdjacentElement('afterend',rule)}}const test=document.querySelector('#testReviewView .test-review-shell');if(test)addWatermark(test,PERFORMANCE);const reviews=document.querySelector('#reviewsView');if(reviews)addRibbon(reviews,CITY);const coaching=document.querySelector('#coachingView');if(coaching)addRibbon(coaching,PEOPLE);const employees=document.querySelector('#employeesView');if(employees)addRibbon(employees,PERFORMANCE);const people=document.querySelector('#peopleView');if(people)addRibbon(people,CITY)}
function run(){installBrandStyles();installMainBrandbar();decorateViews()}
run();setTimeout(run,300);setTimeout(run,900);