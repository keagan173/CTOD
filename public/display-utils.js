const DATE_ONLY=/^(\d{4})-(\d{2})-(\d{2})$/;

export function displayDate(value){
  if(!value)return null;
  if(value instanceof Date)return Number.isNaN(value.getTime())?null:value;
  const match=typeof value==='string'?value.match(DATE_ONLY):null;
  if(match){
    const date=new Date(Number(match[1]),Number(match[2])-1,Number(match[3]),12);
    return Number.isNaN(date.getTime())?null:date;
  }
  const date=new Date(value);
  return Number.isNaN(date.getTime())?null:date;
}

export function formatDate(value,options){
  const date=displayDate(value);
  return date?date.toLocaleDateString(undefined,options):'';
}

export function calendarDateKey(value){
  const date=displayDate(value);
  if(!date)return'';
  return [date.getFullYear(),String(date.getMonth()+1).padStart(2,'0'),String(date.getDate()).padStart(2,'0')].join('-');
}

export function uniqueGoals(goals=[]){
  const seen=new Set();
  return goals.filter(goal=>{
    const key=[
      goal.employee_id||'',
      String(goal.goal_text||goal.text||'').trim().toLowerCase(),
      calendarDateKey(goal.target_date),
      String(goal.status||'').trim().toLowerCase()
    ].join('|');
    if(seen.has(key))return false;
    seen.add(key);
    return true;
  });
}
