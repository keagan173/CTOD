const $m=s=>document.querySelector(s);
let mapLoaded=false,presentationLoaded=false;
function ensureMapHost(){
 const master=$m('#masterView');if(!master||master.classList.contains('hidden'))return null;
 const first=master.querySelector('.ctod-section');if(!first)return null;
 let host=$m('#ctodMap');if(!host){
   const grid=first.querySelector('.ctod-map-grid');if(grid)grid.remove();
   host=document.createElement('div');host.id='ctodMap';host.style.height='430px';host.style.borderRadius='16px';host.style.overflow='hidden';host.innerHTML='<div style="height:100%;display:grid;place-items:center;color:#8fb0c8">Loading company map...</div>';
   first.appendChild(host);
 }
 return host;
}
async function loadMap(){const host=ensureMapHost();if(!host)return;if(!mapLoaded){mapLoaded=true;try{await import('/master-map-v2.js?v=20260815-masterrestore1')}catch(e){console.error('CTOD master map restore',e);mapLoaded=false}}else{window.ctodRenderMasterMap?.(true)}}
async function loadPresentation(){if(presentationLoaded)return;presentationLoaded=true;try{
 const original=window.ctodWorkspaceReady;const ctx=original?await original:window.ctodWorkspaceContext;
 if(ctx&&!ctx.isMaster)window.ctodWorkspaceReady=Promise.resolve({...ctx,isMaster:true});
 await import('/presentation-mode.js?v=20260815-masterrestore1');
 if(original)window.ctodWorkspaceReady=original;
}catch(e){console.error('CTOD presentation restore',e);presentationLoaded=false}}
async function restore(){if(!$m('#masterView')||$m('#masterView').classList.contains('hidden'))return;await loadMap();await loadPresentation()}
document.addEventListener('click',e=>{if(e.target?.id==='tabMaster')setTimeout(restore,80)});
document.addEventListener('ctod:master-rendered',()=>setTimeout(restore,80));
setTimeout(restore,250);setTimeout(restore,900);
