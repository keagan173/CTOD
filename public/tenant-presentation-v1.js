const sb=window.ctodSupabase;
const escText=s=>String(s||'').trim();
let companyName='Company';
async function loadCompany(){
  const id=window.ctodWorkspaceContext?.companyId;
  if(!id||!sb)return;
  const {data}=await sb.from('companies').select('name').eq('id',id).maybeSingle();
  companyName=data?.name||'Company';
  patch();
}
function patch(){
  document.querySelectorAll('#masterView h3').forEach(h=>{
    if(/Commercial Tire Location Map/i.test(h.textContent||''))h.textContent=`${companyName} Location Map`;
  });
  document.querySelectorAll('.ctod-section-intro').forEach(el=>{
    if(/Commercial Tire/i.test(el.textContent||''))el.textContent='Core behaviors expected across the organization.';
  });
  const masterSub=[...document.querySelectorAll('#masterView .sub')].find(x=>/locations this user is authorized/i.test(x.textContent||''));
  if(masterSub&&companyName!=='Company')masterSub.textContent=masterSub.textContent.replace(/company/ig,companyName);
}
function burst(){[0,80,220,500,900].forEach(ms=>setTimeout(patch,ms))}
document.addEventListener('ctod:workspace-ready',()=>{loadCompany();burst()});
document.addEventListener('click',e=>{if(e.target.closest('#tabMaster,#tabReviews,.review,.review-card,.review-row'))burst()},true);
if(window.ctodWorkspaceContext)loadCompany();
