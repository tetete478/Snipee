/**
 * Snipee 共通ユーティリティ関数
 * 全HTMLファイルで使用する汎用的な関数をまとめています
 */

// ===========================
// HTML エスケープ関連
// ===========================

/**
 * テキストをHTMLエスケープ
 * @param {string} text - エスケープするテキスト
 * @returns {string} エスケープされたテキスト
 */
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/**
 * 属性値用のエスケープ
 * @param {string} text - エスケープするテキスト
 * @returns {string} エスケープされたテキスト
 */
function escapeAttr(text) {
  return text.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

/**
 * HTMLエンティティをデコード
 * @param {string} content - デコードするコンテンツ
 * @returns {string} デコードされたコンテンツ
 */
function decodeHtmlEntities(content) {
  if (typeof content !== 'string') return content;
  
  return content
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}

// ===========================
// データ処理
// ===========================

/**
 * スニペットをフォルダごとにグループ化
 * @param {Array} items - スニペットの配列
 * @returns {Object} フォルダ名をキーとしたオブジェクト
 */
function groupByFolder(items) {
  const folders = {};
  items.forEach(item => {
    const folder = item.folder || '未分類';
    if (!folders[folder]) {
      folders[folder] = [];
    }
    folders[folder].push(item);
  });
  return folders;
}

// ===========================
// サブメニュー管理
// ===========================

/**
 * インラインサブメニューを非表示
 * グローバル変数: isSubmenuOpen, submenuSelectedIndex, submenuItems
 */
function hideInlineSubmenu() {
  const submenu = document.getElementById('inline-submenu');
  if (!submenu) return;
  
  submenu.classList.remove('visible');
  
  // グローバル変数の更新（各ファイルで定義されていることを前提）
  if (typeof isSubmenuOpen !== 'undefined') {
    window.isSubmenuOpen = false;
  }
  if (typeof submenuSelectedIndex !== 'undefined') {
    window.submenuSelectedIndex = 0;
  }
  if (typeof submenuItems !== 'undefined') {
    window.submenuItems = [];
  }
}

/**
 * サブメニューの選択状態を更新
 * グローバル変数: submenuSelectedIndex
 */
function updateSubmenuSelection() {
  const submenuItemElements = document.querySelectorAll('.submenu-item');
  const selectedIdx = typeof submenuSelectedIndex !== 'undefined' ? submenuSelectedIndex : 0;
  
  submenuItemElements.forEach((item, index) => {
    if (index === selectedIdx) {
      item.classList.add('selected');
      item.scrollIntoView({ block: 'nearest', behavior: 'auto' });
    } else {
      item.classList.remove('selected');
    }
  });
}

/**
 * インラインサブメニューを表示（基本版）
 * 各ページで必要に応じてカスタマイズ可能
 * 
 * @param {HTMLElement} targetElement - サブメニューを表示する基準要素
 * @param {Array} items - 表示するアイテムの配列
 * @param {Object} options - オプション設定
 * @param {Function} options.renderItem - アイテムのレンダリング関数
 * @param {Function} options.onSelect - アイテム選択時のコールバック
 */
function showInlineSubmenu(targetElement, items, options = {}) {
  const submenu = document.getElementById('inline-submenu');
  if (!submenu) return;
  
  const bounds = targetElement.getBoundingClientRect();
  const itemHeight = 22;
  const estimatedHeight = items.length * itemHeight;
  const viewportHeight = window.innerHeight;
  const margin = 10;
  
  // サブメニューを上の方から表示
  let top = margin;
  
  // 高さ調整
  if (estimatedHeight > viewportHeight - margin * 2) {
    submenu.style.maxHeight = (viewportHeight - margin * 2) + 'px';
    submenu.style.overflowY = 'auto';
  } else {
    submenu.style.maxHeight = 'none';
    submenu.style.overflowY = 'visible';
  }
  
  submenu.style.left = (bounds.right - 5) + 'px';
  submenu.style.top = top + 'px';
  
  // グローバル変数の更新
  if (typeof submenuItems !== 'undefined') {
    window.submenuItems = items;
  }
  if (typeof submenuSelectedIndex !== 'undefined') {
    window.submenuSelectedIndex = 0;
  }
  if (typeof isSubmenuOpen !== 'undefined') {
    window.isSubmenuOpen = true;
  }
  
  // デフォルトのレンダリング関数
  const defaultRenderItem = (item, index) => {
    const displayText = item.title || item.content || '';
    const truncatedText = displayText.length > 25 ? displayText.substring(0, 25) + '...' : displayText;
    
    return `
      <div class="submenu-item ${index === 0 ? 'selected' : ''}" data-index="${index}">
        <div class="submenu-item-title">📄 ${index + 1}. ${escapeHtml(truncatedText)}</div>
      </div>
    `;
  };
  
  const renderItem = options.renderItem || defaultRenderItem;
  submenu.innerHTML = items.map(renderItem).join('');
  submenu.classList.add('visible');
  
  // イベントリスナーの設定
  if (options.onSelect) {
    submenu.querySelectorAll('.submenu-item').forEach((element, index) => {
      element.addEventListener('click', () => options.onSelect(items[index], index));
    });
  }
}

// ===========================
// キーボード操作ヘルパー
// ===========================

/**
 * 選択可能なアイテムのインデックスを更新
 * @param {number} currentIndex - 現在のインデックス
 * @param {number} direction - 移動方向（1: 下、-1: 上）
 * @param {number} maxLength - アイテムの総数
 * @returns {number} 新しいインデックス
 */
function moveSelection(currentIndex, direction, maxLength) {
  if (direction > 0) {
    return (currentIndex + 1) % maxLength;
  } else {
    return (currentIndex - 1 + maxLength) % maxLength;
  }
}

/**
 * 選択状態を視覚的に更新
 * @param {Array<HTMLElement>} items - 選択可能なアイテムの配列
 * @param {number} selectedIndex - 選択されているインデックス
 */
function updateVisualSelection(items, selectedIndex) {
  items.forEach((item, index) => {
    if (index === selectedIndex) {
      item.classList.add('selected');
      item.scrollIntoView({ block: 'nearest', behavior: 'auto' });
    } else {
      item.classList.remove('selected');
    }
  });
}


// =====================================
// キーボードナビゲーションクラス
// =====================================
class KeyboardNavigator {
  constructor(options = {}) {
    // 状態
    this.selectedIndex = 0;
    this.selectableItems = [];
    this.isSubmenuOpen = false;
    this.submenuSelectedIndex = 0;
    this.submenuItems = [];
    
    // 設定
    this.selectedClass = options.selectedClass || 'selected';
    this.itemSelector = options.itemSelector || '.menu-item, .action-item';
    
    // コールバック
    this.onEscape = options.onEscape || (() => {});
    this.onEnter = options.onEnter || ((item) => item?.click());
    this.onRight = options.onRight || null;
    this.onLeft = options.onLeft || null;
    this.onSubmenuEnter = options.onSubmenuEnter || null;
    this.onNumberKey = options.onNumberKey || null;
    this.onFocusChange = options.onFocusChange || null;
    this.onPinToggle = options.onPinToggle || null;
    
    
    // 入力中の無効化
    this.disableOnInput = options.disableOnInput !== false;
  }
  
  // アイテム更新
  updateItems(selector) {
    if (selector) this.itemSelector = selector;
    this.selectableItems = Array.from(document.querySelectorAll(this.itemSelector));
    this.selectedIndex = Math.min(this.selectedIndex, this.selectableItems.length - 1);
    if (this.selectedIndex < 0) this.selectedIndex = 0;
    this.updateVisual();
  }
  
  // 上に移動
  moveUp() {
    if (this.selectableItems.length === 0) return;
    this.selectedIndex = (this.selectedIndex - 1 + this.selectableItems.length) % this.selectableItems.length;
    this.updateVisual();
    if (this.onFocusChange) this.onFocusChange(this.getSelectedItem());
  }
  
  // 下に移動
  moveDown() {
    if (this.selectableItems.length === 0) return;
    this.selectedIndex = (this.selectedIndex + 1) % this.selectableItems.length;
    this.updateVisual();
    if (this.onFocusChange) this.onFocusChange(this.getSelectedItem());
  }

  // 視覚的更新
  updateVisual() {
    this.selectableItems.forEach(item => item.classList.remove(this.selectedClass));
    const current = this.selectableItems[this.selectedIndex];
    if (current) {
      current.classList.add(this.selectedClass);
      current.scrollIntoView({ block: 'nearest', behavior: 'auto' });
    }
  }
  
  // 現在の選択アイテムを取得
  getSelectedItem() {
    return this.selectableItems[this.selectedIndex] || null;
  }
  
  // サブメニュー開く
  openSubmenu(items) {
    this.isSubmenuOpen = true;
    this.submenuItems = items;
    this.submenuSelectedIndex = 0;
  }
  
  // サブメニュー閉じる
  closeSubmenu() {
    this.isSubmenuOpen = false;
    this.submenuItems = [];
    this.submenuSelectedIndex = 0;
  }
  
  // サブメニュー上に移動
  submenuMoveUp() {
    if (this.submenuItems.length === 0) return;
    this.submenuSelectedIndex = (this.submenuSelectedIndex - 1 + this.submenuItems.length) % this.submenuItems.length;
  }
  
  // サブメニュー下に移動
  submenuMoveDown() {
    if (this.submenuItems.length === 0) return;
    this.submenuSelectedIndex = (this.submenuSelectedIndex + 1) % this.submenuItems.length;
  }
  
  // サブメニューの選択アイテムを取得
  getSubmenuSelectedItem() {
    return this.submenuItems[this.submenuSelectedIndex] || null;
  }

  // サブメニューの視覚更新
  updateSubmenuVisual() {
    const submenuItemElements = document.querySelectorAll('.submenu-item');
    submenuItemElements.forEach((item, index) => {
      if (index === this.submenuSelectedIndex) {
        item.classList.add('selected');
        item.scrollIntoView({ block: 'nearest', behavior: 'auto' });
      } else {
        item.classList.remove('selected');
      }
    });
  }
  
  // キーイベント処理
  handleKeyDown(e) {
    // 入力中は無効化（Escは除く）
    if (this.disableOnInput && e.key !== 'Escape') {
      const active = document.activeElement;
      if (active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA')) {
        if (!active.readOnly) return false;
      }
    }
    
    // Escape
    if (e.key === 'Escape') {
      e.preventDefault();
      this.onEscape();
      return true;
    }
    
    // サブメニューが開いている場合
    if (this.isSubmenuOpen) {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        this.submenuMoveDown();
        this.updateSubmenuVisual();
        return true;
      }
      if (e.key === 'ArrowUp') {
        e.preventDefault();
        this.submenuMoveUp();
        this.updateSubmenuVisual();
        return true;
      }
      if (e.key === 'Enter' && this.onSubmenuEnter) {
        e.preventDefault();
        this.onSubmenuEnter(this.getSubmenuSelectedItem());
        return true;
      }
      if (e.key === 'ArrowLeft' && this.onLeft) {
        e.preventDefault();
        this.onLeft();
        return true;
      }
      // Pキーでピン留めトグル
      if ((e.key === 'p' || e.key === 'P') && this.onPinToggle) {
        e.preventDefault();
        const item = this.getSubmenuSelectedItem();
        if (item && item.type === 'history') {
          this.onPinToggle(item);
        }
        return true;
      }
      return false;
    }
    
    // 数字キー
    if (this.onNumberKey && e.key >= '1' && e.key <= '9') {
      e.preventDefault();
      const index = parseInt(e.key) - 1;
      if (this.selectableItems[index]) {
        this.selectedIndex = index;
        this.updateVisual();
        this.onNumberKey(this.selectableItems[index], index);
      }
      return true;
    }
    
    // 上下移動（メインメニュー）
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      this.moveDown();
      return true;
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault();
      this.moveUp();
      return true;
    }
    
    // Enter
    if (e.key === 'Enter') {
      e.preventDefault();
      this.onEnter(this.getSelectedItem());
      return true;
    }
    
    // 左右
    if (e.key === 'ArrowRight' && this.onRight) {
      e.preventDefault();
      this.onRight();
      return true;
    }
    if (e.key === 'ArrowLeft' && this.onLeft) {
      e.preventDefault();
      this.onLeft();
      return true;
    }
    
    return false;
  }
  
  // イベントリスナー登録
  attach() {
    document.addEventListener('keydown', (e) => this.handleKeyDown(e));
  }

  
}


// ===========================
// サブメニュー設定
// ===========================
const SUBMENU_CONFIG = {
  margin: 10,
  topOffset: 0,
  maxWindowWidth: 460,
  maxWindowHeight: 650
};


