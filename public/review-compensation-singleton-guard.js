const ROOT_ID='reviewDetail';
let scheduled=false;
function score(panel){
  let s=0;
  if(panel.querySelector('#compManagerTiming')?.value)s+=8;
  if(panel.querySelector('#compManagerComment')?.value)s+=4;
  if(panel.querySelector('#compReason')?.value)s+=2;
  if(panel.querySelector('#compEmployeeTiming')?.value)s+=1;
  return s;
}
function enforce(){
  const root=document.getElementById(ROOT_ID);
  if(!root)return;
  const panels=[...root.querySelectorAll('.ctod-comp-standard')];
  if(panels.length<=1)return;
  panels.sort((a,b)=>score(b)-score(a));
  const keep=panels[0];
  panels.slice(1).forEach(p=>p.remove());
  keep.dataset.ctodSingleton='true';
  console.warn('CTOD compensation guard removed duplicate Raise Discussion panels');
}
function run(delay=40){
  if(scheduled)return;
  scheduled=true;
  setTimeout(()=>{scheduled=false;enforce()},delay);
}
const root=document.getElementById(ROOT_ID);
if(root)new MutationObserver(()=>run()).observe(root,{childList:true,subtree:true});
document.addEventListener('click',e=>{if(e.target?.closest('.review,#tabReviews'))run(80)});
setTimeout(()=>run(0),250);
setTimeout(()=>run(0),900);
