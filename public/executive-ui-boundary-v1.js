function applyExecutiveBoundary(ctx){
  if(ctx?.role!=='executive')return;
  const hideOwnerControls=()=>{
    document.querySelectorAll('button,a,[role="tab"]').forEach(el=>{
      const t=(el.textContent||'').trim().toLowerCase();
      if(t==='job roles'||t==='test review'){
        el.style.display='none';
        el.setAttribute('aria-hidden','true');
        el.tabIndex=-1;
      }
    });
    document.querySelectorAll('[data-owner-only="true"],.owner-only,.platform-admin-only').forEach(el=>{
      el.style.display='none';
      el.setAttribute('aria-hidden','true');
    });
  };
  hideOwnerControls();
  const observer=new MutationObserver(()=>queueMicrotask(hideOwnerControls));
  observer.observe(document.body,{childList:true,subtree:true});
}
document.addEventListener('ctod:workspace-ready',e=>applyExecutiveBoundary(e.detail));
if(window.ctodWorkspaceContext)applyExecutiveBoundary(window.ctodWorkspaceContext);
