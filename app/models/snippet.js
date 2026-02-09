const SnippetType = {
  PERSONAL: 'personal',
  MASTER: 'master'
};

class Snippet {
  constructor({
    id = null,
    title = '',
    content = '',
    folder = '',
    type = SnippetType.PERSONAL,
    description = '',
    order = 0,
    department = null
  } = {}) {
    this.id = id || this.generateId(folder, title, content);
    this.title = title;
    this.content = content;
    this.folder = folder;
    this.type = type;
    this.description = description;
    this.order = order;
    this.department = department;
  }

  generateId(folder, title, content) {
    const base = `${folder}_${title}_${content.substring(0, 100)}`;
    let hash = 0;
    for (let i = 0; i < base.length; i++) {
      hash = ((hash << 5) - hash) + base.charCodeAt(i);
      hash = hash & hash;
    }
    return `snippet_${Math.abs(hash).toString(36)}`;
  }
}

class SnippetFolder {
  constructor({
    id = null,
    name = '',
    snippets = [],
    order = 0
  } = {}) {
    this.id = id || Date.now().toString();
    this.name = name;
    this.snippets = snippets;
    this.order = order;
  }
}

module.exports = { Snippet, SnippetFolder, SnippetType };