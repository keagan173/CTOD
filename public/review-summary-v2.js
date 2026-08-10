import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const sbSummary=createClient('https://wezcuprboyvbmlnuqdoi.supabase.co','sb_publishable_BFhSdHnbppOmw98ons8iSw_MtkOnRg5');
const escS=s=>String(s??'').replace(/[&<>\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));
const fmtS=d=>d?new Date(d).toLocaleDateString():'';
const clean=s=>String(s||'').trim();
const REVIEW_SUMMARY_VERSION='20260809-1818';
const REVIEW_LOGO=`/branding/ctod-logo-1-primary.svg?v=${REVIEW_SUMMARY_VERSION}`;

const PRINT_CSS=`
*{box-sizing:border-box}html,body{margin:0;padding:0;background:#fff;color:#161616;font-family:Arial,Helvetica,sans-serif;-webkit-print-color-adjust:exact;print-color-adjust:exact}.review-print-page{position:relative;background:#fff;color:#161616;padding:.38in .46in;width:8.5in;height:11in;overflow:hidden;page-break-after:always;break-after:page}.review-print-page:last-child{page-break-after:auto;break-after:auto}.review-print-head{display:flex;justify-content:space-between;gap:18px;align-items:center;border-bottom:3px solid #c99a24;padding-bottom:12px;margin-bottom:14px}.review-print-brand{display:flex;align-items:center;gap:12px}.review-print-brand img{width:190px;max-height:62px;object-fit:contain;object-position:left center}.review-print-kicker{font-size:10px;font-weight:900;letter-spacing:.12em;color:#8b6716;text-transform:uppercase}.review-print-title{font-size:24px;font-weight:900;margin:2px 0}.review-print-meta{font-size:12px;color:#555;line-height:1.45;text-align:right}.review-print-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin:10px 0 14px}.review-print-stat{border:1px solid #e0d1a8;border-radius:10px;padding:9px;background:#fffaf0}.review-print-stat small{display:block;text-transform:uppercase;letter-spacing:.06em;color:#806420;font-weight:850;font-size:9px}.review-print-stat strong{display:block;font-size:15px;margin-top:3px}.review-print-section{margin:12px 0}.review-print-section h2{font-size:14px;text-transform:uppercase;letter-spacing:.08em;margin:0 0 7px;padding-bottom:5px;border-bottom:1px solid #dfc980;color:#72530d}.review-print-item{padding:7px 0;border-bottom:1px solid #eee;font-size:11px;line-height:1.35}.review-print-item:last-child{border-bottom:0}.review-print-item strong{font-size:11px}.review-print-note{color:#555;margin-top:3px}.review-print-two{display:grid;grid-template-columns:1fr 1fr;gap:16px}.review-print-pill{display:inline-block;padding:3px 7px;border-radius:999px;background:#f4ead0;color:#694c0d;font-size:10px;font-weight:850}.review-print-risk{background:#fde9e6;color:#8e2b20}.review-print-good{background:#e7f4e9;color:#23623b}.review-print-signatures{display:grid;grid-template-columns:1fr 1fr;gap:28px;margin-top:44px}.review-print-sig{border-top:1px solid #222;padding-top:5px;font-size:10px}.review-print-footer{position:absolute;left:.46in;right:.46in;bottom:.25in;display:flex;justify-content:space-between;color:#777;font-size:9px}@page{size:Letter portrait;margin:0}`;

function installSummaryStyles(){
 if(document.querySelector('#reviewSummaryV2Styles'))return;
 const s=document.createElement('style');s.id='reviewSummaryV2Styles';s.textContent=`
 #printPage.review-summary-v2{display:none;background:#fff;color:#151515;font-family:Inter,Arial,sans-serif}
 #printPage.review-summary-v2 .review-print-page{position:relative;background:#fff;color:#161616;padding:.38in .46in;margin:12px auto;width:8.5in;min-height:11in;border:1px solid #ddd;box-shadow:0 8px 30px rgba(0,0,0,.12)}
 ${PRINT_CSS.replace('@page{size:Letter portrait;margin:0}','')}
 .review-print-actions{display:flex;gap:10px;justify-content:center;margin:16px auto;max-width:8.5in}
 @media print{html,body{margin:0!important;padding:0!important;background:#fff!important}.shell>*{display:none!important}#printPage.review-summary-v2{display:block!important;position:static!important;margin:0!important;padding:0!important}.shell{display:block!important;max-width:none!important;padding:0!important;margin:0!important}.review-print-page{display:block!important;margin:0!important;border:0!important;box-shadow:none!important;width:8.5in!important;height:11in!important;min-height:11in!important;overflow:hidden!important;page-break-after:always!important;break-after:page!important}.review-print-page:last-of-type{page-break-after:auto!important;break-after:auto!important}.review-print-actions{display:none!important}@page{size:Letter portrait;margin:0}}
 `;document.head.appendChild(s);
}

function ratingMap(form){return new Map((form.ratings||[]).map(x=>[x.id,x]))}
function reasonMap(form){return new Map((form.reasons||[]).map(x=>[x.id,x]))}
function answerRows(form){const rm=ratingMap(form),xm=reasonMap(form);return (form.questions||[]).filter(q=>q.answer).map(q=>{const r=rm.get(q.answer.rating_id),reason=xm.get(q.answer.primary_reason_id);return{section:q.section||q.section_name||'Performance',question:q.text||q.question_text||'',rating:r?.label||'Not rated',score:Number(r?.score_value||0),reason:reason?.label||'',note:q.answer.manager_note||''}})}
function listHtml(items,empty){return items.length?items.map(x=>`<div class="review-print-item"><strong>${escS(x.question)}</strong><div><span class="review-print-pill ${x.score<=2?'review-print-risk':x.score>=4?'review-print-good':''}">${escS(x.rating)}</span>${x.reason?` &nbsp; ${escS(x.reason)}`:''}</div>${x.note?`<div class="review-print-note">${escS(x.note)}</div>`:''}</div>`).join(''):`<div class="review-print-item review-print-note">${escS(empty)}</div>`}
function goalHtml(goals){return goals.length?goals.map(g=>`<div class="review-print-item"><strong>${escS(g.goal_text||g.text||'Goal')}</strong>${g.target_date?`<div class="review-print-note">Target: ${escS(fmtS(g.target_date))}</div>`:''}</div>`).join(''):'<div class="review-print-item review-print-note">No goals recorded.</div>'}
function coachingHtml(items){return items.length?items.map(c=>`<div class="review-print-item"><strong>${escS(c.category||'Coaching')}</strong> <span class="review-print-pill ${String(c.type).toLowerCase()==='corrective'?'review-print-risk':''}">${escS(c.type||'')}</span><div class="review-print-note">${escS(c.notes||'')}</div></div>`).join(''):'<div class="review-print-item review-print-note">No coaching items included in this review.</div>'}

async function locateReviewFromDetail(){
 const detail=document.querySelector('#reviewDetail');if(!detail)throw new Error('Open a finalized review first.');
 const name=clean(detail.querySelector('h3')?.textContent);const meta=clean(detail.querySelector('.meta')?.textContent);if(!name)throw new Error('Could not identify the finalized review.');
 const loc=(meta.match(/Location\s+(\d+)/i)||[])[1];const finalized=(meta.match(/Finalized\s+([^•]+)/i)||[])[1]?.trim();
 const [first,...rest]=name.split(/\s+/);const last=rest.join(' ');
 const r=await sbSummary.from('reviews').select('id,review_date,finalized_at,status,location_id,employees!reviews_employee_id_fkey(first_name,last_name),locations(location_code)').eq('status','finalized').order('finalized_at',{ascending:false}).limit(100);if(r.error)throw r.error;
 let rows=r.data||[];rows=rows.filter(x=>clean(`${x.employees?.first_name||''} ${x.employees?.last_name||''}`)===name);
 if(loc)rows=rows.filter(x=>String(x.locations?.location_code||'').padStart(3,'0')===String(loc).padStart(3,'0'));
 if(finalized){const target=new Date(finalized).toLocaleDateString();const exact=rows.find(x=>new Date(x.review_date||x.finalized_at).toLocaleDateString()===target);if(exact)return exact.id}
 if(rows[0])return rows[0].id;
 throw new Error(`Could not locate ${first}${last?' '+last:''}'s finalized review.`)
}

async function loadSummaryData(reviewId){
 const [form,coaching]=await Promise.all([sbSummary.rpc('get_review_form',{p_review_id:reviewId}),sbSummary.rpc('get_review_coaching_items',{p_review_id:reviewId})]);
 if(form.error)throw form.error;
 return{form:form.data,coaching:coaching.error?[]:(coaching.data||[])}
}

function careerText(c){const d=c?.career_direction;const dir={ADVANCEMENT:'Advancement / another position',CURRENT_ROLE:'Satisfied in current position',SPECIALIST:'Specialist / technical career path',EXPLORING:'Still exploring career direction'}[d]||d||'Not set';return{dir,reason:c?.career_direction_reason||'',readiness:c?.promotion_readiness||'Not set'}}

function buildPages(form,coaching){
 const answers=answerRows(form),strengths=answers.filter(x=>x.score>=4),development=answers.filter(x=>x.score>0&&x.score<=2),career=careerText(form.career||{}),goals=form.goals||[],summary=form.summary||{},review=form.review||{},employee=form.employee||{};
 const nextRole=form.career?.desired_role||form.career?.desired_role_title||'Not set',finalRole=form.career?.final_desired_role||form.career?.final_desired_role_title||'Not set';
 return `<div class="review-print-page"><div class="review-print-head"><div class="review-print-brand"><img src="${REVIEW_LOGO}" alt="CTOD"><div><div class="review-print-kicker">Building People. Driving Performance.</div><div class="review-print-title">Employee Review Summary</div></div></div><div class="review-print-meta"><strong>${escS(employee.name||'Employee')}</strong><br>${escS(employee.role||'')}<br>Location ${escS(employee.location_code||'')}</div></div><div class="review-print-grid"><div class="review-print-stat"><small>Review Date</small><strong>${escS(fmtS(review.review_date||review.finalized_at))}</strong></div><div class="review-print-stat"><small>Overall Rating</small><strong>${escS(review.overall_rating_label||'Completed')}</strong></div><div class="review-print-stat"><small>Promotion Readiness</small><strong>${escS(career.readiness)}</strong></div><div class="review-print-stat"><small>Next Review</small><strong>${escS(fmtS(review.next_review_date))}</strong></div></div><div class="review-print-two"><section class="review-print-section"><h2>Key Strengths</h2>${listHtml(strengths,'No specific high-rating strengths were flagged.')}</section><section class="review-print-section"><h2>Development Areas</h2>${listHtml(development,'No critical development areas were flagged.')}</section></div><section class="review-print-section"><h2>Performance Detail</h2>${listHtml(answers,'No rated review questions were found.')}</section><div class="review-print-footer"><span>CTOD • Confidential Employee Development Record</span><span>Page 1 of 2</span></div></div><div class="review-print-page"><div class="review-print-head"><div class="review-print-brand"><img src="${REVIEW_LOGO}" alt="CTOD"><div><div class="review-print-kicker">Development & Career</div><div class="review-print-title">Growth Plan & Acknowledgment</div></div></div><div class="review-print-meta"><strong>${escS(employee.name||'Employee')}</strong><br>#${escS(employee.employee_code||'')}<br>${escS(employee.role||'')}</div></div><div class="review-print-two"><section class="review-print-section"><h2>Career Direction</h2><div class="review-print-item"><strong>${escS(career.dir)}</strong>${career.reason?`<div class="review-print-note">${escS(career.reason)}</div>`:''}</div><div class="review-print-item"><strong>Next position:</strong> ${escS(nextRole)}</div><div class="review-print-item"><strong>10-year / final position:</strong> ${escS(finalRole)}</div><div class="review-print-item"><strong>Promotion readiness:</strong> ${escS(career.readiness)}</div></section><section class="review-print-section"><h2>Manager Summary</h2><div class="review-print-item">${escS(summary.manager_summary||'No manager summary recorded.')}</div><h2 style="margin-top:12px">Employee Comments</h2><div class="review-print-item">${escS(summary.employee_comments||'No employee comments recorded.')}</div></section></div><div class="review-print-two"><section class="review-print-section"><h2>Goals</h2>${goalHtml(goals)}</section><section class="review-print-section"><h2>Coaching Included</h2>${coachingHtml(coaching.filter(x=>x.included_on_summary!==false&&x.include_in_review!==false))}</section></div><section class="review-print-section"><h2>Acknowledgment</h2><div class="review-print-item">Employee acknowledgment confirms the review was discussed. Signature does not necessarily indicate agreement with every rating or comment.</div></section><div class="review-print-signatures"><div class="review-print-sig">Employee Signature / Date</div><div class="review-print-sig">Manager Signature / Date</div></div><div class="review-print-footer"><span>CTOD • Confidential Employee Development Record</span><span>Page 2 of 2</span></div></div>`;
}

function printStandalone(pagesHtml){
 const frame=document.createElement('iframe');frame.setAttribute('aria-hidden','true');frame.style.position='fixed';frame.style.right='0';frame.style.bottom='0';frame.style.width='1px';frame.style.height='1px';frame.style.border='0';frame.style.opacity='0';document.body.appendChild(frame);
 const doc=frame.contentDocument;doc.open();doc.write(`<!doctype html><html><head><meta charset="utf-8"><title>CTOD Employee Review Summary</title><style>${PRINT_CSS}</style></head><body>${pagesHtml}</body></html>`);doc.close();
 const run=()=>{try{frame.contentWindow.focus();frame.contentWindow.print()}finally{setTimeout(()=>frame.remove(),1500)}};
 const images=[...doc.images];if(!images.length){setTimeout(run,100);return}let pending=images.length;const done=()=>{pending--;if(pending<=0)setTimeout(run,120)};images.forEach(img=>{if(img.complete)done();else{img.onload=done;img.onerror=done}});setTimeout(()=>{if(document.body.contains(frame))run()},1800);
}

function renderSummary(reviewId,form,coaching){
 installSummaryStyles();const host=document.querySelector('#printPage');if(!host)throw new Error('Print workspace is unavailable.');
 const pages=buildPages(form,coaching);host.className='printpage review-summary-v2';host.innerHTML=`${pages}<div class="review-print-actions"><button id="doPrintV2" class="btn primary">Print / Save PDF</button><button id="backPrintV2" class="btn secondary">Back to Review</button></div>`;
 const app=document.querySelector('#app');if(app)app.hidden=true;host.style.display='block';
 document.querySelector('#doPrintV2').onclick=()=>printStandalone(pages);document.querySelector('#backPrintV2').onclick=()=>{host.style.display='none';host.innerHTML='';host.className='printpage';if(app)app.hidden=false};
}

async function generateTwoPageSummary(){
 const btn=document.querySelector('#previewSummary');if(btn){btn.disabled=true;btn.textContent='Generating Summary...'}
 try{const reviewId=await locateReviewFromDetail();const {form,coaching}=await loadSummaryData(reviewId);renderSummary(reviewId,form,coaching)}catch(e){alert(`Review summary could not be generated: ${e.message||e}`)}finally{if(btn){btn.disabled=false;btn.textContent='Print 2-Page Review Summary'}}
}

document.addEventListener('click',e=>{const b=e.target.closest('#previewSummary');if(!b)return;e.preventDefault();e.stopImmediatePropagation();generateTwoPageSummary()},{capture:true});
installSummaryStyles();
