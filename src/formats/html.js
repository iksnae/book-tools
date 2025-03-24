/**
 * HTML Generator Module
 * 
 * This module provides functions for generating HTML output
 * from markdown sources using pandoc.
 */

const path = require('path');
const fs = require('fs');
const { runCommand, createPandocCommand } = require('../utils');
const { getResourcePaths, fileExists, findTemplate, createResult } = require('./utils');

/**
 * Generate HTML from markdown
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output HTML file
 * @param {string} language - Language code
 * @param {Object} options - Additional options
 * @returns {Promise<Object>} - Result of HTML generation
 */
async function generateHTML(config, inputPath, outputPath, language, options = {}) {
  try {
    // Get resource paths for this language
    const projectRoot = path.dirname(path.dirname(path.dirname(inputPath)));
    const resourcePaths = getResourcePaths(projectRoot, language);
    
    // Get HTML-specific settings
    const htmlSettings = config.formatSettings?.html || {};
    
    // Check for custom template
    const templatePath = htmlSettings.template || 'templates/html/default.html';
    const hasTemplate = fileExists(path.join(projectRoot, templatePath));
    
    // Check for custom CSS
    const cssPath = htmlSettings.css || 'templates/html/style.css';
    const hasCss = fileExists(path.join(projectRoot, cssPath));
    
    // Generate pandoc command
    const command = createPandocCommand(
      config,
      inputPath, 
      outputPath, 
      'html', 
      language, 
      resourcePaths
    );
    
    // Execute command
    try {
      const result = await runCommand(command);
      return createResult(true, 'html', {
        outputPath,
        command,
        hasTemplate,
        hasCss,
        stdout: result.stdout,
        stderr: result.stderr
      });
    } catch (error) {
      // Try fallback if configured
      if (htmlSettings.fallback !== false) {
        return await generateFallbackHTML(config, inputPath, outputPath, language);
      }
      throw error;
    }
  } catch (error) {
    return createResult(false, 'html', {
      error,
      errorMessage: error.message
    });
  }
}

/**
 * Generate HTML with fallback settings
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output HTML file
 * @param {string} language - Language code
 * @returns {Promise<Object>} - Result of fallback HTML generation
 */
async function generateFallbackHTML(config, inputPath, outputPath, language) {
  try {
    console.warn(`Falling back to minimal HTML settings for ${outputPath}`);
    
    // Create a minimal pandoc command
    const fallbackCmd = [
      'pandoc',
      `"${inputPath}"`,
      `-o "${outputPath}"`,
      '-t html',
      `--metadata=title:"${config.title || 'Untitled'}"`,
      `--metadata=author:"${config.author || 'Unknown Author'}"`,
      `--metadata=lang:"${language}"`,
      '--standalone',
      '--toc',
      '--toc-depth=2'
    ].join(' ');
    
    const result = await runCommand(fallbackCmd);
    
    return createResult(true, 'html', {
      outputPath,
      command: fallbackCmd,
      fallback: true,
      stdout: result.stdout,
      stderr: result.stderr
    });
  } catch (error) {
    return createResult(false, 'html', {
      error,
      errorMessage: `Fallback HTML generation failed: ${error.message}`
    });
  }
}

/**
 * Post-process HTML output to add additional features
 * 
 * @param {string} htmlPath - Path to HTML file
 * @param {Object} config - Book configuration
 * @returns {Promise<Object>} - Result of post-processing
 */
async function postProcessHTML(htmlPath, config) {
  try {
    if (!fileExists(htmlPath)) {
      throw new Error(`HTML file not found: ${htmlPath}`);
    }
    
    let html = fs.readFileSync(htmlPath, 'utf-8');
    
    // Add any custom post-processing here
    // For example, adding custom headers, footers, or scripts
    
    // Add book title and author to header if not already present
    if (html.indexOf('<title>') === -1 && config.title) {
      const titleTag = `<title>${config.title}</title>`;
      html = html.replace('</head>', `${titleTag}\n</head>`);
    }
    
    // Write updated HTML
    fs.writeFileSync(htmlPath, html);
    
    return createResult(true, 'html', {
      path: htmlPath,
      modified: true
    });
  } catch (error) {
    return createResult(false, 'html', {
      error,
      errorMessage: `HTML post-processing failed: ${error.message}`
    });
  }
}

module.exports = {
  generateHTML,
  generateFallbackHTML,
  postProcessHTML
};
