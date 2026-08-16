import { createClient as realCreateClient } from 'https://esm.sh/@supabase/supabase-js@2?ctod-real=1';
export * from 'https://esm.sh/@supabase/supabase-js@2?ctod-real=1';
const SANDBOX_URL='https://zgwkjyezpgboysiklodj.supabase.co';
const SANDBOX_KEY='sb_publishable_sWjR6yZoedl3q2vYzvRtRg_Pw1Jtuu7';
export function createClient(_url,_key,options){
  const client=realCreateClient(SANDBOX_URL,SANDBOX_KEY,options);
  try{window.__ctodSandboxDatabase={projectRef:'zgwkjyezpgboysiklodj',url:SANDBOX_URL};}catch{}
  return client;
}
