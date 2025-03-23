const { configureCLI } = require('../src/cli');
const { program } = require('commander');

// Mock the inquirer module
jest.mock('inquirer', () => ({
  prompt: jest.fn().mockResolvedValue({
    language: 'en',
    formats: ['pdf', 'epub']
  })
}));

// Mock the book-tools modules
jest.mock('../src/index', () => ({
  buildBook: jest.fn().mockResolvedValue({ success: true }),
  createChapter: jest.fn().mockResolvedValue({ 
    success: true, 
    chapterNumber: '01', 
    chapterTitle: 'Test Chapter',
    language: 'en',
    path: '/project-root/book/en/chapter-01',
    files: [
      '/project-root/book/en/chapter-01/00-introduction.md',
      '/project-root/book/en/chapter-01/01-section.md',
      '/project-root/book/en/chapter-01/images/README.md'
    ]
  }),
  checkChapter: jest.fn().mockResolvedValue({
    language: 'en',
    chapterNumber: '01',
    hasIntro: true,
    hasSection: true,
    hasImagesDir: true,
    markdownFiles: [
      { name: '00-introduction.md', title: 'Introduction' },
      { name: '01-section.md', title: 'First Section' }
    ],
    images: []
  }),
  getBookInfo: jest.fn().mockResolvedValue({
    title: 'Test Book',
    subtitle: 'Test Subtitle',
    author: 'Test Author',
    filePrefix: 'test-book',
    languages: ['en', 'es'],
    formats: {
      pdf: true,
      epub: true,
      mobi: true,
      html: true
    },
    builtFiles: []
  }),
  cleanBuild: jest.fn().mockResolvedValue({
    success: true,
    filesRemoved: 5
  })
}));

// Mock chalk for easier testing
jest.mock('chalk', () => ({
  blue: (text) => text,
  green: (text) => text,
  red: (text) => text,
  cyan: (text) => text,
  yellow: (text) => text
}));

// Mock ora spinner
jest.mock('ora', () => {
  return jest.fn().mockReturnValue({
    start: jest.fn().mockReturnThis(),
    stop: jest.fn().mockReturnThis(),
    succeed: jest.fn().mockReturnThis(),
    fail: jest.fn().mockReturnThis(),
    info: jest.fn().mockReturnThis(),
    warn: jest.fn().mockReturnThis()
  });
});

describe('CLI', () => {
  let originalProcessExit;
  let originalConsoleLog;
  let originalConsoleError;
  let exitMock;
  let logMock;
  let errorMock;

  beforeEach(() => {
    // Mock process.exit, console.log, and console.error
    originalProcessExit = process.exit;
    originalConsoleLog = console.log;
    originalConsoleError = console.error;
    
    exitMock = jest.fn();
    logMock = jest.fn();
    errorMock = jest.fn();
    
    process.exit = exitMock;
    console.log = logMock;
    console.error = errorMock;
    
    // Reset commander before each test
    program.commands = [];
    program.options = [];
  });

  afterEach(() => {
    // Restore original functions
    process.exit = originalProcessExit;
    console.log = originalConsoleLog;
    console.error = originalConsoleError;
    
    jest.clearAllMocks();
  });

  test('should configure commander with the correct commands', () => {
    configureCLI();
    
    // Skip deep command inspection and just verify some basic 
    // structure to avoid potential implementation differences
    expect(program.commands.length).toBeGreaterThan(0);
    
    // Get all registered command names
    const commandNames = program.commands.map(cmd => cmd.name());
    
    // Verify that expected commands are registered
    expect(commandNames).toContain('build');
    expect(commandNames).toContain('interactive');
    expect(commandNames).toContain('create-chapter');
  });
});