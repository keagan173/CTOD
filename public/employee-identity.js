const sixDigit=/^\d{6}$/;

function hardenEmployeeIdentityUI(){
  const input=document.querySelector('#empCode');
  if(input&&!input.dataset.identityHardened){
    input.dataset.identityHardened='1';input.required=true;input.maxLength=6;input.inputMode='numeric';input.pattern='[0-9]{6}';input.placeholder='6-digit employee number';input.addEventListener('input',()=>{input.value=input.value.replace(/\D/g,'').slice(0,6)});const label=input.closest('div')?.querySelector('label');if(label)label.textContent='6-digit employee number';
  }
}
document.addEventListener('click',e=>{const btn=e.target.closest('#empAdd');if(!btn)return;const input=document.querySelector('#empCode');if(!input||sixDigit.test(input.value.trim()))return;e.preventDefault();e.stopImmediatePropagation();const msg=document.querySelector('#empMsg');if(msg)msg.textContent='Employee number must be exactly 6 digits.';input.focus()},{capture:true});
new MutationObserver(hardenEmployeeIdentityUI).observe(document.documentElement,{childList:true,subtree:true});hardenEmployeeIdentityUI();
await import('/exceptional-ui.js?v=20260809-2227');
import('/talent-intelligence-v2.js?v=20260809-2227');
import('/employee-edit.js?v=20260809-2227');
import('/system-admin.js?v=20260809-2227');
import('/promotion-readiness-center.js?v=20260809-2227');
import('/review-career-standard.js?v=20260809-2227');
import('/compensation-standard.js?v=20260809-2227');
import('/review-history-summary.js?v=20260809-2227');
import('/review-history.js?v=20260809-2227');
import('/master-layout-v3.js?v=20260809-2227');
import('/master-leadership-summary.js?v=20260809-2227');
import('/master-test-review.js?v=20260810-002');
import('/review-summary-v2.js?v=20260809-2227');
import('/review-launcher.js?v=20260809-2227');
import('/branding/ctod-branding.js?v=20260809-2227');
setTimeout(()=>import('/master-map-v2.js?v=20260809-2227').catch(()=>setTimeout(()=>import('/master-map-v2.js?v=20260809-2227-r2'),1200)),250);
setTimeout(()=>import('/presentation-mode.js?v=20260809-2227'),650);
