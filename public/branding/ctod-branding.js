const BRAND_VERSION='20260809-1455';
const PRIMARY=`/branding/ctod-logo-1-primary.webp?v=${BRAND_VERSION}`;
const PEOPLE=`/branding/ctod-logo-2-people-shield.svg?v=${BRAND_VERSION}`;
const CITY=`/branding/ctod-logo-3-city-ring.svg?v=${BRAND_VERSION}`;
const PERFORMANCE=`/branding/ctod-logo-4-performance-mark.svg?v=${BRAND_VERSION}`;

function installBrandStyles(){
 if(document.querySelector('#ctodBrandStyles'))return;
 const s=document.createElement('style');s.id='ctodBrandStyles';s.textContent=`
 .brand{align-items:center!important;gap:16px!important}.brand .mark{display:none!important}.ctod-primary-brand{width:235px;max-width:42vw;height:92px;object-fit:contain;object-position:left center;border-radius:12px;filter:drop-shadow(0 7px 18px rgba(0,0,0,.18))}.brand>div:last-child h1{display:none}.brand>div:last-child p{font-weight:800;letter-spacing:.04em;color:#8b6817!important;text-transform:uppercase;font-size:11px!important;margin:0!important}.ctod-brand-chip{position:absolute;right:18px;top:16px;width:106px;height:58px;object-fit:contain;opacity:.2;pointer-events:none;mix-blend-mode:screen}.ctod-brand-chip.strong{opacity:.42}.master-shell,.test-review-shell{position:relative}.ctod-gold-rule{height:2px;background:linear-gradient(90deg,transparent,#d6a62d 18%,#f3d36b 50%,#d6a62d 82%,transparent);opacity:.6;margin:4px 0 14px}
 @media(max-width:720px){.ctod-primary-brand{width:180px;height:72px}.brand>div:last-child p{display:none}.ctod-brand-chip{width:80px;height:44px}}
 `;document.head.appendChild(s);
}

function brandHeader(){
 const brand=document.querySelector('.brand');if(!brand||brand.dataset.ctodBrand==='1')return;
 brand.dataset.ctodBrand='1';const mark=brand.querySelector('.mark');if(mark){const img=document.createElement('img');img.className='ctod-primary-brand';img.src=PRIMARY;img.alt='CTOD';mark.replaceWith(img)}
 const p=brand.querySelector('p');if(p)p.textContent='Building People. Driving Performance.';
}
function addChip(host,src,strong=false){if(!host||host.querySelector(':scope > .ctod-brand-chip'))return;const img=document.createElement('img');img.className='ctod-brand-chip'+(strong?' strong':'');img.src=src;img.alt='';host.prepend(img)}
function decorateViews(){
 const master=document.querySelector('#masterView .master-shell');if(master){addChip(master,PEOPLE,true);if(!master.querySelector(':scope > .ctod-gold-rule')){const r=document.createElement('div');r.className='ctod-gold-rule';const hero=master.querySelector('.master-hero');hero?.insertAdjacentElement('afterend',r)}}
 const test=document.querySelector('#testReviewView .test-review-shell');if(test)addChip(test,PERFORMANCE,true);
 const reviews=document.querySelector('#reviewsView');if(reviews&&getComputedStyle(reviews).position==='static')reviews.style.position='relative';if(reviews)addChip(reviews,CITY,false);
 const coaching=document.querySelector('#coachingView');if(coaching&&getComputedStyle(coaching).position==='static')coaching.style.position='relative';if(coaching)addChip(coaching,PEOPLE,false);
 const employees=document.querySelector('#employeesView');if(employees&&getComputedStyle(employees).position==='static')employees.style.position='relative';if(employees)addChip(employees,PERFORMANCE,false);
}
function run(){installBrandStyles();brandHeader();decorateViews()}
run();setTimeout(run,400);setTimeout(run,1200);new MutationObserver(()=>requestAnimationFrame(run)).observe(document.documentElement,{childList:true,subtree:true});
