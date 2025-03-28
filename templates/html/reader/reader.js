/**
 * Enhanced eBook Reader for book-tools
 * 
 * This script provides a customizable reading experience with controls
 * for font size, font family, theme, line height, and margin width.
 * 
 * Settings are saved to localStorage for persistence between sessions.
 */

class EbookReader {
  constructor() {
    // Initialize DOM elements
    this.container = document.querySelector('.reader-container');
    this.controlsPanel = document.querySelector('.reader-controls');
    this.toggleButton = document.querySelector('#toggle-controls');
    this.closeButton = document.querySelector('#close-controls');
    this.fontSizeDisplay = document.querySelector('.font-size-display');
    
    // Initialize settings with defaults or from localStorage
    this.settings = this.loadSettings() || {
      fontSize: 18,
      fontFamily: "'Libre Baskerville', Georgia, serif",
      theme: 'light',
      lineHeight: 1.6,
      marginWidth: 15
    };
    
    // Initialize event listeners and apply settings
    this.initEventListeners();
    this.applySettings();
  }
  
  /**
   * Initialize all event listeners for controls
   */
  initEventListeners() {
    // Toggle controls visibility
    this.toggleButton.addEventListener('click', () => {
      this.controlsPanel.classList.toggle('visible');
    });
    
    // Close controls
    this.closeButton.addEventListener('click', () => {
      this.controlsPanel.classList.remove('visible');
    });
    
    // Font size controls
    document.querySelector('#font-size-smaller').addEventListener('click', () => {
      this.settings.fontSize = Math.max(12, this.settings.fontSize - 2);
      this.updateFontSizeDisplay();
      this.applySettings();
    });
    
    document.querySelector('#font-size-larger').addEventListener('click', () => {
      this.settings.fontSize = Math.min(32, this.settings.fontSize + 2);
      this.updateFontSizeDisplay();
      this.applySettings();
    });
    
    // Font family control
    document.querySelector('#font-family-control').addEventListener('change', (e) => {
      this.settings.fontFamily = e.target.value;
      this.applySettings();
    });
    
    // Theme controls
    const themeButtons = document.querySelectorAll('.theme-button');
    themeButtons.forEach(button => {
      button.addEventListener('click', () => {
        this.settings.theme = button.dataset.theme;
        this.updateThemeButtons();
        this.applySettings();
      });
    });
    
    // Line height control
    document.querySelector('#line-height-control').addEventListener('input', (e) => {
      this.settings.lineHeight = parseFloat(e.target.value);
      this.applySettings();
    });
    
    // Margin width control
    document.querySelector('#margin-width-control').addEventListener('input', (e) => {
      this.settings.marginWidth = parseInt(e.target.value);
      this.applySettings();
    });
    
    // Initialize form controls with current settings
    document.querySelector('#font-family-control').value = this.settings.fontFamily;
    document.querySelector('#line-height-control').value = this.settings.lineHeight;
    document.querySelector('#margin-width-control').value = this.settings.marginWidth;
    this.updateFontSizeDisplay();
    this.updateThemeButtons();
  }
  
  /**
   * Update the font size display
   */
  updateFontSizeDisplay() {
    this.fontSizeDisplay.textContent = `${this.settings.fontSize}px`;
  }
  
  /**
   * Update active state on theme buttons
   */
  updateThemeButtons() {
    document.querySelectorAll('.theme-button').forEach(button => {
      button.classList.toggle('active', button.dataset.theme === this.settings.theme);
    });
  }
  
  /**
   * Apply all settings to the document
   */
  applySettings() {
    // Apply font size
    document.documentElement.style.setProperty('--reader-font-size', `${this.settings.fontSize}px`);
    
    // Apply font family
    document.documentElement.style.setProperty('--reader-font-family', this.settings.fontFamily);
    
    // Apply theme
    document.body.classList.remove('theme-light', 'theme-sepia', 'theme-dark');
    document.body.classList.add(`theme-${this.settings.theme}`);
    
    // Apply line height
    document.documentElement.style.setProperty('--reader-line-height', this.settings.lineHeight);
    
    // Apply margin width
    document.documentElement.style.setProperty('--reader-margin-width', `${this.settings.marginWidth}%`);
    
    // Save settings to localStorage
    this.saveSettings();
  }
  
  /**
   * Save settings to localStorage
   */
  saveSettings() {
    try {
      localStorage.setItem('reader-settings', JSON.stringify(this.settings));
    } catch (e) {
      console.warn('Could not save reader settings to localStorage:', e);
    }
  }
  
  /**
   * Load settings from localStorage
   * 
   * @returns {Object|null} The saved settings or null if not found
   */
  loadSettings() {
    try {
      const savedSettings = localStorage.getItem('reader-settings');
      return savedSettings ? JSON.parse(savedSettings) : null;
    } catch (e) {
      console.warn('Could not load reader settings from localStorage:', e);
      return null;
    }
  }
}

/**
 * When DOM is loaded, initialize the reader
 */
document.addEventListener('DOMContentLoaded', () => {
  const reader = new EbookReader();
  
  // Add keyboard shortcuts
  document.addEventListener('keydown', (e) => {
    // Toggle controls with 'c' key
    if (e.key === 'c') {
      document.querySelector('.reader-controls').classList.toggle('visible');
    }
    
    // Escape key closes controls
    if (e.key === 'Escape') {
      document.querySelector('.reader-controls').classList.remove('visible');
    }
  });
});
