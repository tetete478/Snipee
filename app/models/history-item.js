class HistoryItem {
  constructor({
    id = null,
    content = '',
    timestamp = null,
    type = 'history',
    isPinned = false
  } = {}) {
    this.id = id || Date.now().toString();
    this.content = content;
    this.timestamp = timestamp || new Date().toISOString();
    this.type = type;
    this.isPinned = isPinned;
  }
}

module.exports = { HistoryItem };