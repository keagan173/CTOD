import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.112.2";
const url=Deno.env.get("SUPABASE_URL")!;
const service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin=createClient(url,service,{auth:{persistSession:false,autoRefreshToken:false}});
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, apikey, content-type","Access-Control-Allow-Methods":"POST,OPTIONS"};
const out=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"content-type":"application/json","cache-control":"no-store"}});
Deno.serve(async(req)=>{if(req.method==="OPTIONS")return new Response("ok",{headers:cors});try{
 const jwt=(req.headers.get("authorization")||"").replace(/^Bearer\s+/i,"");
 if(!jwt)throw new Error("Authentication required");
 const {data:who,error:ue}=await admin.auth.getUser(jwt);if(ue||!who.user)throw new Error("Authentication required");
 const {data:op,error:oe}=await admin.schema("private").from("platform_operators").select("operator_role,active").eq("user_id",who.user.id).eq("active",true).maybeSingle();
 if(oe||!op||op.operator_role!=="platform_admin")throw new Error("Platform Owner access required");
 const b=await req.json().catch(()=>({}));const inviteId=String(b.invite_id||"");
 if(!/^[0-9a-f-]{36}$/i.test(inviteId))throw new Error("Valid invite ID required");
 const {data:inv,error:ie}=await admin.from("access_invites").select("id,email,token,expires_at,accepted_at,revoked_at").eq("id",inviteId).maybeSingle();
 if(ie||!inv)throw new Error("Invite not found");
 if(inv.accepted_at)throw new Error("Invite is already accepted");if(inv.revoked_at)throw new Error("Invite is revoked");if(new Date(inv.expires_at)<=new Date())throw new Error("Invite is expired");
 const redirect=`https://ctod.vercel.app/invite?token=${encodeURIComponent(inv.token)}`;
 const {data:list,error:le}=await admin.auth.admin.listUsers({page:1,perPage:1000});if(le)throw le;
 const existing=(list.users||[]).some(u=>(u.email||"").toLowerCase()===String(inv.email).toLowerCase());
 if(existing){const {error}=await admin.auth.signInWithOtp({email:inv.email,options:{emailRedirectTo:redirect,shouldCreateUser:false}});if(error)throw error;return out({ok:true,delivery:"magic_link",email:inv.email});}
 const {error}=await admin.auth.admin.inviteUserByEmail(inv.email,{redirectTo:redirect,data:{ctod_invite_id:inv.id}});if(error)throw error;
 return out({ok:true,delivery:"invite",email:inv.email});
 }catch(e){return out({ok:false,error:e instanceof Error?e.message:String(e)},400)}});
