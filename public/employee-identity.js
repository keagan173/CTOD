const sixDigit=/^\d{6}$/;

function hardenEmployeeIdentityUI(){
  const input=document.querySelector('#empCode');
  if(input){
    input.required=true;
    input.maxLength=6;
    input.inputMode='numeric';
    input.pattern='[0-9]{6}';
    input.placeholder='6-digit employee number';
    input.addEventListener('input',()=>{input.value=input.value.replace(/\D/g,'').slice(0,6)});
    const label=input.closest('div')?.querySelector('label');
    if(label)label.textContent='6-digit employee number';
  }
  document.querySelectorAll('#coachEmployee option').forEach(o=>{
    if(o.value&&!/Employee #/.test(o.textContent||'')){
      const row=window.__ctodRoster?.find?.(x=>x.employee_id===o.value);
      if(row?.employee_code)o.textContent=`${row.first_name} ${row.last_name} · Employee #${row.employee_code} · ${row.role_title} · ${row.location_code}`;
    }
  });
}

new MutationObserver(hardenEmployeeIdentityUI).observe(document.documentElement,{childList:true,subtree:true});
hardenEmployeeIdentityUI();
