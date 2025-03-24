const path = require('path');
const fs = require('fs');
const { 
  findProjectRoot, 
  loadConfig, 
  ensureDirectoryExists,
  buildFileNames,
  runScript,
  getFormatSettings,
  writeLegacyConfig
} = require('./utils');

/**
 * Build a book in the specified format(s)
 * 
 * @param {Object} options - Build options
 * @param {boolean} [options.allLanguages=false] - Whether to build for all languages
 * @param {string} [options.language='en'] - Language to build for
 * @param {Array<string>} [options.formats=['pdf']] - Formats to build
 * @param {boolean} [options.useLegacyScripts=true] - Whether to use legacy build scripts
 * @returns {Promise<Object>} - Build result
 */
async function buildBook(options = {}) {
  try {
    const projectRoot = findProjectRoot();
    const config = loadConfig(projectRoot);
    
    // Determine which languages to build
    const languages = options.allLanguages 
      ? config.languages 
      : [options.language || 'en'];
    
    // Determine which formats to build
    const requestedFormats = options.formats || ['pdf'];
    const formats = requestedFormats.filter(format => {
      // Check if the format is enabled in the configuration
      return config.formats && config.formats[format] !== false;
    });
    
    if (formats.length === 0) {
      return {
        success: false,
        error: new Error('No enabled formats requested for build')
      };
    }
    
    const results = [];
    
    for (const language of languages) {
      const fileNames = buildFileNames(language, projectRoot);
      
      // Ensure build directory exists
      const buildDir = path.dirname(fileNames.input);
      ensureDirectoryExists(buildDir);
      
      // Create a temporary configuration file for legacy scripts
      const tempConfigPath = path.join(buildDir, 'book-config.yaml');
      if (options.useLegacyScripts !== false) {
        writeLegacyConfig(config, tempConfigPath);
      }
      
      const buildResult = {
        success: true,
        language,
        formats,
        files: {
          input: fileNames.input
        }
      };
      
      // Perform the actual build (to be implemented with proper scripts)
      // For now, this just sets up the file paths
      for (const format of formats) {
        if (fileNames[format]) {
          // Get the format-specific settings
          const formatSettings = getFormatSettings(config, format);
          
          // TODO: Implement actual build logic for each format
          // This would involve running scripts or using libraries
          // For now, we just set up the file path
          
          buildResult.files[format] = fileNames[format];
        }
      }
      
      results.push(buildResult);
    }
    
    // Clean up temporary files
    // TODO: Implement cleanup
    
    // Return the first result for simplicity if only building one language
    return languages.length === 1 ? results[0] : { success: true, results };
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

/**
 * Create a new chapter
 * 
 * @param {Object} options - Chapter options
 * @param {string} options.chapterNumber - Chapter number (e.g., "01")
 * @param {string} options.title - Chapter title
 * @param {string} [options.language='en'] - Language code
 * @returns {Promise<Object>} - Result object
 */
async function createChapter(options) {
  try {
    const projectRoot = findProjectRoot();
    const config = loadConfig(projectRoot);
    const language = options.language || 'en';
    const chapterNumber = options.chapterNumber;
    const title = options.title;
    
    // Validate language
    if (!config.languages.includes(language)) {
      return {
        success: false,
        error: new Error(`Language "${language}" is not configured in book.yaml`)
      };
    }
    
    // Create chapter directory
    const chapterDir = path.join(projectRoot, 'book', language, `chapter-${chapterNumber}`);
    ensureDirectoryExists(chapterDir);
    
    // Create introduction file
    const introFile = path.join(chapterDir, '00-introduction.md');
    fs.writeFileSync(introFile, `# ${title}\n\nIntroduction to the chapter.\n`);
    
    // Create images directory
    const imagesDir = path.join(chapterDir, 'images');
    ensureDirectoryExists(imagesDir);
    
    // Create README in images directory
    const imagesReadme = path.join(imagesDir, 'README.md');
    fs.writeFileSync(imagesReadme, `# Images for Chapter ${chapterNumber}\n\nPlace chapter images in this directory.\n`);
    
    return {
      success: true,
      chapterNumber,
      chapterTitle: title,
      language,
      path: chapterDir,
      files: [
        introFile,
        imagesReadme
      ]
    };
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

/**
 * Check the structure of a chapter
 * 
 * @param {Object} options - Chapter options
 * @param {string} options.chapterNumber - Chapter number (e.g., "01")
 * @param {string} [options.language='en'] - Language code
 * @returns {Promise<Object>} - Result with chapter information
 */
async function checkChapter(options) {
  try {
    const projectRoot = findProjectRoot();
    const config = loadConfig(projectRoot);
    const language = options.language || 'en';
    const chapterNumber = options.chapterNumber;
    
    // Validate language
    if (!config.languages.includes(language)) {
      return {
        success: false,
        error: new Error(`Language "${language}" is not configured in book.yaml`)
      };
    }
    
    const chapterDir = path.join(projectRoot, 'book', language, `chapter-${chapterNumber}`);
    
    if (!fs.existsSync(chapterDir)) {
      return {
        success: false,
        error: new Error(`Chapter directory not found: ${chapterDir}`)
      };
    }
    
    // Check for introduction file
    const introFile = path.join(chapterDir, '00-introduction.md');
    const hasIntro = fs.existsSync(introFile);
    
    // Check for any section files
    const files = fs.readdirSync(chapterDir);
    const sectionFiles = files.filter(file => 
      file.match(/^\d{2}-.*\.md$/) && !file.startsWith('00-')
    );
    const hasSection = sectionFiles.length > 0;
    
    // Check for images directory
    const imagesDir = path.join(chapterDir, 'images');
    const hasImagesDir = fs.existsSync(imagesDir);
    
    // Get all markdown files
    const markdownFiles = files
      .filter(file => file.endsWith('.md'))
      .map(file => {
        const filePath = path.join(chapterDir, file);
        let title = '';
        
        try {
          const content = fs.readFileSync(filePath, 'utf-8');
          const titleMatch = content.match(/^#\s+(.+)$/m);
          if (titleMatch) {
            title = titleMatch[1].trim();
          }
        } catch (e) {
          // Ignore errors
        }
        
        return {
          name: file,
          title
        };
      });
    
    // Get images if the directory exists
    let images = [];
    if (hasImagesDir) {
      try {
        images = fs.readdirSync(imagesDir)
          .filter(file => !file.endsWith('.md'));
      } catch (e) {
        // Ignore errors
      }
    }
    
    return {
      success: true,
      language,
      chapterNumber,
      hasIntro,
      hasSection,
      hasImagesDir,
      markdownFiles,
      images
    };
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

/**
 * Get book information
 * 
 * @returns {Promise<Object>} - Book information
 */
async function getBookInfo() {
  try {
    const projectRoot = findProjectRoot();
    const config = loadConfig(projectRoot);
    
    // Look for built files
    const builtFiles = [];
    
    // Check the build directory for each language
    for (const language of config.languages || ['en']) {
      const buildDir = path.join(projectRoot, 'build', language);
      
      if (fs.existsSync(buildDir)) {
        try {
          const files = fs.readdirSync(buildDir);
          
          files.forEach(file => {
            if (file !== 'book.md' && !file.endsWith('.tmp') && !file.endsWith('.yaml')) {
              builtFiles.push(path.join(buildDir, file));
            }
          });
        } catch (e) {
          // Ignore errors
        }
      }
    }
    
    // Return the configuration with built files
    return {
      ...config,
      builtFiles
    };
  } catch (error) {
    return {
      title: 'Unknown',
      error
    };
  }
}

/**
 * Clean build artifacts
 * 
 * @returns {Promise<Object>} - Result of cleaning
 */
async function cleanBuild() {
  try {
    const projectRoot = findProjectRoot();
    const config = loadConfig(projectRoot);
    
    let filesRemoved = 0;
    
    // Remove files from build directory for each language
    for (const language of config.languages || ['en']) {
      const buildDir = path.join(projectRoot, 'build', language);
      
      if (fs.existsSync(buildDir)) {
        try {
          const files = fs.readdirSync(buildDir);
          
          for (const file of files) {
            const filePath = path.join(buildDir, file);
            fs.unlinkSync(filePath);
            filesRemoved++;
          }
        } catch (e) {
          // Ignore errors
        }
      }
    }
    
    return {
      success: true,
      filesRemoved
    };
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

/**
 * Validate book configuration
 * 
 * @returns {Promise<Object>} - Validation result
 */
async function validateConfig() {
  try {
    const projectRoot = findProjectRoot();
    const config = loadConfig(projectRoot);
    
    const validationResult = {
      success: true,
      config,
      warnings: [],
      errors: []
    };
    
    // Check essential properties
    if (!config.title) {
      validationResult.warnings.push('Book title is not defined');
    }
    
    if (!config.author) {
      validationResult.warnings.push('Book author is not defined');
    }
    
    // Check languages
    if (!config.languages || config.languages.length === 0) {
      validationResult.errors.push('No languages defined');
      validationResult.success = false;
    }
    
    // Check languages directories
    for (const language of config.languages || []) {
      const langDir = path.join(projectRoot, 'book', language);
      if (!fs.existsSync(langDir)) {
        validationResult.warnings.push(`Language directory not found: ${langDir}`);
      }
    }
    
    // Check format settings
    for (const format of ['pdf', 'epub', 'html']) {
      if (config.formats[format]) {
        const formatSettings = getFormatSettings(config, format);
        
        if (format === 'pdf' && formatSettings.template) {
          const templatePath = path.join(projectRoot, formatSettings.template);
          if (!fs.existsSync(templatePath)) {
            validationResult.warnings.push(`PDF template not found: ${templatePath}`);
          }
        }
        
        if (format === 'epub' && formatSettings.coverImage) {
          const coverPath = path.join(projectRoot, formatSettings.coverImage);
          if (!fs.existsSync(coverPath)) {
            validationResult.warnings.push(`EPUB cover image not found: ${coverPath}`);
          }
        }
        
        if (format === 'html' && formatSettings.template) {
          const templatePath = path.join(projectRoot, formatSettings.template);
          if (!fs.existsSync(templatePath)) {
            validationResult.warnings.push(`HTML template not found: ${templatePath}`);
          }
        }
      }
    }
    
    return validationResult;
  } catch (error) {
    return {
      success: false,
      error
    };
  }
}

module.exports = {
  buildBook,
  createChapter,
  checkChapter,
  getBookInfo,
  cleanBuild,
  validateConfig
};
