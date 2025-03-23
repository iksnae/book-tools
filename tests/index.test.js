const path = require('path');
const fs = require('fs');
const mockFs = require('mock-fs');
const { 
  buildBook, 
  createChapter, 
  checkChapter, 
  getBookInfo,
  cleanBuild
} = require('../src/index');

// Mock utils functions that would be used by index.js
jest.mock('../src/utils', () => ({
  findProjectRoot: jest.fn().mockReturnValue('/project-root'),
  loadConfig: jest.fn().mockReturnValue({
    title: 'Test Book',
    subtitle: 'Testing Book Tools',
    author: 'Test Author',
    filePrefix: 'test-book',
    languages: ['en', 'es'],
    formats: {
      pdf: true,
      epub: true,
      mobi: true,
      html: true
    }
  }),
  ensureDirectoryExists: jest.fn().mockImplementation((dir) => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }),
  buildFileNames: jest.fn().mockImplementation((language) => ({
    input: `/project-root/build/${language}/book.md`,
    pdf: `/project-root/build/${language}/test-book.pdf`,
    epub: `/project-root/build/${language}/test-book.epub`,
    mobi: `/project-root/build/${language}/test-book.mobi`,
    html: `/project-root/build/${language}/test-book.html`
  })),
  runScript: jest.fn().mockResolvedValue({ success: true })
}));

// Mock child_process
jest.mock('child_process', () => ({
  exec: jest.fn((cmd, opts, callback) => {
    if (callback) {
      callback(null, { stdout: 'Success', stderr: '' });
    }
    return {
      on: jest.fn().mockImplementation((event, handler) => {
        if (event === 'close') {
          handler(0); // Simulate successful execution
        }
        return this;
      })
    };
  }),
  execSync: jest.fn().mockReturnValue('Success')
}));

describe('Main Module', () => {
  beforeEach(() => {
    // Set up mock file system
    mockFs({
      '/project-root': {
        'book.yaml': mockYamlFile(),
        'book': {
          'en': {
            'chapter-01': {
              '00-introduction.md': '# Introduction',
              '01-section.md': '## Section 1',
              'images': {
                'README.md': 'Images folder'
              }
            },
            'chapter-02': {
              '00-introduction.md': '# Chapter 2 Intro',
              'images': {}
            }
          },
          'es': {
            'chapter-01': {
              '00-introduction.md': '# Introducción',
              'images': {}
            }
          }
        },
        'build': {
          'en': {
            'book.md': '# Test Book\n\n## Chapter 1\n\n# Introduction\n\n## Section 1',
            'test-book.pdf': Buffer.from([1, 2, 3]),
            'test-book.epub': Buffer.from([4, 5, 6]),
            'test-book.mobi': Buffer.from([7, 8, 9]),
            'test-book.html': '<html><body><h1>Test Book</h1></body></html>'
          },
          'es': {
            'book.md': '# Libro de Prueba\n\n## Capítulo 1\n\n# Introducción',
            'test-book.pdf': Buffer.from([1, 2, 3])
          }
        }
      }
    });
  });

  afterEach(() => {
    mockFs.restore();
    jest.clearAllMocks();
  });

  function mockYamlFile() {
    return `title: Test Book
subtitle: Testing Book Tools
author: Test Author
filePrefix: test-book
languages:
  - en
  - es
formats:
  pdf: true
  epub: true
  mobi: true
  html: true`;
  }

  describe('buildBook', () => {
    test('should build book for specified language and formats', async () => {
      const result = await buildBook({
        language: 'en',
        formats: ['pdf', 'epub']
      });

      expect(result).toEqual(expect.objectContaining({
        success: true,
        language: 'en',
        formats: ['pdf', 'epub']
      }));
    });

    test('should handle build errors gracefully', async () => {
      // Override mock to simulate a failure
      const utils = require('../src/utils');
      utils.runScript.mockRejectedValueOnce(new Error('Build failed'));

      const result = await buildBook({
        language: 'en',
        formats: ['pdf']
      });

      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });
  });

  describe('createChapter', () => {
    test('should create a new chapter with the correct structure', async () => {
      const options = {
        chapterNumber: '03',
        title: 'New Chapter',
        language: 'en'
      };

      const result = await createChapter(options);

      expect(result.success).toBe(true);
      expect(result.chapterNumber).toBe('03');
      expect(result.chapterTitle).toBe('New Chapter');
      expect(result.language).toBe('en');
    });
  });

  describe('checkChapter', () => {
    test('should return chapter information for an existing chapter', async () => {
      const result = await checkChapter({
        chapterNumber: '01',
        language: 'en'
      });

      expect(result.language).toBe('en');
      expect(result.chapterNumber).toBe('01');
      expect(result.hasIntro).toBe(true);
    });

    test('should return error for non-existent chapter', async () => {
      const result = await checkChapter({
        chapterNumber: '99',
        language: 'en'
      });

      expect(result.success).toBe(false);
    });
  });

  describe('getBookInfo', () => {
    test('should return book information from config', async () => {
      const result = await getBookInfo();

      expect(result.title).toBe('Test Book');
      expect(result.subtitle).toBe('Testing Book Tools');
      expect(result.author).toBe('Test Author');
    });
  });

  describe('cleanBuild', () => {
    test('should clean build directory', async () => {
      const result = await cleanBuild();

      expect(result.success).toBe(true);
    });
  });
});