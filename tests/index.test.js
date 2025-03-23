const { 
  buildBook, 
  createChapter, 
  checkChapter, 
  getBookInfo,
  cleanBuild
} = require('../src/index');

// Basic mocks
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
  ensureDirectoryExists: jest.fn(),
  buildFileNames: jest.fn().mockImplementation((language) => ({
    input: `/project-root/build/${language}/book.md`,
    pdf: `/project-root/build/${language}/test-book.pdf`,
    epub: `/project-root/build/${language}/test-book.epub`,
    mobi: `/project-root/build/${language}/test-book.mobi`,
    html: `/project-root/build/${language}/test-book.html`
  })),
  runScript: jest.fn().mockResolvedValue({ success: true })
}));

// Mock fs module
jest.mock('fs', () => ({
  existsSync: jest.fn().mockReturnValue(true),
  mkdirSync: jest.fn(),
  readdirSync: jest.fn().mockReturnValue(['00-introduction.md', '01-section.md', 'images']),
  statSync: jest.fn().mockReturnValue({ isDirectory: () => false }),
  rmSync: jest.fn(),
  writeFileSync: jest.fn()
}));

// Mock child_process
jest.mock('child_process', () => ({
  exec: jest.fn((cmd, opts, callback) => {
    if (callback) {
      callback(null, { stdout: 'Success', stderr: '' });
    }
    return {
      on: jest.fn()
    };
  }),
  execSync: jest.fn().mockReturnValue('Success')
}));

describe('Main Module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    
    // Set up fs mocks for specific test cases
    const fs = require('fs');
    fs.statSync.mockImplementation((path) => ({
      isDirectory: () => path.includes('images') || path.includes('chapter')
    }));
  });

  describe('buildBook', () => {
    it('builds book for specified language and formats', async () => {
      const result = await buildBook({
        language: 'en',
        formats: ['pdf', 'epub']
      });

      expect(result.success).toBe(true);
      expect(result.language).toBe('en');
      expect(result.formats).toEqual(['pdf', 'epub']);
    });

    it('handles build errors gracefully', async () => {
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
    it('creates a new chapter with the correct structure', async () => {
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
    it('returns chapter information for an existing chapter', async () => {
      const result = await checkChapter({
        chapterNumber: '01',
        language: 'en'
      });

      expect(result.language).toBe('en');
      expect(result.chapterNumber).toBe('01');
    });

    it('returns error for non-existent chapter', async () => {
      const fs = require('fs');
      fs.existsSync.mockReturnValueOnce(false);
      
      const result = await checkChapter({
        chapterNumber: '99',
        language: 'en'
      });

      expect(result.success).toBe(false);
    });
  });

  describe('getBookInfo', () => {
    it('returns book information from config', async () => {
      const result = await getBookInfo();

      expect(result.title).toBe('Test Book');
      expect(result.subtitle).toBe('Testing Book Tools');
      expect(result.author).toBe('Test Author');
    });
  });

  describe('cleanBuild', () => {
    it('cleans build directory', async () => {
      const result = await cleanBuild();

      expect(result.success).toBe(true);
    });
  });
});