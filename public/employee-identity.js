const sixDigit=/^\d{6}$/;

function hardenEmployeeIdentityUI(){
  const input=document.querySelector('#empCode');
  if(input&&!input.dataset.identityHardened){
    input.dataset.identityHardened='1';input.required=true;input.maxLength=6;input.inputMode='numeric';input.pattern='[0-9]{6}';input.placeholder='6-digit employee number';input.addEventListener('input',()=>{input.value=input.value.replace(/\D/g,'').slice(0,6)});const label=input.closest('div')?.querySelector('label');if(label)label.textContent='6-digit employee number';
  }
}
document.addEventListener('click',e=>{const btn=e.target.closest('#empAdd');if(!btn)return;const input=document.querySelector('#empCode');if(!input||sixDigit.test(input.value.trim()))return;e.preventDefault();e.stopImmediatePropagation();const msg=document.querySelector('#empMsg');if(msg)msg.textContent='Employee number must be exactly 6 digits.';input.focus()},{capture:true});
new MutationObserver(hardenEmployeeIdentityUI).observe(document.documentElement,{childList:true,subtree:true});hardenEmployeeIdentityUI();
const workspace=await window.ctodWorkspaceReady;
await import('/exceptional-ui.js?v=20260810-005');
await Promise.allSettled([
  import('/talent-intelligence-v2.js?v=20260810-005'),
  import('/employee-edit.js?v=20260810-004'),
  import('/promotion-readiness-center.js?v=20260810-004'),
  import('/review-career-standard.js?v=20260810-005'),
  import('/compensation-standard.js?v=20260810-005'),
  import('/review-history-summary.js?v=20260810-005'),
  import('/review-history.js?v=20260810-005'),
  import('/review-summary-v2.js?v=20260810-005'),
  import('/review-launcher.js?v=20260810-007'),
  import('/branding/ctod-branding.js?v=20260810-004')
]);
if(workspace?.isMaster){
  await Promise.allSettled([
    import('/system-admin.js?v=20260810-004'),
    import('/master-layout-v3.js?v=20260810-004'),
    import('/master-leadership-summary.js?v=20260810-004'),
    import('/master-test-review.js?v=20260810-004'),
    import('/master-map-v2.js?v=20260810-004'),
    import('/presentation-mode.js?v=20260810-004')
  ]);
}
