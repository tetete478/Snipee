const MemberRole = {
  GENERAL: '一般',
  ADMIN: '管理者',
  SUPER_ADMIN: '最高管理者'
};

class Member {
  constructor({
    name = '',
    email = '',
    departments = [],
    role = MemberRole.GENERAL
  } = {}) {
    this.name = name;
    this.email = email;
    this.departments = departments;
    this.role = role;
  }

  get isAdmin() {
    return this.role === MemberRole.ADMIN || this.role === MemberRole.SUPER_ADMIN;
  }

  get isSuperAdmin() {
    return this.role === MemberRole.SUPER_ADMIN;
  }
}

module.exports = { Member, MemberRole };