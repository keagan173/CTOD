const sixDigit=/^\d{6}$/;

function hardenEmployeeIdentityUI(){
  const input=document.querySelector('#empCode');
  if(input&&!input.dataset.identityHardened){
    input.dataset.identityHardened='1';input.required=true;input.maxLength=6;input.inputMode='numeric';input.pattern='[0-9]{6}';input.placeholder='6-digit employee number';input.addEventListener('input',()=>{input.value=input.value.replace(/\D/g,'').slice(0,6)});const label=input.closest('div')?.querySelector('label');if(label)label.textContent='6-digit employee number';
  }
}
document.addEventListener('click',e=>{const btn=e.target.closest('#empAdd');if(!btn)return;const input=document.querySelector('#empCode');if(!input||sixDigit.test(input.value.trim()))return;e.preventDefault();e.stopImmediatePropagation();const msg=document.querySelector('#empMsg');if(msg)msg.textContent='Employee number must be exactly 6 digits.';input.focus()},{capture:true});
new MutationObserver(hardenEmployeeIdentityUI).observe(document.documentElement,{childList:true,subtree:true});hardenEmployeeIdentityUI();
await import('/exceptional-ui.js?v=20260809-1924');
import('/talent-intelligence-v2.js?v=20260809-1924');
import('/employee-edit.js?v=20260809-1924');
import('/system-admin.js?v=20260809-1924');
import('/promotion-readiness-center.js?v=20260809-1924');
import('/master-layout-v3.js?v=20260809-1924');
import('/master-leadership-summary.js?v=20260809-1924');
import('/master-test-review.js?v=20260809-1924');
import('/review-summary-v2.js?v=20260809-1924');
import('/review-launcher.js?v=20260809-1924');
import('/branding/ctod-branding.js?v=20260809-1924');
import('/pitch-mode.js?v=20260809-1924');
setTimeout(()=>import('/master-map-v2.js?v=20260809-1924'),700);