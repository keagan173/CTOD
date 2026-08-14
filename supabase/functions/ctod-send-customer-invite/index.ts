import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.112.2";

const url=Deno.env.get("SUPABASE_URL")!;
const service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin=createClient(url,service,{auth:{persistSession:false,autoRefreshToken:false}});
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, apikey, content-type","Access-Control-Allow-Methods":"POST,OPTIONS"};
const out=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"content-type":"application/json","cache-control":"no-store"}});
function claims(jwt:string){try{let s=jwt.split('.')[1].replace(/-/g,'+').replace(/_/g,'/');while(s.length%4)s+='=';return JSON.parse(atob(s))}catch{return {}}}

Deno.serve(async(req)=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
  try{
    const jwt=(req.headers.get("authorization")||"").replace(/^Bearer\s+/i,"");
    if(!jwt)throw new Error("Authentication required");
    if(claims(jwt).aal!=="aal2")throw new Error("MFA verification required");
    const {data:who,error:ue}=await admin.auth.getUser(jwt);
    if(ue||!who.user)throw new Error("Authentication required");

    const {error:gateError}=await admin.rpc("operator_service_dashboard",{p_actor_user_id:who.user.id});
    if(gateError)throw new Error("Platform Owner access required");

    const b=await req.json().catch(()=>({}));
    const inviteId=String(b.invite_id||"");
    if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(inviteId))throw new Error("Valid invite ID required");

    const {data:inv,error:ie}=await admin.from("access_invites")
      .select("id,company_id,email,token,expires_at,accepted_at,revoked_at")
      .eq("id",inviteId).maybeSingle();
    if(ie||!inv)throw new Error("Invite not found");
    if(inv.accepted_at)throw new Error("Invite is already accepted");
    if(inv.revoked_at)throw new Error("Invite is revoked");
    if(new Date(inv.expires_at)<=new Date())throw new Error("Invite is expired");

    const redirect=`https://ctod.vercel.app/invite?token=${encodeURIComponent(inv.token)}`;
    const {data:list,error:le}=await admin.auth.admin.listUsers({page:1,perPage:1000});
    if(le)throw le;
    const existing=(list.users||[]).some(u=>(u.email||"").toLowerCase()===String(inv.email).toLowerCase());
    if(existing){
      const {error}=await admin.auth.signInWithOtp({email:inv.email,options:{emailRedirectTo:redirect,shouldCreateUser:false}});
      if(error)throw error;
      return out({ok:true,delivery:"magic_link",email:inv.email});
    }
    const {error}=await admin.auth.admin.inviteUserByEmail(inv.email,{redirectTo:redirect,data:{ctod_invite_id:inv.id,ctod_company_id:inv.company_id}});
    if(error)throw error;
    return out({ok:true,delivery:"invite",email:inv.email});
  }catch(e){return out({ok:false,error:e instanceof Error?e.message:String(e)},400)}
});
