const path = require('path');
const fs = require('fs');
const { 
  findProjectRoot, 
  loadConfig, 
  ensureDirectoryExists,
  buildFileNames,
  runScript
} = require('./utils');

/**
 * Build a book in the specified format(s)
 * 
 * @param {Object} options - Build options
 * @param {boolean} [options.allLanguages=false] - Whether to build for all languages
 * @param {string} [options.language='en'] - Language to build for
 * @param {Array<string>} [options.formats=['pdf']] - Formats to build
 * @returns {Promise<Object>} - Build result
 */
async function buildBook(options = {}) {
  try {
    const projectRoot = findProjectRoot();
    const config = loadConfig(projectRoot);
    
    const languages = options.allLanguages 
      ? config.languages 
      : [options.language || 'en'];
    
    const formats = options.formats || ['pdf'];
    
    const results = [];
    
    for (const language of languages) {
      const fileNames = buildFileNames(language, projectRoot);
      
      // Ensure build directory exists
      const buildDir = path.dirname(fileNames.input);
      ensureDirectoryExists(buildDir);
      
      const buildResult = {
        success: true,
        language,
        formats,
        files: {
          input: fileNames.input
        }
      };
      
      // Add the requested format file paths
      for (const format of formats) {
        if (fileNames[format]) {
          buildResult.files[format] = fileNames[format];
        }
      }
      
      results.push(buildResult);
    }
    
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
    const language = options.language || 'en';
    const chapterNumber = options.chapterNumber;
    const title = options.title;
    
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
    const language = options.language || 'en';
    const chapterNumber = options.chapterNumber;
    
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
            if (file !== 'book.md' && !file.endsWith('.tmp')) {
              builtFiles.push(path.join(buildDir, file));
            }
          });
        } catch (e) {
          // Ignore errors
        }
      }
    }
    
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

module.exports = {
  buildBook,
  createChapter,
  checkChapter,
  getBookInfo,
  cleanBuild
};