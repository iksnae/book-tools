const { 
  findProjectRoot, 
  loadConfig, 
  ensureDirectoryExists,
  buildFileNames
} = require('../src/utils');

// Mock fs module
jest.mock('fs', () => ({
  existsSync: jest.fn(),
  readFileSync: jest.fn(),
  mkdirSync: jest.fn()
}));

// Mock yaml module
jest.mock('js-yaml', () => ({
  load: jest.fn().mockImplementation(yamlString => {
    if (yamlString.includes('Test Book')) {
      return {
        title: 'Test Book',
        subtitle: 'Test Subtitle',
        author: 'Test Author',
        filePrefix: 'test-book',
        languages: ['en', 'es']
      };
    }
    return {};
  })
}));

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

// Skip using mock-fs
jest.mock('mock-fs', () => jest.fn());

describe('Utils', () => {
  // Store original process.cwd
  const originalCwd = process.cwd;
  
  beforeEach(() => {
    // Setup fs.existsSync mock
    const fs = require('fs');
    
    // Default behavior: most files don't exist
    fs.existsSync.mockImplementation(path => {
      if (path === '/project-root/book.yaml') return true;
      if (path === '/project-root/book') return true;
      if (path.includes('/project-root')) return true;
      return false;
    });
    
    // Setup fs.readFileSync mock
    fs.readFileSync.mockImplementation(path => {
      if (path === '/project-root/book.yaml') {
        return 'title: Test Book\nsubtitle: Test Subtitle\nauthor: Test Author\nfilePrefix: test-book\nlanguages:\n  - en\n  - es';
      }
      return '';
    });
    
    // Mock process.cwd() to return a specific location
    jest.spyOn(process, 'cwd').mockReturnValue('/project-root/src');
  });

  afterEach(() => {
    jest.clearAllMocks();
    jest.restoreAllMocks();
    // Restore process.cwd
    process.cwd = originalCwd;
  });

  describe('findProjectRoot', () => {
    test('should find project root by looking for book.yaml', () => {
      const rootPath = findProjectRoot();
      expect(rootPath).toBe('/project-root');
    });

    test('should return null if book.yaml is not found', () => {
      const fs = require('fs');
      fs.existsSync.mockReturnValue(false);
      
      expect(() => {
        findProjectRoot();
      }).toThrow(/Could not find project root/);
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
    test('should create directory if it does not exist', () => {
      const fs = require('fs');
      fs.existsSync.mockReturnValueOnce(false);
      
      const dirPath = '/project-root/new-directory';
      ensureDirectoryExists(dirPath);
      
      expect(fs.mkdirSync).toHaveBeenCalledWith(dirPath, { recursive: true });
    });

    test('should not throw if directory already exists', () => {
      const fs = require('fs');
      fs.existsSync.mockReturnValueOnce(true);
      
      const dirPath = '/project-root/book';
      ensureDirectoryExists(dirPath);
      
      expect(fs.mkdirSync).not.toHaveBeenCalled();
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