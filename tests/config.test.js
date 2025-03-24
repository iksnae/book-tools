const fs = require('fs');
const path = require('path');
const yaml = require('yaml');
const mockFs = require('mock-fs');

// Module to test
const { 
  loadExtendedConfig, 
  convertLegacyConfig,
  loadConfig,
  getDefaultConfig,
  getPandocArgs
} = require('../src/config');

describe('Configuration Module', () => {
  
  afterEach(() => {
    // Restore the file system after each test
    mockFs.restore();
  });
  
  describe('loadExtendedConfig', () => {
    it('should add default format settings if not present', () => {
      const config = {
        title: 'Test Book',
        author: 'Test Author'
      };
      
      const result = loadExtendedConfig(config);
      
      expect(result.formatSettings).toBeDefined();
      expect(result.formatSettings.pdf).toBeDefined();
      expect(result.formatSettings.epub).toBeDefined();
      expect(result.formatSettings.html).toBeDefined();
    });
    
    it('should preserve existing format settings', () => {
      const config = {
        title: 'Test Book',
        author: 'Test Author',
        formatSettings: {
          pdf: {
            paperSize: 'a4',
            fontSize: '12pt'
          }
        }
      };
      
      const result = loadExtendedConfig(config);
      
      expect(result.formatSettings.pdf.paperSize).toBe('a4');
      expect(result.formatSettings.pdf.fontSize).toBe('12pt');
    });
    
    it('should handle legacy format settings', () => {
      const config = {
        title: 'Test Book',
        author: 'Test Author',
        pdf: {
          paper_size: 'a4',
          font_size: '12pt'
        }
      };
      
      const result = loadExtendedConfig(config);
      
      expect(result.formatSettings.pdf.paperSize).toBe('a4');
      expect(result.formatSettings.pdf.fontSize).toBe('12pt');
    });
  });
  
  describe('convertLegacyConfig', () => {
    it('should convert legacy config to new format', () => {
      const legacyConfig = {
        title: 'Legacy Book',
        subtitle: 'A Legacy Book',
        author: 'Legacy Author',
        file_prefix: 'legacy-book',
        language: 'en',
        outputs: {
          pdf: true,
          epub: true,
          mobi: false,
          html: true
        },
        pdf: {
          paper_size: 'letter',
          margin_top: '1in'
        }
      };
      
      const result = convertLegacyConfig(legacyConfig);
      
      expect(result.title).toBe('Legacy Book');
      expect(result.subtitle).toBe('A Legacy Book');
      expect(result.author).toBe('Legacy Author');
      expect(result.filePrefix).toBe('legacy-book');
      expect(result.languages).toEqual(['en']);
      expect(result.formats.pdf).toBe(true);
      expect(result.formats.epub).toBe(true);
      expect(result.formats.mobi).toBe(false);
      expect(result.formats.html).toBe(true);
      expect(result.formatSettings.pdf.paperSize).toBe('letter');
      expect(result.formatSettings.pdf.marginTop).toBe('1in');
    });
    
    it('should handle languages array in legacy config', () => {
      const legacyConfig = {
        title: 'Legacy Book',
        author: 'Legacy Author',
        languages: ['en', 'es', 'fr']
      };
      
      const result = convertLegacyConfig(legacyConfig);
      
      expect(result.languages).toEqual(['en', 'es', 'fr']);
    });
  });
  
  describe('loadConfig', () => {
    it('should load config from file system', () => {
      // Mock the file system
      mockFs({
        'book.yaml': yaml.stringify({
          title: 'Mock Book',
          author: 'Mock Author',
          filePrefix: 'mock-book'
        })
      });
      
      const result = loadConfig('book.yaml');
      
      expect(result.title).toBe('Mock Book');
      expect(result.author).toBe('Mock Author');
      expect(result.filePrefix).toBe('mock-book');
    });
    
    it('should detect and convert legacy config', () => {
      // Mock the file system
      mockFs({
        'book.yaml': yaml.stringify({
          title: 'Legacy Book',
          author: 'Legacy Author',
          file_prefix: 'legacy-book',
          outputs: {
            pdf: true
          }
        })
      });
      
      const result = loadConfig('book.yaml');
      
      expect(result.title).toBe('Legacy Book');
      expect(result.filePrefix).toBe('legacy-book');
      expect(result.formats.pdf).toBe(true);
    });
    
    it('should return default config if file not found', () => {
      // Mock empty file system
      mockFs({});
      
      const result = loadConfig('non-existent.yaml');
      
      expect(result.title).toBe('Untitled Book');
      expect(result.author).toBe('Unknown Author');
    });
  });
  
  describe('getDefaultConfig', () => {
    it('should return a default configuration', () => {
      const result = getDefaultConfig();
      
      expect(result.title).toBe('Untitled Book');
      expect(result.author).toBe('Unknown Author');
      expect(result.filePrefix).toBe('book');
      expect(result.languages).toEqual(['en']);
      expect(result.formats.pdf).toBe(true);
      expect(result.formats.epub).toBe(true);
      expect(result.formats.html).toBe(true);
    });
  });
  
  describe('getPandocArgs', () => {
    it('should generate basic pandoc arguments', () => {
      const config = {
        title: 'Test Book',
        author: 'Test Author',
        subtitle: 'A Test Book'
      };
      
      const result = getPandocArgs(config, 'pdf', 'en');
      
      expect(result).toContain('--standalone');
      expect(result).toContain('--metadata=title:Test Book');
      expect(result).toContain('--metadata=author:Test Author');
      expect(result).toContain('--metadata=subtitle:A Test Book');
      expect(result).toContain('--metadata=lang:en');
    });
    
    it('should add PDF-specific arguments', () => {
      const config = {
        title: 'Test Book',
        author: 'Test Author',
        formatSettings: {
          pdf: {
            paperSize: 'a4',
            fontSize: '12pt',
            marginTop: '2in'
          }
        }
      };
      
      // Mock a template file
      mockFs({
        'templates/pdf/custom.latex': 'template content'
      });
      
      config.formatSettings.pdf.template = 'templates/pdf/custom.latex';
      
      const result = getPandocArgs(config, 'pdf', 'en');
      
      expect(result).toContain('--variable=papersize:a4');
      expect(result).toContain('--variable=fontsize:12pt');
      expect(result).toContain('--variable=margin-top:2in');
      expect(result).toContain('--template=templates/pdf/custom.latex');
    });
    
    it('should add EPUB-specific arguments', () => {
      const config = {
        title: 'Test Book',
        author: 'Test Author',
        formatSettings: {
          epub: {
            tocDepth: 3
          }
        }
      };
      
      // Mock cover image and CSS file
      mockFs({
        'book/images/cover.png': 'image content',
        'templates/epub/custom.css': 'css content'
      });
      
      config.formatSettings.epub.coverImage = 'book/images/cover.png';
      config.formatSettings.epub.css = 'templates/epub/custom.css';
      
      const result = getPandocArgs(config, 'epub', 'en');
      
      expect(result).toContain('--epub-cover-image=book/images/cover.png');
      expect(result).toContain('--css=templates/epub/custom.css');
      expect(result).toContain('--toc-depth=3');
      expect(result).toContain('--toc');
    });
    
    it('should add HTML-specific arguments', () => {
      const config = {
        title: 'Test Book',
        author: 'Test Author',
        formatSettings: {
          html: {
            toc: true,
            tocDepth: 2,
            sectionDivs: true,
            selfContained: true
          }
        }
      };
      
      // Mock template and CSS file
      mockFs({
        'templates/html/custom.html': 'template content',
        'templates/html/custom.css': 'css content'
      });
      
      config.formatSettings.html.template = 'templates/html/custom.html';
      config.formatSettings.html.css = 'templates/html/custom.css';
      
      const result = getPandocArgs(config, 'html', 'en');
      
      expect(result).toContain('--template=templates/html/custom.html');
      expect(result).toContain('--css=templates/html/custom.css');
      expect(result).toContain('--toc');
      expect(result).toContain('--toc-depth=2');
      expect(result).toContain('--section-divs');
      expect(result).toContain('--self-contained');
    });
  });
});
