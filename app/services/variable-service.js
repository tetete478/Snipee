// ========================================
// 変数置換機能
// ========================================

function formatDate(date, format) {
  const month = date.getMonth() + 1;
  const day = date.getDate();
  
  if (format === 'MM/DD') {
    return `${String(month).padStart(2, '0')}/${String(day).padStart(2, '0')}`;
  }
  
  if (format === 'M月D日') {
    return `${month}月${day}日`;
  }
  
  return date.toLocaleDateString('ja-JP');
}

function getWeekdayShort(date) {
  const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
  return `（${weekdays[date.getDay()]}）`;
}

function addDaysExcluding1st(date, days, alternativeDays) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  
  if (result.getDate() === 1) {
    const alternative = new Date(date);
    alternative.setDate(alternative.getDate() + alternativeDays);
    return alternative;
  }
  
  return result;
}

function formatDateWithWeekday(date) {
  return formatDate(date, 'M月D日') + getWeekdayShort(date);
}

function formatTimestamp(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  
  return `${year}/${month}/${day} ${hours}:${minutes}:${seconds}`;
}

function calculateLinkedSchedule(baseDate, baseDays, alternativeDays) {
  const schedule1 = addDaysExcluding1st(baseDate, baseDays, alternativeDays);
  
  const schedule2Base = new Date(schedule1);
  schedule2Base.setDate(schedule2Base.getDate() + 1);
  const schedule2 = schedule2Base.getDate() === 1
    ? new Date(schedule2Base.getFullYear(), schedule2Base.getMonth(), schedule2Base.getDate() + 1)
    : schedule2Base;
  
  return [schedule1, schedule2];
}

function replaceVariables(text, store) {
  const now = new Date();
  const userName = store.get('userName', '');
  
  // {名前} / {name}
  text = text.replace(/\{名前\}/g, userName);
  text = text.replace(/\{name\}/g, userName);
  
  // {日付} / {date} - YYYY/MM/DD
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const dateStr = `${year}/${month}/${day}`;
  text = text.replace(/\{日付\}/g, dateStr);
  text = text.replace(/\{date\}/g, dateStr);
  
  // {年} {月} {日}
  text = text.replace(/\{年\}/g, String(now.getFullYear()));
  text = text.replace(/\{月\}/g, String(now.getMonth() + 1));
  text = text.replace(/\{日\}/g, String(now.getDate()));
  
  // {時刻} / {time} - HH:mm
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const timeStr = `${hours}:${minutes}`;
  text = text.replace(/\{時刻\}/g, timeStr);
  text = text.replace(/\{time\}/g, timeStr);
  
  // {曜日}
  const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
  text = text.replace(/\{曜日\}/g, weekdays[now.getDay()]);
  
  // {明日} - YYYY/MM/DD
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tYear = tomorrow.getFullYear();
  const tMonth = String(tomorrow.getMonth() + 1).padStart(2, '0');
  const tDay = String(tomorrow.getDate()).padStart(2, '0');
  text = text.replace(/\{明日\}/g, `${tYear}/${tMonth}/${tDay}`);
  
  // {明後日} - YYYY/MM/DD
  const dayAfter = new Date(now);
  dayAfter.setDate(dayAfter.getDate() + 2);
  const daYear = dayAfter.getFullYear();
  const daMonth = String(dayAfter.getMonth() + 1).padStart(2, '0');
  const daDay = String(dayAfter.getDate()).padStart(2, '0');
  text = text.replace(/\{明後日\}/g, `${daYear}/${daMonth}/${daDay}`);
  
  // {今日:MM/DD}
  text = text.replace(/\{今日:MM\/DD\}/g, formatDate(now, 'MM/DD'));
  
  // {明日:MM/DD}
  text = text.replace(/\{明日:MM\/DD\}/g, formatDate(tomorrow, 'MM/DD'));
  
  // {タイムスタンプ}
  text = text.replace(/\{タイムスタンプ\}/g, formatTimestamp(now));
  
  // 連動ペアA: 当日 & 1日後
  const [schedA1, schedA2] = calculateLinkedSchedule(now, 0, 1);
  text = text.replace(
    /\{当日:M月D日:曜日短（毎月1日は除外して翌日）\}/g,
    formatDateWithWeekday(schedA1)
  );
  text = text.replace(
    /\{1日後:M月D日:曜日短（毎月1日は除外して2日後）\}/g,
    formatDateWithWeekday(schedA2)
  );
  
  // 連動ペアB: 1日後 & 2日後
  const [schedB1, schedB2] = calculateLinkedSchedule(now, 1, 2);
  text = text.replace(
    /\{1日後:M月D日:曜日短（毎月1日は除外して2日後）\}/g,
    formatDateWithWeekday(schedB1)
  );
  text = text.replace(
    /\{2日後:M月D日:曜日短（毎月1日は除外して3日後）\}/g,
    formatDateWithWeekday(schedB2)
  );
  
  // 連動ペアC: 2日後 & 3日後
  const [schedC1, schedC2] = calculateLinkedSchedule(now, 2, 3);
  text = text.replace(
    /\{2日後:M月D日:曜日短（毎月1日は除外して3日後）\}/g,
    formatDateWithWeekday(schedC1)
  );
  text = text.replace(
    /\{3日後:M月D日:曜日短（毎月1日は除外して4日後）\}/g,
    formatDateWithWeekday(schedC2)
  );
  
  return text;
}

module.exports = {
  formatDate,
  getWeekdayShort,
  addDaysExcluding1st,
  calculateLinkedSchedule,
  formatDateWithWeekday,
  formatTimestamp,
  replaceVariables
};
