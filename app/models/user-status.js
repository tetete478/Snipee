class UserStatus {
  constructor({
    name = '',
    email = '',
    department = '',
    role = '',
    version = '',
    lastActive = '',
    snippetCount = ''
  } = {}) {
    this.name = name;
    this.email = email;
    this.department = department;
    this.role = role;
    this.version = version;
    this.lastActive = lastActive;
    this.snippetCount = snippetCount;
  }
}

module.exports = { UserStatus };
