const path = require('path');
const fs = require('fs');
const mockFs = require('mock-fs');
const { findProjectRoot, loadConfig, ensureDirectoryExists, buildFileNames } = require('../src/utils');

// Mock the child_process execSync
jest.mock('child_process', () => ({
  execSync: jest.fn((command, options) => {
    if (command === 'failing-command') {
      if (options.stdio === 'pipe') {
        return null;
      }
      throw new Error('Command failed');
    }
    return Buffer.from('command output');
  })
}));

describe('Utils', () => {
  beforeEach(() => {
    // Set up a mock file system
    mockFs({
      '/project-root': {
        'book.yaml': 'title: "Test Book"\nsubtitle: "A Test Subtitle"\nauthor: "Test Author"\nfile_prefix: "test-book"\nlanguages:\n  - en\n  - es',
        'book': {
          'en': {
            'chapter-01': {
              '00-introduction.md': '# Introduction\n\nThis is the intro.',
              'images': {}
            }
          }
        },
        'build': {}
      }
    });
  });

  afterEach(() => {
    // Restore the file system
    mockFs.restore();
    jest.clearAllMocks();
  });

  describe('findProjectRoot', () => {
    it('should find the project root directory', () => {
      // Mock process.cwd() to return a specific path
      const originalCwd = process.cwd;
      process.cwd = jest.fn().mockReturnValue('/project-root/book/en/chapter-01');
      
      const result = findProjectRoot();
      
      expect(result).toBe('/project-root');
      
      // Restore original process.cwd
      process.cwd = originalCwd;
    });

    it('should throw error if project root is not found', () => {
      // Mock process.cwd() to return a path without book.yaml
      const originalCwd = process.cwd;
      process.cwd = jest.fn().mockReturnValue('/no-project-root');
      
      expect(() => findProjectRoot()).toThrow();
      
      // Restore original process.cwd
      process.cwd = originalCwd;
    });
  });

  describe('loadConfig', () => {
    it('should load configuration from book.yaml', () => {
      // Mock findProjectRoot to return our mock project root
      jest.spyOn(path, 'join').mockImplementation((...args) => {
        if (args[1] === 'book.yaml') {
          return '/project-root/book.yaml';
        }
        return path.posix.join(...args);
      });
      
      const config = loadConfig();
      
      expect(config).toEqual({
        title: 'Test Book',
        subtitle: 'A Test Subtitle',
        author: 'Test Author',
        file_prefix: 'test-book',
        languages: ['en', 'es']
      });
    });

    it('should return default config if book.yaml is not found', () => {
      // Mock findProjectRoot and fs.existsSync
      jest.spyOn(path, 'join').mockReturnValue('/project-root/no-such-file');
      const existsSyncSpy = jest.spyOn(fs, 'existsSync').mockReturnValue(false);
      
      const config = loadConfig();
      
      expect(config).toEqual({
        title: "My Book",
        subtitle: "A Book Built with the Template System",
        author: "Author Name",
        file_prefix: "my-book",
        languages: ["en"]
      });
      
      existsSyncSpy.mockRestore();
    });
  });

  describe('ensureDirectoryExists', () => {
    it('should create directory if it does not exist', () => {
      const dirPath = '/project-root/new-dir';
      
      // Verify directory doesn't exist
      expect(fs.existsSync(dirPath)).toBe(false);
      
      // Call the function
      const result = ensureDirectoryExists(dirPath);
      
      // Check the result
      expect(result).toBe(true);
      
      // Verify directory was created
      expect(fs.existsSync(dirPath)).toBe(true);
    });

    it('should return true if directory already exists', () => {
      const dirPath = '/project-root/book';
      
      // Verify directory exists
      expect(fs.existsSync(dirPath)).toBe(true);
      
      // Call the function
      const result = ensureDirectoryExists(dirPath);
      
      // Check the result
      expect(result).toBe(true);
    });
  });

  describe('buildFileNames', () => {
    it('should build file names for English language', () => {
      // Mock loadConfig to return our test config
      jest.spyOn(path, 'join').mockImplementation((...args) => {
        if (args[1] === 'book.yaml') {
          return '/project-root/book.yaml';
        }
        return path.posix.join(...args);
      });
      
      const fileNames = buildFileNames('en');
      
      expect(fileNames).toEqual({
        pdf: 'test-book.pdf',
        epub: 'test-book.epub',
        mobi: 'test-book.mobi',
        html: 'test-book.html',
        markdown: 'test-book.md'
      });
    });

    it('should build file names for non-English language', () => {
      // Mock loadConfig to return our test config
      jest.spyOn(path, 'join').mockImplementation((...args) => {
        if (args[1] === 'book.yaml') {
          return '/project-root/book.yaml';
        }
        return path.posix.join(...args);
      });
      
      const fileNames = buildFileNames('es');
      
      expect(fileNames).toEqual({
        pdf: 'test-book-es.pdf',
        epub: 'test-book-es.epub',
        mobi: 'test-book-es.mobi',
        html: 'test-book-es.html',
        markdown: 'test-book-es.md'
      });
    });
  });
});