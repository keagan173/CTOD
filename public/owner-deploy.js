import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.112.2';
const SUPABASE_URL='https://zgwkjyezpgboysiklodj.supabase.co';
const SUPABASE_KEY='sb_publishable_sWjR6yZoedl3q2vYzvRtRg_Pw1Jtuu7';
const sb=createClient(SUPABASE_URL,SUPABASE_KEY);
const $=s=>document.querySelector(s); const esc=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
let current=null;
async function call(action,payload={}){const {data:{session}}=await sb.auth.getSession(); if(!session) throw new Error('Sign in required'); const r=await fetch(SUPABASE_URL+'/functions/v1/ctod-owner-deploy',{method:'POST',headers:{authorization:'Bearer '+session.access_token,apikey:SUPABASE_KEY,'content-type':'application/json'},body:JSON.stringify({action,...payload})}); const d=await r.json(); if(!r.ok||!d.ok) throw new Error(d.error||'Owner deployment service failed'); return d;}
function showCfg(cfg){return cfg?`<div><b>${esc(cfg.version_label)}</b></div><div class="muted">${esc(cfg.status)} · ${esc(cfg.schema_version)} · ${esc(cfg.id)}</div>`:'<div class="muted">None</div>'}
function render(d){
  current=d; const cfg=d.configuration||{};
  $('#live').innerHTML=showCfg(cfg.published_configuration); $('#draft').innerHTML=showCfg(cfg.draft_configuration);
  const vals=d.validations||[]; const latest=vals[0];
  if(latest){const checks=Array.isArray(latest.checks)?latest.checks:[]; $('#checks').innerHTML=checks.map(c=>`<div class="check ${c.passed?'pass':'fail'}">${c.passed?'✓':'✕'} ${esc(c.message||c.code)}</div>`).join('')+`<div class="muted">Validated ${esc(latest.validated_at)} · ${latest.passed?'PASS':'FAIL'}</div>`;} else $('#checks').innerHTML='<div class="muted">No validation has been run for this sandbox.</div>';
  $('#validate').disabled=!cfg.draft_configuration?.id;
  $('#promote').disabled=!(cfg.draft_configuration?.id&&latest?.passed);
  $('#discard').disabled=!cfg.draft_configuration?.id;
  const targets=d.rollback_targets||[]; const select=$('#rollbackTarget'); select.innerHTML='<option value="">No eligible rollback target</option>'+targets.map(v=>`<option value="${esc(v.id)}">${esc(v.version_label)} · ${esc(v.schema_version)} · ${esc(v.id)}</option>`).join('');
  $('#rollback').disabled=!!cfg.draft_configuration?.id||!targets.length;
  $('#history').innerHTML=(d.release_history||[]).map(h=>`<div class="history"><b>${esc(h.action)}</b> <span class="pill">${esc(h.created_at)}</span><div class="muted">${esc(h.reason||'')}</div><div class="muted">${esc(h.from_config_version_id||'none')} → ${esc(h.to_config_version_id||'none')}</div></div>`).join('')||'<div class="muted">No customer configuration releases yet.</div>';
}
async function load(){const id=$('#companyId').value.trim(); $('#msg').textContent='Loading customer...'; try{const d=await call('status',{company_id:id});render(d);$('#msg').textContent='Customer deployment state loaded.';}catch(e){$('#msg').textContent=e.message}}
$('#signin').onclick=async()=>{const {error}=await sb.auth.signInWithPassword({email:$('#email').value.trim(),password:$('#password').value}); if(error){$('#authMsg').textContent=error.message;return} $('#auth').hidden=true;$('#console').hidden=false;};
$('#logout').onclick=async()=>{await sb.auth.signOut();location.reload()}; $('#load').onclick=load;
$('#validate').onclick=async()=>{try{$('#msg').textContent='Validating sandbox...';await call('validate',{company_id:$('#companyId').value.trim(),config_version_id:current.configuration.draft_configuration.id});await load();}catch(e){$('#msg').textContent=e.message}};
$('#promote').onclick=async()=>{const why=$('#reason').value.trim(); if(!why){$('#msg').textContent='Enter a deployment reason.';return} try{$('#msg').textContent='Promoting validated sandbox...';await call('promote',{company_id:$('#companyId').value.trim(),config_version_id:current.configuration.draft_configuration.id,reason:why});$('#reason').value='';await load();$('#msg').textContent='Promotion complete. Only this customer configuration changed.';}catch(e){$('#msg').textContent=e.message}};
$('#discard').onclick=async()=>{const why=$('#reason').value.trim(); if(!why){$('#msg').textContent='Enter a reason before discarding the sandbox.';return} if(!confirm('Discard this customer sandbox draft? The current live configuration will remain unchanged.')) return; try{$('#msg').textContent='Discarding customer sandbox...';await call('discard_draft',{company_id:$('#companyId').value.trim(),reason:why});$('#reason').value='';await load();$('#msg').textContent='Sandbox draft discarded. Live customer configuration was not changed.';}catch(e){$('#msg').textContent=e.message}};
$('#rollback').onclick=async()=>{const target=$('#rollbackTarget').value; const why=$('#rollbackReason').value.trim(); if(!target){$('#msg').textContent='Choose a prior configuration.';return} if(!why){$('#msg').textContent='Enter a rollback reason.';return} if(!confirm('Rollback this customer to the selected prior configuration?')) return; try{$('#msg').textContent='Rolling back customer configuration...';await call('rollback',{company_id:$('#companyId').value.trim(),target_config_version_id:target,reason:why});$('#rollbackReason').value='';await load();$('#msg').textContent='Rollback complete. Only this customer configuration changed.';}catch(e){$('#msg').textContent=e.message}};
const {data:{session}}=await sb.auth.getSession(); if(session){$('#auth').hidden=true;$('#console').hidden=false;}
