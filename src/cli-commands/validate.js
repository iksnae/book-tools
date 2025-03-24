/**
 * Validate command module
 * 
 * This module implements the `book validate` command to validate
 * the project configuration and dependencies.
 */

const path = require('path');
const fs = require('fs');
const ora = require('ora');
const chalk = require('chalk');
const { findProjectRoot, loadBookConfig } = require('../utils');
const { fileExists } = require('../formats/utils');

/**
 * Configure the validate command
 * 
 * @param {Object} program - Commander program instance
 */
function configureValidateCommand(program) {
  program
    .command('validate')
    .description('Validate the project configuration')
    .option('-c, --check-dependencies', 'Check external dependencies')
    .option('-v, --verbose', 'Show detailed validation results')
    .action(async (options) => {
      try {
        const spinner = ora('Validating project configuration...').start();
        
        // Try to find the project root
        let projectRoot;
        try {
          projectRoot = findProjectRoot();
        } catch (error) {
          spinner.fail(chalk.red('Project validation failed'));
          console.error(chalk.red(error.message));
          console.error(chalk.yellow('Make sure you are in a book project directory with a book.yaml file.'));
          return;
        }
        
        // Try to load the configuration
        let config;
        try {
          config = loadBookConfig(projectRoot);
        } catch (error) {
          spinner.fail(chalk.red('Configuration validation failed'));
          console.error(chalk.red(`Error loading configuration: ${error.message}`));
          return;
        }
        
        // Validate the configuration
        const configValidation = validateConfig(config, projectRoot);
        
        // Check dependencies if requested
        let dependencyValidation = { success: true, warnings: [], errors: [] };
        if (options.checkDependencies) {
          dependencyValidation = await validateDependencies();
        }
        
        // Determine overall success
        const success = configValidation.success && dependencyValidation.success;
        
        if (success) {
          spinner.succeed(chalk.green('Project configuration is valid'));
        } else {
          spinner.fail(chalk.red('Project validation found issues'));
        }
        
        // Show validation results
        if (!configValidation.success || options.verbose) {
          console.log(chalk.blue('\nConfiguration validation:'));
          if (configValidation.errors.length > 0) {
            console.log(chalk.red('Errors:'));
            configValidation.errors.forEach(error => {
              console.log(chalk.red(` - ${error}`));
            });
          }
          
          if (configValidation.warnings.length > 0) {
            console.log(chalk.yellow('Warnings:'));
            configValidation.warnings.forEach(warning => {
              console.log(chalk.yellow(` - ${warning}`));
            });
          }
          
          if (configValidation.success && configValidation.warnings.length === 0) {
            console.log(chalk.green(' ✓ Configuration is valid'));
          }
        }
        
        // Show dependency validation results
        if (options.checkDependencies && (!dependencyValidation.success || options.verbose)) {
          console.log(chalk.blue('\nDependency validation:'));
          if (dependencyValidation.errors.length > 0) {
            console.log(chalk.red('Errors:'));
            dependencyValidation.errors.forEach(error => {
              console.log(chalk.red(` - ${error}`));
            });
          }
          
          if (dependencyValidation.warnings.length > 0) {
            console.log(chalk.yellow('Warnings:'));
            dependencyValidation.warnings.forEach(warning => {
              console.log(chalk.yellow(` - ${warning}`));
            });
          }
          
          if (dependencyValidation.success && dependencyValidation.warnings.length === 0) {
            console.log(chalk.green(' ✓ All dependencies are available'));
          }
        }
        
        // Show summary
        if (success) {
          console.log(chalk.green('\n✓ Project validation passed'));
        } else {
          console.log(chalk.red('\n✗ Project validation failed'));
          console.log(chalk.yellow('Please fix the errors to ensure proper book building.'));
        }
      } catch (error) {
        console.error(chalk.red(`Error: ${error.message}`));
      }
    });
}

/**
 * Validate the configuration object
 * 
 * @param {Object} config - Configuration object
 * @param {string} projectRoot - Path to project root
 * @returns {Object} - Validation result
 */
function validateConfig(config, projectRoot) {
  const errors = [];
  const warnings = [];
  
  // Required fields
  if (!config.title) {
    errors.push('Missing required field: title');
  }
  
  if (!config.author) {
    errors.push('Missing required field: author');
  }
  
  // Check languages
  if (!Array.isArray(config.languages) || config.languages.length === 0) {
    errors.push('Missing or invalid languages array');
  } else {
    // Check if language directories exist
    config.languages.forEach(language => {
      const langDir = path.join(projectRoot, 'book', language);
      if (!fs.existsSync(langDir)) {
        warnings.push(`Language directory not found: book/${language}`);
      } else if (!fs.statSync(langDir).isDirectory()) {
        warnings.push(`Invalid language directory: book/${language}`);
      }
    });
  }
  
  // Check formats
  if (!config.formats) {
    warnings.push('No formats specified, using defaults');
  }
  
  // Check format-specific settings
  const formatSettings = config.formatSettings || {};
  
  // PDF settings
  if (config.formats?.pdf) {
    const pdfSettings = formatSettings.pdf || {};
    
    // Check template
    if (pdfSettings.template) {
      const templatePath = path.isAbsolute(pdfSettings.template)
        ? pdfSettings.template
        : path.join(projectRoot, pdfSettings.template);
      
      if (!fs.existsSync(templatePath)) {
        warnings.push(`PDF template not found: ${pdfSettings.template}`);
      }
    }
  }
  
  // EPUB settings
  if (config.formats?.epub) {
    const epubSettings = formatSettings.epub || {};
    
    // Check cover image
    if (epubSettings.coverImage) {
      const coverPath = path.isAbsolute(epubSettings.coverImage)
        ? epubSettings.coverImage
        : path.join(projectRoot, epubSettings.coverImage);
      
      if (!fs.existsSync(coverPath)) {
        warnings.push(`EPUB cover image not found: ${epubSettings.coverImage}`);
      }
    }
    
    // Check CSS
    if (epubSettings.css) {
      const cssPath = path.isAbsolute(epubSettings.css)
        ? epubSettings.css
        : path.join(projectRoot, epubSettings.css);
      
      if (!fs.existsSync(cssPath)) {
        warnings.push(`EPUB CSS file not found: ${epubSettings.css}`);
      }
    }
  }
  
  // HTML settings
  if (config.formats?.html) {
    const htmlSettings = formatSettings.html || {};
    
    // Check template
    if (htmlSettings.template) {
      const templatePath = path.isAbsolute(htmlSettings.template)
        ? htmlSettings.template
        : path.join(projectRoot, htmlSettings.template);
      
      if (!fs.existsSync(templatePath)) {
        warnings.push(`HTML template not found: ${htmlSettings.template}`);
      }
    }
    
    // Check CSS
    if (htmlSettings.css) {
      const cssPath = path.isAbsolute(htmlSettings.css)
        ? htmlSettings.css
        : path.join(projectRoot, htmlSettings.css);
      
      if (!fs.existsSync(cssPath)) {
        warnings.push(`HTML CSS file not found: ${htmlSettings.css}`);
      }
    }
  }
  
  // DOCX settings
  if (config.formats?.docx) {
    const docxSettings = formatSettings.docx || {};
    
    // Check reference document
    if (docxSettings.referenceDoc) {
      const refPath = path.isAbsolute(docxSettings.referenceDoc)
        ? docxSettings.referenceDoc
        : path.join(projectRoot, docxSettings.referenceDoc);
      
      if (!fs.existsSync(refPath)) {
        warnings.push(`DOCX reference document not found: ${docxSettings.referenceDoc}`);
      }
    }
  }
  
  return {
    success: errors.length === 0,
    errors,
    warnings
  };
}

/**
 * Check for required external dependencies
 * 
 * @returns {Promise<Object>} - Validation result
 */
async function validateDependencies() {
  const errors = [];
  const warnings = [];
  
  // Check for pandoc
  try {
    const result = await runCommand('pandoc --version');
    const versionMatch = result.stdout.match(/^pandoc\s+(\d+\.\d+)/m);
    if (versionMatch) {
      const version = parseFloat(versionMatch[1]);
      if (version < 2.0) {
        warnings.push(`Pandoc version ${version} is lower than recommended (2.0+)`);
      }
    }
  } catch (error) {
    errors.push('Pandoc is not installed or not in PATH');
  }
  
  // Check for kindlegen (optional)
  try {
    await runCommand('kindlegen -version');
  } catch (error) {
    warnings.push('Kindlegen is not installed (required for MOBI output)');
  }
  
  // Check for calibre (optional, alternative to kindlegen)
  try {
    await runCommand('ebook-convert --version');
  } catch (error) {
    if (warnings.some(w => w.includes('Kindlegen'))) {
      warnings.push('Neither Kindlegen nor Calibre is installed (one is required for MOBI output)');
    }
  }
  
  return {
    success: errors.length === 0,
    errors,
    warnings
  };
}

/**
 * Run a command and return the output
 * 
 * @param {string} command - Command to run
 * @returns {Promise<Object>} - Command result
 */
function runCommand(command) {
  return new Promise((resolve, reject) => {
    const { exec } = require('child_process');
    
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      
      resolve({ stdout, stderr });
    });
  });
}

module.exports = {
  configureValidateCommand
};
