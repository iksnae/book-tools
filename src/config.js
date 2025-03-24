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
  config.formatSettings.html.template = config.formatSettings.html.template || config.html?.template || 'templates/html/default.html';
  config.formatSettings.html.css = config.formatSettings.html.css || config.html?.css || 'templates/html/style.css';
  config.formatSettings.html.toc = config.formatSettings.html.toc !== undefined ? config.formatSettings.html.toc : config.html?.toc !== false;
  config.formatSettings.html.tocDepth = config.formatSettings.html.tocDepth || config.html?.toc_depth || 3;
  config.formatSettings.html.sectionDivs = config.formatSettings.html.sectionDivs || config.html?.section_divs || true;
  config.formatSettings.html.selfContained = config.formatSettings.html.selfContained || config.html?.self_contained || true;
  
  // MOBI configuration - minimal for now
  config.formatSettings.mobi = config.formatSettings.mobi || {};
  
  return config;
}

/**
 * Convert book-template config format to book-tools format
 * 
 * @param {Object} legacyConfig - Configuration in book-template format
 * @returns {Object} - Configuration in book-tools format
 */
function convertLegacyConfig(legacyConfig) {
  const newConfig = {
    title: legacyConfig.title || 'Untitled Book',
    subtitle: legacyConfig.subtitle || '',
    author: legacyConfig.author || 'Unknown Author',
    filePrefix: legacyConfig.file_prefix || 'book',
    
    // Handle languages array
    languages: Array.isArray(legacyConfig.languages) 
      ? legacyConfig.languages 
      : (legacyConfig.language ? [legacyConfig.language] : ['en']),
    
    // Format configurations
    formats: {
      pdf: legacyConfig.outputs?.pdf !== false,
      epub: legacyConfig.outputs?.epub !== false,
      mobi: legacyConfig.outputs?.mobi !== false,
      html: legacyConfig.outputs?.html !== false
    },
    
    // Pass format-specific settings to be processed by loadExtendedConfig
    pdf: legacyConfig.pdf || {},
    epub: legacyConfig.epub || {},
    html: legacyConfig.html || {},
    
    // Metadata
    metadata: {
      publisher: legacyConfig.publisher || '',
      year: legacyConfig.year || new Date().getFullYear().toString(),
      rights: legacyConfig.metadata?.rights || `Copyright © ${new Date().getFullYear()}`,
      description: legacyConfig.metadata?.description || '',
      subject: legacyConfig.metadata?.subject || '',
      keywords: legacyConfig.metadata?.keywords || ''
    }
  };
  
  return loadExtendedConfig(newConfig);
}

/**
 * Detect config format and load appropriately
 * 
 * @param {string} configPath - Path to configuration file
 * @returns {Object} - Normalized configuration
 */
function loadConfig(configPath) {
  if (!fs.existsSync(configPath)) {
    return getDefaultConfig();
  }
  
  try {
    const configContent = fs.readFileSync(configPath, 'utf-8');
    const rawConfig = yaml.parse(configContent);
    
    // Check if it's legacy format (has file_prefix or outputs)
    const isLegacyFormat = rawConfig.file_prefix !== undefined || rawConfig.outputs !== undefined;
    
    if (isLegacyFormat) {
      return convertLegacyConfig(rawConfig);
    } else {
      return loadExtendedConfig(rawConfig);
    }
  } catch (error) {
    console.error(`Error loading configuration: ${error.message}`);
    return getDefaultConfig();
  }
}

/**
 * Get default configuration
 * 
 * @returns {Object} - Default configuration
 */
function getDefaultConfig() {
  return loadExtendedConfig({
    title: 'Untitled Book',
    subtitle: '',
    author: 'Unknown Author',
    filePrefix: 'book',
    languages: ['en'],
    formats: {
      pdf: true,
      epub: true,
      mobi: true,
      html: true
    }
  });
}

/**
 * Generate pandoc arguments from config
 * 
 * @param {Object} config - Configuration object
 * @param {string} format - Output format ('pdf', 'epub', 'html')
 * @param {string} language - Language code
 * @returns {Array} - Array of pandoc arguments
 */
function getPandocArgs(config, format, language) {
  const args = [
    '--standalone',
    `--metadata=title:${config.title}`,
    `--metadata=author:${config.author}`
  ];
  
  if (config.subtitle) {
    args.push(`--metadata=subtitle:${config.subtitle}`);
  }
  
  if (config.metadata) {
    for (const [key, value] of Object.entries(config.metadata)) {
      if (value) {
        args.push(`--metadata=${key}:${value}`);
      }
    }
  }
  
  // Format-specific arguments
  const formatSettings = config.formatSettings || {};
  
  if (format === 'pdf') {
    const pdfSettings = formatSettings.pdf || {};
    
    if (pdfSettings.paperSize) {
      args.push(`--variable=papersize:${pdfSettings.paperSize}`);
    }
    
    if (pdfSettings.marginTop) {
      args.push(`--variable=margin-top:${pdfSettings.marginTop}`);
    }
    
    if (pdfSettings.marginRight) {
      args.push(`--variable=margin-right:${pdfSettings.marginRight}`);
    }
    
    if (pdfSettings.marginBottom) {
      args.push(`--variable=margin-bottom:${pdfSettings.marginBottom}`);
    }
    
    if (pdfSettings.marginLeft) {
      args.push(`--variable=margin-left:${pdfSettings.marginLeft}`);
    }
    
    if (pdfSettings.fontSize) {
      args.push(`--variable=fontsize:${pdfSettings.fontSize}`);
    }
    
    if (pdfSettings.lineHeight) {
      args.push(`--variable=lineheight:${pdfSettings.lineHeight}`);
    }
    
    if (pdfSettings.template && fs.existsSync(pdfSettings.template)) {
      args.push(`--template=${pdfSettings.template}`);
    }
  } else if (format === 'epub') {
    const epubSettings = formatSettings.epub || {};
    
    if (epubSettings.coverImage && fs.existsSync(epubSettings.coverImage)) {
      args.push(`--epub-cover-image=${epubSettings.coverImage}`);
    }
    
    if (epubSettings.css && fs.existsSync(epubSettings.css)) {
      args.push(`--css=${epubSettings.css}`);
    }
    
    if (epubSettings.tocDepth) {
      args.push(`--toc-depth=${epubSettings.tocDepth}`);
    }
    
    args.push('--toc');
  } else if (format === 'html') {
    const htmlSettings = formatSettings.html || {};
    
    if (htmlSettings.template && fs.existsSync(htmlSettings.template)) {
      args.push(`--template=${htmlSettings.template}`);
    }
    
    if (htmlSettings.css && fs.existsSync(htmlSettings.css)) {
      args.push(`--css=${htmlSettings.css}`);
    }
    
    if (htmlSettings.toc !== false) {
      args.push('--toc');
      
      if (htmlSettings.tocDepth) {
        args.push(`--toc-depth=${htmlSettings.tocDepth}`);
      }
    }
    
    if (htmlSettings.sectionDivs) {
      args.push('--section-divs');
    }
    
    if (htmlSettings.selfContained) {
      args.push('--self-contained');
    }
  }
  
  // Add language-specific metadata
  args.push(`--metadata=lang:${language}`);
  
  return args;
}

module.exports = {
  loadExtendedConfig,
  convertLegacyConfig,
  loadConfig,
  getDefaultConfig,
  getPandocArgs
};
