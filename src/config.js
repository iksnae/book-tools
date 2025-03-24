const path = require('path');
const fs = require('fs');
const yaml = require('yaml');

/**
 * Load and validate extended configuration settings
 * 
 * @param {Object} config - Base configuration object
 * @returns {Object} - Enhanced configuration with format settings
 */
function loadExtendedConfig(config) {
  // Initialize format settings if not present
  config.formatSettings = config.formatSettings || {};
  
  // PDF configuration
  config.formatSettings.pdf = config.formatSettings.pdf || {};
  config.formatSettings.pdf.paperSize = config.formatSettings.pdf.paperSize || config.pdf?.paper_size || 'letter';
  config.formatSettings.pdf.marginTop = config.formatSettings.pdf.marginTop || config.pdf?.margin_top || '1in';
  config.formatSettings.pdf.marginRight = config.formatSettings.pdf.marginRight || config.pdf?.margin_right || '1in';
  config.formatSettings.pdf.marginBottom = config.formatSettings.pdf.marginBottom || config.pdf?.margin_bottom || '1in';
  config.formatSettings.pdf.marginLeft = config.formatSettings.pdf.marginLeft || config.pdf?.margin_left || '1in';
  config.formatSettings.pdf.fontSize = config.formatSettings.pdf.fontSize || config.pdf?.font_size || '11pt';
  config.formatSettings.pdf.lineHeight = config.formatSettings.pdf.lineHeight || config.pdf?.line_height || '1.5';
  config.formatSettings.pdf.template = config.formatSettings.pdf.template || config.pdf?.template || 'templates/pdf/default.latex';
  
  // EPUB configuration
  config.formatSettings.epub = config.formatSettings.epub || {};
  config.formatSettings.epub.coverImage = config.formatSettings.epub.coverImage || config.epub?.cover_image || 'book/images/cover.png';
  config.formatSettings.epub.css = config.formatSettings.epub.css || config.epub?.css || 'templates/epub/style.css';
  config.formatSettings.epub.tocDepth = config.formatSettings.epub.tocDepth || config.epub?.toc_depth || 3;
  
  // HTML configuration
  config.formatSettings.html = config.formatSettings.html || {};
  config.formatSettings.