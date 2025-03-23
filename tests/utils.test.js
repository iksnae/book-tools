const path = require('path');
const fs = require('fs');
const mockFs = require('mock-fs');
const { 
  findProjectRoot, 
  loadConfig, 
  ensureDirectoryExists,
  buildFileNames
} = require('../src/utils');

// Mock child_process for exec calls
jest.mock('child_process', () => {
  return {
    exec: jest.fn().mockImplementation((command, options, callback) => {
      if (callback) {
        callback(null, { stdout: 'success', stderr: '' });
      }
      return {
        on: jest.fn((event, handler) => {
          if (event === 'close') {
            handler(0);
          }
          return this;
        })
      };
    }),
    execSync: jest.fn().mockReturnValue('success')
  };
});

describe('Utils', () => {
  beforeEach(() => {
    // Set up a mock file system
    mockFs({
      '/project-root': {
        'book.yaml': 'title: Test Book\nsubtitle: Test Subtitle\nauthor: Test Author\nfilePrefix: test-book\nlanguages:\n  - en\n  - es',
        'package.json': '{"name": "test-book", "version": "1.0.0"}',
        'node_modules': {
          'book-tools': {
            'package.json': '{"name": "book-tools", "version": "0.1.0"}'
          }
        },
        'book': {
          'en': {
            'chapter-01': {
              '00-introduction.md': '# Introduction',
              'images': {}
            }
          }
        },
        'build': {}
      },
      '/not-a-project': {
        'some-file.txt': 'Not a project'
      }
    });

    // Mock process.cwd() to return a specific location
    jest.spyOn(process, 'cwd').mockReturnValue('/project-root/src');
  });

  afterEach(() => {
    mockFs.restore();
    jest.restoreAllMocks();
  });

  describe('findProjectRoot', () => {
    test('should find project root by looking for book.yaml', () => {
      const rootPath = findProjectRoot();
      expect(rootPath).toBe('/project-root');
    });

    test('should return null if book.yaml is not found', () => {
      jest.spyOn(process, 'cwd').mockReturnValue('/not-a-project');
      
      try {
        findProjectRoot();
        fail('Should have thrown an error');
      } catch (error) {
        expect(error.message).toContain('Could not find project root');
      }
    });
  });

  describe('loadConfig', () => {
    test('should load configuration from book.yaml', () => {
      const config = loadConfig('/project-root');
      
      expect(config).toEqual({
        title: 'Test Book',
        subtitle: 'Test Subtitle',
        author: 'Test Author',
        filePrefix: 'test-book',
        languages: ['en', 'es']
      });
    });

    test('should return default config if book.yaml is not found', () => {
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
    test('should create directory if it does not exist', () => {
      const dirPath = '/project-root/new-directory';
      
      ensureDirectoryExists(dirPath);
      
      expect(fs.existsSync(dirPath)).toBe(true);
    });

    test('should not throw if directory already exists', () => {
      const dirPath = '/project-root/book';
      
      expect(() => {
        ensureDirectoryExists(dirPath);
      }).not.toThrow();
      
      expect(fs.existsSync(dirPath)).toBe(true);
    });
  });

  describe('buildFileNames', () => {
    test('should build correct file names for English language', () => {
      const fileNames = buildFileNames('en', '/project-root');
      
      expect(fileNames).toEqual({
        input: '/project-root/build/en/book.md',
        pdf: '/project-root/build/en/test-book.pdf',
        epub: '/project-root/build/en/test-book.epub',
        mobi: '/project-root/build/en/test-book.mobi',
        html: '/project-root/build/en/test-book.html'
      });
    });

    test('should build correct file names for Spanish language', () => {
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