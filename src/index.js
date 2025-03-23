const fs = require('fs');
const path = require('path');
const fsExtra = require('fs-extra');
const { findProjectRoot, runCommand, loadConfig, ensureDirectoryExists, getLanguages, buildFileNames } = require('./utils');

/**
 * Build a book with the specified options
 * @param {Object} options - Build options
 * @param {boolean} options.allLanguages - Whether to build all languages
 * @param {string} options.lang - Specific language to build
 * @param {boolean} options.skipPdf - Whether to skip PDF generation
 * @param {boolean} options.skipEpub - Whether to skip EPUB generation
 * @param {boolean} options.skipMobi - Whether to skip MOBI generation
 * @param {boolean} options.skipHtml - Whether to skip HTML generation
 * @returns {Promise<Object>} Build result
 */
async function buildBook(options = {}) {
  const projectRoot = findProjectRoot();
  
  // Prepare directories
  ensureDirectoryExists(path.join(projectRoot, 'build'));
  ensureDirectoryExists(path.join(projectRoot, 'templates', 'pdf'));
  ensureDirectoryExists(path.join(projectRoot, 'templates', 'epub'));
  ensureDirectoryExists(path.join(projectRoot, 'templates', 'html'));
  ensureDirectoryExists(path.join(projectRoot, 'build', 'images'));
  ensureDirectoryExists(path.join(projectRoot, 'book', 'images'));
  
  // Determine languages to build
  let languages = [];
  if (options.allLanguages) {
    languages = getLanguages();
  } else if (options.lang) {
    languages = [options.lang];
  } else {
    // Default to first language
    languages = [getLanguages()[0]];
  }
  
  // Build command
  let buildCommand = './tools/scripts/build.sh';
  
  if (options.allLanguages) {
    buildCommand += ' --all-languages';
  } else if (options.lang) {
    buildCommand += ` --lang=${options.lang}`;
  }
  
  if (options.skipPdf) {
    buildCommand += ' --skip-pdf';
  }
  
  if (options.skipEpub) {
    buildCommand += ' --skip-epub';
  }
  
  if (options.skipMobi) {
    buildCommand += ' --skip-mobi';
  }
  
  if (options.skipHtml) {
    buildCommand += ' --skip-html';
  }
  
  // Run the build command
  try {
    await runCommand(buildCommand);
    
    // Get built files info
    const buildDir = path.join(projectRoot, 'build');
    const builtFiles = [];
    
    if (fs.existsSync(buildDir)) {
      const files = fs.readdirSync(buildDir)
        .filter(file => !fs.statSync(path.join(buildDir, file)).isDirectory());
      
      for (const file of files) {
        const stats = fs.statSync(path.join(buildDir, file));
        const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);
        builtFiles.push({
          name: file,
          path: path.join(buildDir, file),
          size: fileSizeMB
        });
      }
    }
    
    return {
      success: true,
      languages,
      builtFiles
    };
  } catch (error) {
    throw new Error(`Build failed: ${error.message}`);
  }
}

/**
 * Create a new chapter
 * @param {Object} options - Chapter options
 * @param {string} options.number - Chapter number (e.g., '04')
 * @param {string} options.title - Chapter title
 * @param {string} options.lang - Language code (default: 'en')
 * @returns {Promise<Object>} Chapter creation result
 */
async function createChapter(options) {
  const { number, title, lang = 'en' } = options;
  
  if (!number || !/^\d{2}$/.test(number)) {
    throw new Error('Chapter number must be a two-digit number (e.g., 04)');
  }
  
  if (!title || !title.trim()) {
    throw new Error('Chapter title is required');
  }
  
  const projectRoot = findProjectRoot();
  
  // Format the chapter folder name
  const chapterFolder = `chapter-${number}`;
  
  // Create the full path
  const chapterPath = path.join(projectRoot, 'book', lang, chapterFolder);
  const imagesPath = path.join(chapterPath, 'images');
  
  // Create the chapter directory structure
  try {
    // Create chapter directory if it doesn't exist
    ensureDirectoryExists(chapterPath);
    
    // Create images directory if it doesn't exist
    ensureDirectoryExists(imagesPath);
    
    // Create the introduction file
    const introContent = `# ${title}\n\nThis is the introduction to your chapter.\n`;
    const introFile = path.join(chapterPath, '00-introduction.md');
    fs.writeFileSync(introFile, introContent);
    
    // Create a sample section file
    const sectionContent = `## First Section\n\nThis is the first section of your chapter.\n`;
    const sectionFile = path.join(chapterPath, '01-section.md');
    fs.writeFileSync(sectionFile, sectionContent);
    
    // Create a README in the images folder
    const readmeContent = `# Images for Chapter ${number}: ${title}\n\nPlace chapter-specific images in this directory.\n`;
    const readmeFile = path.join(imagesPath, 'README.md');
    fs.writeFileSync(readmeFile, readmeContent);
    
    return {
      success: true,
      chapterNumber: number,
      chapterTitle: title,
      language: lang,
      path: chapterPath,
      files: [
        introFile,
        sectionFile,
        readmeFile
      ]
    };
  } catch (error) {
    throw new Error(`Failed to create chapter: ${error.message}`);
  }
}

/**
 * Check the structure of a chapter
 * @param {Object} options - Options
 * @param {string} options.number - Chapter number
 * @param {string} options.lang - Language code (default: 'en')
 * @returns {Promise<Object>} Chapter structure information
 */
async function checkChapter(options) {
  const { number, lang = 'en' } = options;
  const projectRoot = findProjectRoot();
  const langPath = path.join(projectRoot, 'book', lang);
  
  // Check if the language directory exists
  if (!fs.existsSync(langPath)) {
    throw new Error(`Language directory not found: ${langPath}`);
  }
  
  // If no specific chapter was provided, list all chapters
  if (!number) {
    const items = fs.readdirSync(langPath);
    const chapters = items
      .filter(item => {
        const itemPath = path.join(langPath, item);
        return fs.statSync(itemPath).isDirectory() && item.startsWith('chapter-');
      })
      .map(chapter => {
        const chapterPath = path.join(langPath, chapter);
        const files = fs.readdirSync(chapterPath);
        const sectionCount = files.filter(file => file.endsWith('.md')).length;
        
        return {
          name: chapter,
          path: chapterPath,
          sectionCount
        };
      });
    
    return {
      language: lang,
      chapters
    };
  }
  
  // Check a specific chapter
  const chapterFolder = `chapter-${number}`;
  const chapterPath = path.join(langPath, chapterFolder);
  
  if (!fs.existsSync(chapterPath)) {
    throw new Error(`Chapter directory not found: ${chapterPath}`);
  }
  
  // List all files in the chapter directory
  const items = fs.readdirSync(chapterPath);
  
  // Check for required files and directories
  const hasIntro = items.some(item => item === '00-introduction.md');
  const hasSection = items.some(item => /^\d+-section\.md$/.test(item) || /^\d+-[a-z0-9-]+\.md$/.test(item));
  const hasImagesDir = items.some(item => item === 'images' && fs.statSync(path.join(chapterPath, item)).isDirectory());
  
  // Get markdown files
  const markdownFiles = items
    .filter(item => item.endsWith('.md'))
    .map(file => {
      const filePath = path.join(chapterPath, file);
      const firstLine = fs.readFileSync(filePath, 'utf8').split('\\n')[0].trim();
      const title = firstLine.startsWith('#') ? firstLine.replace(/^#+\\s*/, '') : 'Untitled';
      
      return {
        name: file,
        path: filePath,
        title
      };
    });
  
  // Get images
  const images = [];
  if (hasImagesDir) {
    const imagesPath = path.join(chapterPath, 'images');
    const imageFiles = fs.readdirSync(imagesPath);
    
    for (const file of imageFiles) {
      const filePath = path.join(imagesPath, file);
      if (fs.statSync(filePath).isFile()) {
        const stats = fs.statSync(filePath);
        const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);
        
        images.push({
          name: file,
          path: filePath,
          size: fileSizeMB
        });
      }
    }
  }
  
  return {
    language: lang,
    chapterNumber: number,
    hasIntro,
    hasSection,
    hasImagesDir,
    markdownFiles,
    images
  };
}

/**
 * Get book information
 * @returns {Promise<Object>} Book information
 */
async function getBookInfo() {
  const config = loadConfig();
  const projectRoot = findProjectRoot();
  const buildDir = path.join(projectRoot, 'build');
  
  const builtFiles = [];
  if (fs.existsSync(buildDir)) {
    const files = fs.readdirSync(buildDir)
      .filter(file => !fs.statSync(path.join(buildDir, file)).isDirectory());
    
    for (const file of files) {
      const stats = fs.statSync(path.join(buildDir, file));
      const fileSizeMB = (stats.size / (1024 * 1024)).toFixed(2);
      builtFiles.push({
        name: file,
        path: path.join(buildDir, file),
        size: fileSizeMB
      });
    }
  }
  
  return {
    title: config.title,
    subtitle: config.subtitle,
    author: config.author,
    filePrefix: config.file_prefix,
    languages: config.languages || ['en'],
    formats: {
      pdf: config.pdf !== false,
      epub: config.epub !== false,
      mobi: config.mobi !== false,
      html: config.html !== false
    },
    builtFiles
  };
}

/**
 * Clean build artifacts
 * @returns {Promise<Object>} Clean result
 */
async function cleanBuild() {
  const projectRoot = findProjectRoot();
  const buildDir = path.join(projectRoot, 'build');
  
  if (fs.existsSync(buildDir)) {
    // Count the number of files to remove
    const files = fs.readdirSync(buildDir);
    let filesRemoved = 0;
    
    // Delete all files in the build directory
    for (const file of files) {
      const filePath = path.join(buildDir, file);
      try {
        if (fs.statSync(filePath).isDirectory()) {
          // Use recursive deletion for directories
          fsExtra.removeSync(filePath);
          filesRemoved++;
        } else {
          // Simple delete for files
          fs.unlinkSync(filePath);
          filesRemoved++;
        }
      } catch (err) {
        console.warn(`Could not delete ${file}: ${err.message}`);
      }
    }
    
    return {
      success: true,
      filesRemoved
    };
  }
  
  return {
    success: false,
    filesRemoved: 0
  };
}

module.exports = {
  buildBook,
  createChapter,
  checkChapter,
  getBookInfo,
  cleanBuild
};