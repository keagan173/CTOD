import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const url=Deno.env.get("SUPABASE_URL")!; const service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin=createClient(url,service,{auth:{autoRefreshToken:false,persistSession:false}});
const cors={"access-control-allow-origin":"*","access-control-allow-headers":"content-type, authorization, apikey","access-control-allow-methods":"GET, POST, OPTIONS"};
const json=(body:any,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,'content-type':'application/json'}});
Deno.serve(async(req:Request)=>{
  if(req.method==='OPTIONS') return new Response('ok',{headers:cors});
  try{
    if(req.method==='GET'){
      const token=String(new URL(req.url).searchParams.get('token')||'');
      if(!token) return json({ok:false,error:'Invite token required'},400);
      const {data:inv,error}=await admin.from('access_invites').select('email,intended_role,accepted_at,revoked_at,expires_at').eq('token',token).maybeSingle();
      if(error) throw error;
      if(!inv) return json({ok:false,error:'Invite is invalid'},404);
      const expired=new Date(inv.expires_at)<=new Date();
      return json({ok:true,email:inv.email,role:inv.intended_role,active:!inv.accepted_at&&!inv.revoked_at&&!expired,accepted:!!inv.accepted_at,revoked:!!inv.revoked_at,expired,expires_at:inv.expires_at});
    }
    const body=await req.json();
    const token=String(body.token||''); const password=String(body.password||'');
    if(!token) throw new Error('Invite token required');
    if(password.length<8) throw new Error('Password must be at least 8 characters');
    const {data:inv,error:ie}=await admin.from('access_invites').select('id,company_id,email,intended_role,accepted_at,revoked_at,expires_at,invited_by_user_id').eq('token',token).maybeSingle();
    if(ie) throw ie;
    if(!inv||inv.accepted_at||inv.revoked_at||new Date(inv.expires_at)<=new Date()) throw new Error('Invite is invalid or expired');
    const email=String(inv.email).trim().toLowerCase();
    const {data:list,error:le}=await admin.auth.admin.listUsers({page:1,perPage:1000}); if(le) throw le;
    let user=list.users.find((u:any)=>String(u.email||'').toLowerCase()===email);
    if(user){const {data:up,error:ue}=await admin.auth.admin.updateUserById(user.id,{password,email_confirm:true});if(ue)throw ue;user=up.user}
    else{const {data:cr,error:ce}=await admin.auth.admin.createUser({email,password,email_confirm:true});if(ce)throw ce;user=cr.user}
    const uid=user.id;
    await admin.from('profiles').upsert({id:uid,display_name:email.split('@')[0]},{onConflict:'id'});
    const {error:me}=await admin.from('company_memberships').upsert({company_id:inv.company_id,user_id:uid,role:inv.intended_role,location_id:null,active:true},{onConflict:'company_id,user_id'}); if(me)throw me;
    const {data:locs,error:loe}=await admin.from('access_invite_locations').select('location_id').eq('invite_id',inv.id); if(loe)throw loe;
    await admin.from('user_location_access').update({active:false,revoked_at:new Date().toISOString()}).eq('company_id',inv.company_id).eq('user_id',uid);
    for(const l of (locs||[])){const {error:ae}=await admin.from('user_location_access').upsert({company_id:inv.company_id,user_id:uid,location_id:l.location_id,access_role:inv.intended_role,active:true,revoked_at:null,granted_by_user_id:inv.invited_by_user_id,granted_at:new Date().toISOString()},{onConflict:'user_id,location_id'});if(ae)throw ae}
    await admin.from('access_invites').update({accepted_at:new Date().toISOString()}).eq('id',inv.id);
    return json({ok:true,email,role:inv.intended_role,location_count:(locs||[]).length});
  }catch(e){return json({ok:false,error:e instanceof Error?e.message:String(e)},400)}
});
