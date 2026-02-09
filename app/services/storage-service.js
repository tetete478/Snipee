const Store = require('electron-store');

const store = new Store();
const personalStore = new Store({ name: 'personal-snippets' });

module.exports = { store, personalStore };