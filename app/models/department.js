class Department {
  constructor({
    id = null,
    name = '',
    xmlFileId = ''
  } = {}) {
    this.id = id || Date.now().toString();
    this.name = name;
    this.xmlFileId = xmlFileId;
  }
}

module.exports = { Department };