const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const yaml = require('yaml');

/**
 * Find the project root directory by looking for book.yaml
 * 
 * @returns {string} - Path to the project root
 * @throws {Error} - If project root could not be found
 */
function findProjectRoot() {
  let currentDir = process.cwd();
  const root = path.parse(currentDir).root;
  
  while (currentDir !== root) {
    if (fs.existsSync(path.join(currentDir, 'book.yaml'))) {
      return currentDir;
    }
    
    currentDir = path.dirname(currentDir);
  }
  
  throw new Error('Could not find project root (book.yaml not found in parent directories)');
}

/**
 * Load book configuration from book.yaml
 * 
 * @param {string} projectRoot - Path to the project root
 * @returns {Object} - Book configuration
 */
function loadConfig(projectRoot) {
  const configPath = path.join(projectRoot, 'book.yaml');
  
  if (fs.existsSync(configPath)) {
    try {
      const configContent = fs.readFileSync(configPath, 'utf-8');
      let config = yaml.parse(configContent);
      
      // Apply extended configuration processing
      config = processExtendedConfig(config);
      
      return config;
    } catch (error) {
      console.error(`Error reading config: ${error.message}`);
    }
  }
  
  // Return default configuration
  return getDefaultConfig();
}

/**
 * Get the default configuration
 * 
 * @returns {Object} - Default configuration
 */
function getDefaultConfig() {
  return {
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
    },
    formatSettings: getDefaultFormatSettings()
  };
}

/**
 * Get default format-specific settings
 * 
 * @returns {Object} - Default format settings
 */
function getDefaultFormatSettings() {
  return {
    pdf: {
      paperSize: 'letter',
      marginTop: '1in',
      marginRight: '1in',
      marginBottom: '1in',
      marginLeft: '1in',
      fontSize: '11pt',
      lineHeight: '1.5',
      template: 'templates/pdf/default.latex'
    },
    epub: {
      coverImage: 'book/images/cover.png',
      css: 'templates/epub/style.css',
      tocDepth: 3
    },
    html: {
      template: 'templates/html/default.html',
      css: 'templates/html/style.css',
      toc: true,
      tocDepth: 3,
      sectionDivs: true,
      selfContained: true
    }
  };
}

/**
 * Process extended configuration options and convert legacy formats
 * 
 * @param {Object} config - Raw configuration
 * @returns {Object} - Processed configuration
 */
function processExtendedConfig(config) {
  // Initialize the formats object if not present
  if (!config.formats) {
    config.formats = {
      pdf: true,
      epub: true,
      mobi: true,
      html: true
    };
  }
  
  // Check for legacy outputs format and convert to formats
  if (config.outputs) {
    config.formats.pdf = config.outputs.pdf !== false;
    config.formats.epub = config.outputs.epub !== false;
    config.formats.mobi = config.outputs.mobi !== false;
    config.formats.html = config.outputs.html !== false;
  }

  // Check file_prefix (snake_case) and convert to filePrefix (camelCase)
  if (config.file_prefix && !config.filePrefix) {
    config.filePrefix = config.file_prefix;
  }
  
  // Initialize formatSettings
  if (!config.formatSettings) {
    config.formatSettings = {};
  }
  
  // Process PDF settings
  config.formatSettings.pdf = config.formatSettings.pdf || {};
  
  // Check for legacy pdf settings
  if (config.pdf) {
    config.formatSettings.pdf = {
      ...config.formatSettings.pdf,
      paperSize: config.pdf.paper_size || config.pdf.paperSize || 'letter',
      marginTop: config.pdf.margin_top || config.pdf.marginTop || '1in',
      marginRight: config.pdf.margin_right || config.pdf.marginRight || '1in',
      marginBottom: config.pdf.margin_bottom || config.pdf.marginBottom || '1in',
      marginLeft: config.pdf.margin_left || config.pdf.marginLeft || '1in',
      fontSize: config.pdf.font_size || config.pdf.fontSize || '11pt',
      lineHeight: config.pdf.line_height || config.pdf.lineHeight || '1.5',
      template: config.pdf.template || 'templates/pdf/default.latex'
    };
  }
  
  // Apply defaults for missing PDF settings
  const defaultPdfSettings = getDefaultFormatSettings().pdf;
  for (const key in defaultPdfSettings) {
    if (!config.formatSettings.pdf[key]) {
      config.formatSettings.pdf[key] = defaultPdfSettings[key];
    }
  }
  
  // Process EPUB settings
  config.formatSettings.epub = config.formatSettings.epub || {};
  
  // Check for legacy epub settings
  if (config.epub) {
    config.formatSettings.epub = {
      ...config.formatSettings.epub,
      coverImage: config.epub.cover_image || config.epub.coverImage || 'book/images/cover.png',
      css: config.epub.css || 'templates/epub/style.css',
      tocDepth: config.epub.toc_depth || config.epub.tocDepth || 3
    };
  }
  
  // Apply defaults for missing EPUB settings
  const defaultEpubSettings = getDefaultFormatSettings().epub;
  for (const key in defaultEpubSettings) {
    if (!config.formatSettings.epub[key]) {
      config.formatSettings.epub[key] = defaultEpubSettings[key];
    }
  }
  
  // Process HTML settings
  config.formatSettings.html = config.formatSettings.html || {};
  
  // Check for legacy html settings
  if (config.html) {
    config.formatSettings.html = {
      ...config.formatSettings.html,
      template: config.html.template || 'templates/html/default.html',
      css: config.html.css || 'templates/html/style.css',
      toc: config.html.toc !== false,
      tocDepth: config.html.toc_depth || config.html.tocDepth || 3,
      sectionDivs: config.html.section_divs || config.html.sectionDivs || true,
      selfContained: config.html.self_contained || config.html.selfContained || true
    };
  }
  
  // Apply defaults for missing HTML settings
  const defaultHtmlSettings = getDefaultFormatSettings().html;
  for (const key in defaultHtmlSettings) {
    if (!config.formatSettings.html[key]) {
      config.formatSettings.html[key] = defaultHtmlSettings[key];
    }
  }
  
  // Process languages
  if (!Array.isArray(config.languages)) {
    // If languages is not an array, check for single language
    if (config.language) {
      config.languages = [config.language];
    } else {
      config.languages = ['en']; // Default to English
    }
  }
  
  // Process metadata
  if (config.metadata) {
    // Ensure metadata is available directly in the config
    if (config.metadata.rights && !config.rights) {
      config.rights = config.metadata.rights;
    }
    
    if (config.metadata.description && !config.description) {
      config.description = config.metadata.description;
    }
    
    if (config.metadata.keywords && !config.keywords) {
      config.keywords = config.metadata.keywords;
    }
  }
  
  return config;
}

/**
 * Get format-specific settings for a particular format
 * 
 * @param {Object} config - Book configuration
 * @param {string} format - Format name (pdf, epub, html)
 * @returns {Object} - Format-specific settings
 */
function getFormatSettings(config, format) {
  const settings = config.formatSettings && config.formatSettings[format];
  
  if (settings) {
    return settings;
  }
  
  // Return default settings if not found
  return getDefaultFormatSettings()[format] || {};
}

/**
 * Ensure a directory exists, creating it if necessary
 * 
 * @param {string} dirPath - Path to the directory
 */
function ensureDirectoryExists(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

/**
 * Build file names for a book in a specific language
 * 
 * @param {string} language - Language code
 * @param {string} projectRoot - Path to the project root
 * @returns {Object} - Object with file paths for input and outputs
 */
function buildFileNames(language, projectRoot) {
  const config = loadConfig(projectRoot);
  const filePrefix = config.filePrefix || 'book';
  
  const buildDir = path.join(projectRoot, 'build', language);
  
  return {
    input: path.join(buildDir, 'book.md'),
    pdf: path.join(buildDir, `${filePrefix}.pdf`),
    epub: path.join(buildDir, `${filePrefix}.epub`),
    mobi: path.join(buildDir, `${filePrefix}.mobi`),
    html: path.join(buildDir, `${filePrefix}.html`)
  };
}

/**
 * Run a script with the provided arguments
 * 
 * @param {string} scriptPath - Path to the script
 * @param {string[]} args - Array of arguments
 * @returns {Promise<Object>} - Result of the script execution
 */
function runScript(scriptPath, args = []) {
  return new Promise((resolve, reject) => {
    const command = `"${scriptPath}" ${args.join(' ')}`;
    
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      
      resolve({
        success: true,
        stdout,
        stderr
      });
    });
  });
}

/**
 * Write a config file in the format expected by legacy scripts
 * 
 * @param {Object} config - Book configuration
 * @param {string} outputPath - Path to write the config file
 * @returns {boolean} - Success status
 */
function writeLegacyConfig(config, outputPath) {
  try {
    // Convert to legacy format
    const legacyConfig = {
      title: config.title,
      subtitle: config.subtitle,
      author: config.author,
      file_prefix: config.filePrefix,
      language: config.languages[0],
      languages: config.languages,
      outputs: {
        pdf: config.formats.pdf,
        epub: config.formats.epub,
        mobi: config.formats.mobi,
        html: config.formats.html
      },
      pdf: {
        paper_size: config.formatSettings.pdf.paperSize,
        margin_top: config.formatSettings.pdf.marginTop,
        margin_right: config.formatSettings.pdf.marginRight,
        margin_bottom: config.formatSettings.pdf.marginBottom,
        margin_left: config.formatSettings.pdf.marginLeft,
        font_size: config.formatSettings.pdf.fontSize,
        line_height: config.formatSettings.pdf.lineHeight,
        template: config.formatSettings.pdf.template
      },
      epub: {
        cover_image: config.formatSettings.epub.coverImage,
        css: config.formatSettings.epub.css,
        toc_depth: config.formatSettings.epub.tocDepth
      },
      html: {
        template: config.formatSettings.html.template,
        css: config.formatSettings.html.css,
        toc: config.formatSettings.html.toc,
        toc_depth: config.formatSettings.html.tocDepth,
        section_divs: config.formatSettings.html.sectionDivs,
        self_contained: config.formatSettings.html.selfContained
      }
    };
    
    fs.writeFileSync(outputPath, yaml.stringify(legacyConfig));
    return true;
  } catch (error) {
    console.error(`Error writing legacy config: ${error.message}`);
    return false;
  }
}

module.exports = {
  findProjectRoot,
  loadConfig,
  getDefaultConfig,
  getDefaultFormatSettings,
  processExtendedConfig,
  getFormatSettings,
  ensureDirectoryExists,
  buildFileNames,
  runScript,
  writeLegacyConfig
};
