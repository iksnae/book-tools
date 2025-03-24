/**
 * Validate book project configuration and dependencies
 * Verifies proper setup of configuration files, dependencies, and directory structure
 */
const fs = require('fs-extra');
const path = require('path');
const { execSync } = require('child_process');
const yaml = require('yaml');
const { loadConfig } = require('./config');

/**
 * Validate the book configuration file
 * 
 * @param {Object} options - Validation options
 * @param {string} options.configPath - Path to the book.yaml file
 * @returns {Object} Validation results
 */
async function validateConfig(options = {}) {
  const configPath = options.configPath || 'book.yaml';
  
  const result = {
    success: false,
    issues: [],
    valid: false,
    configPath: configPath
  };
  
  // Check if config file exists
  if (!fs.existsSync(configPath)) {
    result.issues.push({
      type: 'error',
      message: `Configuration file not found: ${configPath}`
    });
    return result;
  }
  
  // Check if config file can be parsed
  try {
    const configContent = fs.readFileSync(configPath, 'utf-8');
    const rawConfig = yaml.parse(configContent);
    
    // Check for essential properties
    if (!rawConfig.title) {
      result.issues.push({
        type: 'warning',
        message: 'Missing title in configuration'
      });
    }
    
    if (!rawConfig.author) {
      result.issues.push({
        type: 'warning',
        message: 'Missing author in configuration'
      });
    }
    
    // Check for languages
    if (!rawConfig.languages || !Array.isArray(rawConfig.languages) || rawConfig.languages.length === 0) {
      result.issues.push({
        type: 'error',
        message: 'No languages specified in configuration'
      });
    } else {
      // Check if language directories exist
      for (const lang of rawConfig.languages) {
        const langDir = path.join('book', lang);
        if (!fs.existsSync(langDir)) {
          result.issues.push({
            type: 'warning',
            message: `Language directory not found: ${langDir}`
          });
        }
      }
    }
    
    // Check formats configuration
    if (!rawConfig.formats) {
      result.issues.push({
        type: 'warning',
        message: 'No formats specified in configuration'
      });
    } else {
      // Load full config to get format settings
      const config = loadConfig(configPath);
      
      // Check PDF settings
      if (config.formats.pdf) {
        if (config.formatSettings?.pdf?.template && !fs.existsSync(config.formatSettings.pdf.template)) {
          result.issues.push({
            type: 'warning',
            message: `PDF template not found: ${config.formatSettings.pdf.template}`
          });
        }
      }
      
      // Check EPUB settings
      if (config.formats.epub) {
        if (config.formatSettings?.epub?.coverImage && !fs.existsSync(config.formatSettings.epub.coverImage)) {
          result.issues.push({
            type: 'warning',
            message: `EPUB cover image not found: ${config.formatSettings.epub.coverImage}`
          });
        }
        
        if (config.formatSettings?.epub?.css && !fs.existsSync(config.formatSettings.epub.css)) {
          result.issues.push({
            type: 'warning',
            message: `EPUB CSS file not found: ${config.formatSettings.epub.css}`
          });
        }
      }
      
      // Check HTML settings
      if (config.formats.html) {
        if (config.formatSettings?.html?.template && !fs.existsSync(config.formatSettings.html.template)) {
          result.issues.push({
            type: 'warning',
            message: `HTML template not found: ${config.formatSettings.html.template}`
          });
        }
        
        if (config.formatSettings?.html?.css && !fs.existsSync(config.formatSettings.html.css)) {
          result.issues.push({
            type: 'warning',
            message: `HTML CSS file not found: ${config.formatSettings.html.css}`
          });
        }
      }
      
      // Check DOCX settings
      if (config.formats.docx) {
        if (config.formatSettings?.docx?.referenceDoc && !fs.existsSync(config.formatSettings.docx.referenceDoc)) {
          result.issues.push({
            type: 'warning',
            message: `DOCX reference doc not found: ${config.formatSettings.docx.referenceDoc}`
          });
        }
      }
    }
    
    // Set valid if there are no error issues
    result.valid = !result.issues.some(issue => issue.type === 'error');
    result.success = true;
  } catch (error) {
    result.issues.push({
      type: 'error',
      message: `Failed to parse configuration: ${error.message}`
    });
  }
  
  return result;
}

/**
 * Check if a system dependency is installed
 * 
 * @param {string} command - Command to check
 * @returns {boolean} - True if command is available
 */
function checkDependency(command) {
  try {
    execSync(`which ${command}`, { stdio: 'ignore' });
    return true;
  } catch (error) {
    return false;
  }
}

/**
 * Validate system dependencies
 * 
 * @returns {Object} Validation results
 */
async function validateDependencies() {
  const result = {
    success: true,
    issues: [],
    dependencies: {}
  };
  
  // Check essential dependencies
  const dependencies = {
    pandoc: {
      required: true,
      message: 'Pandoc is required for all format conversions'
    },
    latex: {
      command: 'pdflatex',
      required: true,
      message: 'LaTeX (pdflatex) is required for PDF generation'
    },
    kindlegen: {
      required: false,
      message: 'Kindlegen is required for MOBI format generation (optional)'
    },
    calibre: {
      command: 'ebook-convert',
      required: false,
      message: 'Calibre (ebook-convert) can be used as an alternative for e-book conversion (optional)'
    }
  };
  
  for (const [name, dependency] of Object.entries(dependencies)) {
    const command = dependency.command || name;
    const installed = checkDependency(command);
    
    result.dependencies[name] = installed;
    
    if (!installed && dependency.required) {
      result.issues.push({
        type: 'error',
        message: dependency.message
      });
    } else if (!installed) {
      result.issues.push({
        type: 'warning',
        message: dependency.message
      });
    }
  }
  
  return result;
}

/**
 * Validate project directory structure
 * 
 * @param {Object} options - Validation options
 * @param {string} options.configPath - Path to the book.yaml file
 * @returns {Object} Validation results
 */
async function validateStructure(options = {}) {
  const configPath = options.configPath || 'book.yaml';
  
  const result = {
    success: false,
    issues: [],
    valid: false,
    directories: {}
  };
  
  // Check for essential directories
  const essentialDirs = [
    { path: 'book', required: true, message: 'Main content directory not found' },
    { path: 'templates', required: false, message: 'Templates directory not found (recommended)' },
    { path: 'templates/pdf', required: false, message: 'PDF templates directory not found' },
    { path: 'templates/epub', required: false, message: 'EPUB templates directory not found' },
    { path: 'templates/html', required: false, message: 'HTML templates directory not found' },
    { path: 'templates/docx', required: false, message: 'DOCX templates directory not found' },
    { path: 'book/images', required: false, message: 'Images directory not found (recommended)' }
  ];
  
  for (const dir of essentialDirs) {
    const exists = fs.existsSync(dir.path);
    result.directories[dir.path] = exists;
    
    if (!exists && dir.required) {
      result.issues.push({
        type: 'error',
        message: dir.message
      });
    } else if (!exists) {
      result.issues.push({
        type: 'warning',
        message: dir.message
      });
    }
  }
  
  // Check language-specific structure
  try {
    const config = loadConfig(configPath);
    if (config.languages && Array.isArray(config.languages)) {
      for (const lang of config.languages) {
        const langDir = `book/${lang}`;
        
        if (fs.existsSync(langDir)) {
          // Check if there are markdown files
          const files = fs.readdirSync(langDir);
          const mdFiles = files.filter(file => file.endsWith('.md'));
          
          if (mdFiles.length === 0) {
            result.issues.push({
              type: 'warning',
              message: `No markdown files found in language directory: ${langDir}`
            });
          }
        }
      }
    }
  } catch (error) {
    result.issues.push({
      type: 'warning',
      message: `Error checking language structure: ${error.message}`
    });
  }
  
  // Set valid if there are no error issues
  result.valid = !result.issues.some(issue => issue.type === 'error');
  result.success = true;
  
  return result;
}

/**
 * Comprehensive validation of the book project
 * 
 * @param {Object} options - Validation options
 * @param {string} options.configPath - Path to the book.yaml file
 * @returns {Object} Validation results
 */
async function validate(options = {}) {
  const configResult = await validateConfig(options);
  const dependencyResult = await validateDependencies();
  const structureResult = await validateStructure(options);
  
  const result = {
    success: configResult.success && dependencyResult.success && structureResult.success,
    valid: configResult.valid && !dependencyResult.issues.some(i => i.type === 'error') && structureResult.valid,
    config: configResult,
    dependencies: dependencyResult,
    structure: structureResult,
    allIssues: [
      ...configResult.issues,
      ...dependencyResult.issues,
      ...structureResult.issues
    ]
  };
  
  return result;
}

module.exports = {
  validate,
  validateConfig,
  validateDependencies,
  validateStructure
};
