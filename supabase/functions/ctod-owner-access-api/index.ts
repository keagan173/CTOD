import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2.112.2";

const url=Deno.env.get("SUPABASE_URL")!;
const service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin=createClient(url,service,{auth:{persistSession:false,autoRefreshToken:false}});
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, apikey, content-type","Access-Control-Allow-Methods":"POST,OPTIONS"};
const out=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"content-type":"application/json","cache-control":"no-store"}});
function claims(jwt:string){try{let s=jwt.split('.')[1].replace(/-/g,'+').replace(/_/g,'/');while(s.length%4)s+='=';return JSON.parse(atob(s))}catch{return {}}}
const uuid=(v:unknown)=>{const s=String(v||"");if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(s))throw new Error("Invalid ID");return s};
const uuids=(v:unknown)=>Array.isArray(v)?v.map(uuid):[];

async function requireOwner(req:Request){
  const jwt=(req.headers.get("authorization")||"").replace(/^Bearer\s+/i,"");
  if(!jwt)throw new Error("Authentication required");
  if(claims(jwt).aal!=="aal2")throw new Error("MFA verification required. Complete two-factor authentication before using the Platform Owner Console.");
  const {data,error}=await admin.auth.getUser(jwt);
  if(error||!data.user)throw new Error("Authentication required");
  const gate=await admin.rpc("operator_service_dashboard",{p_actor_user_id:data.user.id});
  if(gate.error)throw new Error("Platform Owner access required");
  return data.user;
}

Deno.serve(async(req:Request)=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
  try{
    const user=await requireOwner(req);
    const body=await req.json().catch(()=>({}));
    const action=String(body.action||"list");
    const companyId=uuid(body.company_id);

    if(action==="list"){
      const {data,error}=await admin.rpc("operator_service_list_customer_access",{p_actor_user_id:user.id,p_company_id:companyId});
      if(error)throw error;
      return out({ok:true,users:data||[]});
    }

    if(action==="update"){
      const role=String(body.role||"");
      if(!["manager","market_leader","area_leader","executive","viewer"].includes(role))throw new Error("Unsupported access role");
      const {data,error}=await admin.rpc("operator_service_update_customer_user_access",{
        p_actor_user_id:user.id,
        p_company_id:companyId,
        p_user_id:uuid(body.user_id),
        p_role:role,
        p_location_ids:uuids(body.location_ids),
        p_request_id:crypto.randomUUID()
      });
      if(error)throw error;
      return out({ok:true,result:data});
    }

    return out({ok:false,error:"Unknown action"},404);
  }catch(e){
    return out({ok:false,error:e instanceof Error?e.message:String(e)},400);
  }
});
