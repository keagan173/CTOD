import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL='https://wezcuprboyvbmlnuqdoi.supabase.co';
const SUPABASE_KEY='sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5';
const sb=createClient(SUPABASE_URL,SUPABASE_KEY);
const $=s=>document.querySelector(s);
const inviteToken=new URLSearchParams(location.search).get('invite');

async function validateInvite(){
  $('#inviteSetup').hidden=false;
  $('#activateInvite').disabled=true;
  $('#inviteMsg').textContent='Checking invitation...';
  try{
    const r=await fetch(SUPABASE_URL+'/functions/v1/complete-ctod-invite?token='+encodeURIComponent(inviteToken||''));
    const data=await r.json();
    if(!r.ok||!data.ok){
      $('#inviteMsg').textContent=data.error||'Invite is invalid.';
      return;
    }
    if(!data.active){
      $('#inviteMsg').textContent=data.accepted?'This invitation has already been activated.':data.expired?'This invitation has expired.':data.revoked?'This invitation was revoked.':'Invite is no longer active.';
      return;
    }
    $('#inviteEmail').textContent=data.email+' • '+String(data.role||'').replaceAll('_',' ');
    $('#inviteMsg').textContent='Invitation verified. Create your password below.';
    $('#activateInvite').disabled=false;
  }catch(e){
    $('#inviteMsg').textContent='Could not verify invitation. Check your connection and try again.';
  }
}

async function activateInvite(){
  const p=$('#invitePassword').value;
  const p2=$('#invitePassword2').value;
  if(p.length<8){$('#inviteMsg').textContent='Password must be at least 8 characters.';return}
  if(p!==p2){$('#inviteMsg').textContent='Passwords do not match.';return}
  $('#activateInvite').disabled=true;
  $('#inviteMsg').textContent='Activating CTOD access...';
  try{
    const r=await fetch(SUPABASE_URL+'/functions/v1/complete-ctod-invite',{
      method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({token:inviteToken,password:p})
    });
    const data=await r.json();
    if(!r.ok||!data.ok){
      $('#inviteMsg').textContent=data.error||'Could not activate invite.';
      $('#activateInvite').disabled=false;
      return;
    }
    const s=await sb.auth.signInWithPassword({email:data.email,password:p});
    if(s.error){
      $('#inviteMsg').textContent='Access activated. Opening CTOD sign in...';
      setTimeout(()=>location.href='/',900);
      return;
    }
    $('#inviteMsg').textContent='Access activated. Opening your CTOD dashboard...';
    setTimeout(()=>location.href='/',650);
  }catch(e){
    $('#inviteMsg').textContent='Activation failed. Please try again.';
    $('#activateInvite').disabled=false;
  }
}

$('#activateInvite').onclick=activateInvite;
validateInvite();
