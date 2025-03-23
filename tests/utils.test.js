const { 
  findProjectRoot, 
  loadConfig, 
  ensureDirectoryExists,
  buildFileNames
} = require('../src/utils');

// Simple manual mocks to avoid compatibility issues
jest.mock('fs', () => ({
  existsSync: jest.fn(),
  readFileSync: jest.fn(),
  mkdirSync: jest.fn()
}));

jest.mock('js-yaml', () => ({
  load: jest.fn()
}));

jest.mock('child_process', () => ({
  exec: jest.fn(),
  execSync: jest.fn()
}));

describe('Utils', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    
    // Setup fs mocks
    const fs = require('fs');
    fs.existsSync.mockImplementation(path => {
      if (path.includes('book.yaml')) return true;
      return false;
    });
    
    fs.readFileSync.mockImplementation(() => {
      return 'title: Test Book\nsubtitle: Test Subtitle\nauthor: Test Author\nfilePrefix: test-book\nlanguages:\n  - en\n  - es';
    });
    
    // Setup yaml mock
    const yaml = require('js-yaml');
    yaml.load.mockImplementation(() => ({
      title: 'Test Book',
      subtitle: 'Test Subtitle',
      author: 'Test Author',
      filePrefix: 'test-book',
      languages: ['en', 'es']
    }));
    
    // Mock process.cwd
    jest.spyOn(process, 'cwd').mockReturnValue('/project-root/src');
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('findProjectRoot', () => {
    it('finds the project root when book.yaml exists', () => {
      const rootPath = findProjectRoot();
      expect(rootPath).toBe('/project-root');
    });

    it('throws an error when book.yaml is not found', () => {
      const fs = require('fs');
      fs.existsSync.mockReturnValue(false);
      
      expect(() => {
        findProjectRoot();
      }).toThrow();
    });
  });

  describe('loadConfig', () => {
    it('loads configuration from book.yaml', () => {
      const config = loadConfig('/project-root');
      
      expect(config).toEqual({
        title: 'Test Book',
        subtitle: 'Test Subtitle',
        author: 'Test Author',
        filePrefix: 'test-book',
        languages: ['en', 'es']
      });
    });

    it('returns default config if book.yaml is not found', () => {
      const fs = require('fs');
      fs.existsSync.mockReturnValueOnce(false);
      
      const config = loadConfig('/not-a-project');
      
      expect(config).toEqual({
        title: 'Untitled Book',
        subtitle: '',
        author: 'Unknown Author',
        filePrefix: 'book',
        languages: ['en']
      });
    });
  });

  describe('ensureDirectoryExists', () => {
    it('creates directory if it does not exist', () => {
      const fs = require('fs');
      fs.existsSync.mockReturnValueOnce(false);
      
      ensureDirectoryExists('/project-root/new-directory');
      
      expect(fs.mkdirSync).toHaveBeenCalledWith('/project-root/new-directory', { recursive: true });
    });

    it('does not create directory if it already exists', () => {
      const fs = require('fs');
      fs.existsSync.mockReturnValueOnce(true);
      
      ensureDirectoryExists('/project-root/existing-directory');
      
      expect(fs.mkdirSync).not.toHaveBeenCalled();
    });
  });

  describe('buildFileNames', () => {
    it('builds correct file names for English language', () => {
      const fileNames = buildFileNames('en', '/project-root');
      
      expect(fileNames).toEqual({
        input: '/project-root/build/en/book.md',
        pdf: '/project-root/build/en/test-book.pdf',
        epub: '/project-root/build/en/test-book.epub',
        mobi: '/project-root/build/en/test-book.mobi',
        html: '/project-root/build/en/test-book.html'
      });
    });

    it('builds correct file names for Spanish language', () => {
      const fileNames = buildFileNames('es', '/project-root');
      
      expect(fileNames).toEqual({
        input: '/project-root/build/es/book.md',
        pdf: '/project-root/build/es/test-book.pdf',
        epub: '/project-root/build/es/test-book.epub',
        mobi: '/project-root/build/es/test-book.mobi',
        html: '/project-root/build/es/test-book.html'
      });
    });
  });
});