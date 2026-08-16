function publish(){const p=document.querySelector('#ctodUnifiedCareerVoiceV4');if(p?.dataset?.reviewId)window.ctodCurrentReviewId=p.dataset.reviewId}
function burst(){[50,140,300,600,1000].forEach(ms=>setTimeout(publish,ms))}
document.addEventListener('click',e=>{if(e.target.closest('.review,#tabReviews,#saveReviewDraft,#finalizeCurrentReview'))burst()},true);
document.addEventListener('ctod:workspace-ready',burst);
burst();
