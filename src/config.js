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
  // Add responsive option, default to true
  config.formatSettings.html.responsive = config.formatSettings.html.responsive !== undefined ? 
    config.formatSettings.html.responsive : config.html?.responsive !== false;
  
  // MOBI configuration - minimal for now
  config.formatSettings.mobi = config.formatSettings.mobi || {};
  
  // DOCX configuration
  config.formatSettings.docx = config.formatSettings.docx || {};
  config.formatSettings.docx.referenceDoc = config.formatSettings.docx.referenceDoc || config.docx?.reference_doc || '';
  config.formatSettings.docx.tocDepth = config.formatSettings.docx.tocDepth || config.docx?.toc_depth || 3;
  config.formatSettings.docx.toc = config.formatSettings.docx.toc !== undefined ? config.formatSettings.docx.toc : config.docx?.toc !== false;
  
  // Normalize output formats
  config.formats = config.formats || {};
  
  // Handle legacy outputs format
  if (config.outputs) {
    config.formats.pdf = config.outputs.pdf !== false;
    config.formats.epub = config.outputs.epub !== false;
    config.formats.mobi = config.outputs.mobi !== false;
    config.formats.html = config.outputs.html !== false;
    config.formats.docx = config.outputs.docx !== false;
  }
  
  // Ensure all formats have a boolean value
  config.formats.pdf = config.formats.pdf !== false;
  config.formats.epub = config.formats.epub !== false;
  config.formats.mobi = config.formats.mobi !== false;
  config.formats.html = config.formats.html !== false;
  config.formats.docx = config.formats.docx !== false;
  
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
      html: legacyConfig.outputs?.html !== false,
      docx: legacyConfig.outputs?.docx !== false
    },
    
    // Pass format-specific settings to be processed by loadExtendedConfig
    pdf: legacyConfig.pdf || {},
    epub: legacyConfig.epub || {},
    html: legacyConfig.html || {},
    docx: legacyConfig.docx || {},
    
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
      html: true,
      docx: true
    }
  });
}

/**
 * Safely quote a string for command line usage
 * 
 * @param {string} str - String to quote
 * @returns {string} - Safely quoted string
 */
function safeQuote(str) {
  // Replace double quotes with escaped double quotes
  const escaped = str.replace(/\"/g, '\\\"');
  // Wrap in double quotes
  return `"${escaped}"`;
}

/**
 * Generate pandoc arguments from config
 * 
 * @param {Object} config - Configuration object
 * @param {string} format - Output format ('pdf', 'epub', 'html', 'docx')
 * @param {string} language - Language code
 * @returns {Array} - Array of pandoc arguments
 */
function getPandocArgs(config, format, language) {
  const args = [
    '--standalone',
    `--metadata=title:${safeQuote(config.title)}`,
    `--metadata=author:${safeQuote(config.author)}`
  ];
  
  if (config.subtitle) {
    args.push(`--metadata=subtitle:${safeQuote(config.subtitle)}`);
  }
  
  if (config.metadata) {
    for (const [key, value] of Object.entries(config.metadata)) {
      if (value) {
        args.push(`--metadata=${key}:${safeQuote(value.toString())}`);
      }
    }
  }
  
  // Format-specific arguments
  const formatSettings = config.formatSettings || {};
  
  if (format === 'pdf') {
    const pdfSettings = formatSettings.pdf || {};
    
    if (pdfSettings.paperSize) {
      args.push(`--variable=papersize:${safeQuote(pdfSettings.paperSize)}`);
    }
    
    if (pdfSettings.marginTop) {
      args.push(`--variable=margin-top:${safeQuote(pdfSettings.marginTop)}`);
    }
    
    if (pdfSettings.marginRight) {
      args.push(`--variable=margin-right:${safeQuote(pdfSettings.marginRight)}`);
    }
    
    if (pdfSettings.marginBottom) {
      args.push(`--variable=margin-bottom:${safeQuote(pdfSettings.marginBottom)}`);
    }
    
    if (pdfSettings.marginLeft) {
      args.push(`--variable=margin-left:${safeQuote(pdfSettings.marginLeft)}`);
    }
    
    if (pdfSettings.fontSize) {
      args.push(`--variable=fontsize:${safeQuote(pdfSettings.fontSize)}`);
    }
    
    if (pdfSettings.lineHeight) {
      args.push(`--variable=lineheight:${safeQuote(pdfSettings.lineHeight)}`);
    }
    
    if (pdfSettings.template && fs.existsSync(pdfSettings.template)) {
      args.push(`--template=${safeQuote(pdfSettings.template)}`);
    }
  } else if (format === 'epub') {
    const epubSettings = formatSettings.epub || {};
    
    if (epubSettings.coverImage && fs.existsSync(epubSettings.coverImage)) {
      args.push(`--epub-cover-image=${safeQuote(epubSettings.coverImage)}`);
    }
    
    if (epubSettings.css && fs.existsSync(epubSettings.css)) {
      args.push(`--css=${safeQuote(epubSettings.css)}`);
    }
    
    if (epubSettings.tocDepth) {
      args.push(`--toc-depth=${epubSettings.tocDepth}`);
    }
    
    args.push('--toc');
  } else if (format === 'html') {
    const htmlSettings = formatSettings.html || {};
    
    // Use responsive template and CSS if the responsive option is enabled
    if (htmlSettings.responsive !== false) {
      // Check for responsive template
      const responsiveTemplate = path.join(process.cwd(), 'templates/html/responsive.html');
      if (fs.existsSync(responsiveTemplate)) {
        args.push(`--template=${safeQuote(responsiveTemplate)}`);
      } else if (htmlSettings.template && fs.existsSync(htmlSettings.template)) {
        args.push(`--template=${safeQuote(htmlSettings.template)}`);
      }
      
      // Check for responsive CSS
      const responsiveCSS = path.join(process.cwd(), 'templates/html/responsive.css');
      if (fs.existsSync(responsiveCSS)) {
        args.push(`--css=${safeQuote(responsiveCSS)}`);
      } else if (htmlSettings.css && fs.existsSync(htmlSettings.css)) {
        args.push(`--css=${safeQuote(htmlSettings.css)}`);
      }
    } else {
      // Use standard (non-responsive) templates
      if (htmlSettings.template && fs.existsSync(htmlSettings.template)) {
        args.push(`--template=${safeQuote(htmlSettings.template)}`);
      }
      
      if (htmlSettings.css && fs.existsSync(htmlSettings.css)) {
        args.push(`--css=${safeQuote(htmlSettings.css)}`);
      }
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
  } else if (format === 'docx') {
    const docxSettings = formatSettings.docx || {};
    
    if (docxSettings.referenceDoc && fs.existsSync(docxSettings.referenceDoc)) {
      args.push(`--reference-doc=${safeQuote(docxSettings.referenceDoc)}`);
    }
    
    if (docxSettings.toc !== false) {
      args.push('--toc');
      
      if (docxSettings.tocDepth) {
        args.push(`--toc-depth=${docxSettings.tocDepth}`);
      }
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
  getPandocArgs,
  safeQuote
};