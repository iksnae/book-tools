/**
 * EPUB Generator Module
 * 
 * This module provides functions for generating EPUB output
 * from markdown sources using pandoc.
 */

const path = require('path');
const fs = require('fs');
const { runCommand, createPandocCommand } = require('../utils');
const { getResourcePaths, fileExists, createResult } = require('./utils');

/**
 * Generate EPUB from markdown
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output EPUB file
 * @param {string} language - Language code
 * @param {Object} options - Additional options
 * @returns {Promise<Object>} - Result of EPUB generation
 */
async function generateEPUB(config, inputPath, outputPath, language, options = {}) {
  try {
    // Get resource paths for this language
    const projectRoot = path.dirname(path.dirname(path.dirname(inputPath)));
    const resourcePaths = getResourcePaths(projectRoot, language);
    
    // Get EPUB-specific settings
    const epubSettings = config.formatSettings?.epub || {};
    
    // Add cover image if specified and exists
    const coverImagePath = epubSettings.coverImage || 'book/images/cover.png';
    const hasCoverImage = fileExists(path.join(projectRoot, coverImagePath));
    
    // Generate pandoc command
    const command = createPandocCommand(
      config,
      inputPath, 
      outputPath, 
      'epub', 
      language, 
      resourcePaths
    );
    
    // Execute command
    try {
      const result = await runCommand(command);
      return createResult(true, 'epub', {
        outputPath,
        command,
        hasCoverImage,
        stdout: result.stdout,
        stderr: result.stderr
      });
    } catch (error) {
      // Try fallback if configured
      if (epubSettings.fallback !== false) {
        return await generateFallbackEPUB(config, inputPath, outputPath, language);
      }
      throw error;
    }
  } catch (error) {
    return createResult(false, 'epub', {
      error,
      errorMessage: error.message
    });
  }
}

/**
 * Generate EPUB with fallback settings
 * 
 * @param {Object} config - Book configuration
 * @param {string} inputPath - Path to input markdown file
 * @param {string} outputPath - Path to output EPUB file
 * @param {string} language - Language code
 * @returns {Promise<Object>} - Result of fallback EPUB generation
 */
async function generateFallbackEPUB(config, inputPath, outputPath, language) {
  try {
    console.warn(`Falling back to minimal EPUB settings for ${outputPath}`);
    
    // Create a minimal pandoc command
    const fallbackCmd = [
      'pandoc',
      `"${inputPath}"`,
      `-o "${outputPath}"`,
      '-t epub',
      `--metadata=title:"${config.title || 'Untitled'}"`,
      `--metadata=author:"${config.author || 'Unknown Author'}"`,
      `--metadata=lang:"${language}"`,
      '--toc',
      '--toc-depth=2'
    ].join(' ');
    
    const result = await runCommand(fallbackCmd);
    
    return createResult(true, 'epub', {
      outputPath,
      command: fallbackCmd,
      fallback: true,
      stdout: result.stdout,
      stderr: result.stderr
    });
  } catch (error) {
    return createResult(false, 'epub', {
      error,
      errorMessage: `Fallback EPUB generation failed: ${error.message}`
    });
  }
}

/**
 * Validate EPUB settings
 * 
 * @param {Object} epubSettings - EPUB settings object
 * @param {string} projectRoot - Path to project root
 * @returns {Object} - Validation result
 */
function validateEPUBSettings(epubSettings, projectRoot) {
  const result = {
    valid: true,
    warnings: []
  };
  
  // Check cover image
  if (epubSettings.coverImage) {
    const coverPath = path.isAbsolute(epubSettings.coverImage) 
      ? epubSettings.coverImage
      : path.join(projectRoot, epubSettings.coverImage);
      
    if (!fileExists(coverPath)) {
      result.warnings.push(`Cover image not found: ${epubSettings.coverImage}`);
    }
  }
  
  // Check CSS file
  if (epubSettings.css) {
    const cssPath = path.isAbsolute(epubSettings.css)
      ? epubSettings.css
      : path.join(projectRoot, epubSettings.css);
      
    if (!fileExists(cssPath)) {
      result.warnings.push(`CSS file not found: ${epubSettings.css}`);
    }
  }
  
  return result;
}

module.exports = {
  generateEPUB,
  generateFallbackEPUB,
  validateEPUBSettings
};
