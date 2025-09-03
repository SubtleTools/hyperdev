/**
 * Comprehensive Error Handling System for Hypergen Monorepo Pack
 * 
 * Provides structured error handling with meaningful messages, recovery suggestions,
 * and graceful fallbacks for all edge cases in template generation.
 */

export enum ErrorCode {
  // Validation Errors
  INVALID_PROJECT_NAME = 'INVALID_PROJECT_NAME',
  INVALID_TOOL_COMBINATION = 'INVALID_TOOL_COMBINATION', 
  MISSING_REQUIRED_FIELD = 'MISSING_REQUIRED_FIELD',
  PRESET_NOT_FOUND = 'PRESET_NOT_FOUND',
  
  // Template Errors
  TEMPLATE_FILE_NOT_FOUND = 'TEMPLATE_FILE_NOT_FOUND',
  TEMPLATE_PARSING_ERROR = 'TEMPLATE_PARSING_ERROR',
  TEMPLATE_RENDER_ERROR = 'TEMPLATE_RENDER_ERROR',
  COMPOSITION_FAILED = 'COMPOSITION_FAILED',
  
  // File System Errors
  DIRECTORY_ACCESS_ERROR = 'DIRECTORY_ACCESS_ERROR',
  FILE_WRITE_ERROR = 'FILE_WRITE_ERROR',
  FILE_READ_ERROR = 'FILE_READ_ERROR',
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  DISK_SPACE_ERROR = 'DISK_SPACE_ERROR',
  
  // Network/Dependency Errors
  PACKAGE_MANAGER_NOT_FOUND = 'PACKAGE_MANAGER_NOT_FOUND',
  DEPENDENCY_RESOLUTION_ERROR = 'DEPENDENCY_RESOLUTION_ERROR',
  NETWORK_ERROR = 'NETWORK_ERROR',
  TIMEOUT_ERROR = 'TIMEOUT_ERROR',
  
  // Runtime Errors
  UNEXPECTED_ERROR = 'UNEXPECTED_ERROR',
  ACTION_EXECUTION_FAILED = 'ACTION_EXECUTION_FAILED',
  POST_GENERATION_ERROR = 'POST_GENERATION_ERROR',
  CONTEXT_PREPARATION_ERROR = 'CONTEXT_PREPARATION_ERROR',
}

export enum ErrorSeverity {
  FATAL = 'fatal',
  ERROR = 'error', 
  WARNING = 'warning',
  INFO = 'info'
}

export interface ErrorSuggestion {
  action: string;
  description: string;
  command?: string;
  url?: string;
  automated?: boolean;
}

export interface ErrorContext {
  operation?: string;
  file?: string;
  tool?: string;
  preset?: string;
  field?: string;
  value?: any;
  stackTrace?: string;
  timestamp?: string;
  [key: string]: any;
}

/**
 * Base error class for all Hypergen errors
 */
export class HypergenError extends Error {
  public readonly code: ErrorCode;
  public readonly severity: ErrorSeverity;
  public readonly suggestions: ErrorSuggestion[];
  public readonly context: ErrorContext;
  public readonly userMessage: string;
  public readonly recoverable: boolean;

  constructor(
    code: ErrorCode,
    message: string,
    options: {
      severity?: ErrorSeverity;
      suggestions?: ErrorSuggestion[];
      context?: ErrorContext;
      userMessage?: string;
      recoverable?: boolean;
      cause?: Error;
    } = {}
  ) {
    super(message);
    this.name = 'HypergenError';
    this.code = code;
    this.severity = options.severity || ErrorSeverity.ERROR;
    this.suggestions = options.suggestions || [];
    this.context = {
      timestamp: new Date().toISOString(),
      ...options.context
    };
    this.userMessage = options.userMessage || message;
    this.recoverable = options.recoverable || false;

    if (options.cause) {
      this.cause = options.cause;
      this.stack = `${this.stack}\nCaused by: ${options.cause.stack}`;
    }
  }

  /**
   * Get formatted error message for user display
   */
  getDisplayMessage(): string {
    let message = `${this.getSeverityIcon()} ${this.userMessage}\n`;
    
    if (this.context.operation) {
      message += `   Operation: ${this.context.operation}\n`;
    }
    
    if (this.suggestions.length > 0) {
      message += '\n💡 Suggestions:\n';
      this.suggestions.forEach(suggestion => {
        message += `   • ${suggestion.description}`;
        if (suggestion.command) {
          message += `\n     Command: ${suggestion.command}`;
        }
        if (suggestion.url) {
          message += `\n     More info: ${suggestion.url}`;
        }
        message += '\n';
      });
    }

    return message;
  }

  /**
   * Get error data for logging/reporting
   */
  getErrorData(): Record<string, any> {
    return {
      code: this.code,
      severity: this.severity,
      message: this.message,
      userMessage: this.userMessage,
      context: this.context,
      suggestions: this.suggestions,
      recoverable: this.recoverable,
      stack: this.stack
    };
  }

  private getSeverityIcon(): string {
    switch (this.severity) {
      case ErrorSeverity.FATAL: return '💀';
      case ErrorSeverity.ERROR: return '❌';
      case ErrorSeverity.WARNING: return '⚠️';
      case ErrorSeverity.INFO: return 'ℹ️';
      default: return '❌';
    }
  }
}

/**
 * Validation-specific errors
 */
export class ValidationError extends HypergenError {
  constructor(
    message: string,
    field?: string,
    value?: any,
    suggestions: ErrorSuggestion[] = []
  ) {
    super(ErrorCode.MISSING_REQUIRED_FIELD, message, {
      severity: ErrorSeverity.ERROR,
      context: { field, value, operation: 'validation' },
      suggestions,
      recoverable: true
    });
  }
}

/**
 * Template-specific errors
 */
export class TemplateError extends HypergenError {
  constructor(
    code: ErrorCode,
    message: string,
    templateFile?: string,
    suggestions: ErrorSuggestion[] = []
  ) {
    super(code, message, {
      severity: ErrorSeverity.ERROR,
      context: { file: templateFile, operation: 'template_processing' },
      suggestions,
      recoverable: false
    });
  }
}

/**
 * File system errors
 */
export class FileSystemError extends HypergenError {
  constructor(
    code: ErrorCode,
    message: string,
    filePath?: string,
    cause?: Error,
    suggestions: ErrorSuggestion[] = []
  ) {
    super(code, message, {
      severity: ErrorSeverity.ERROR,
      context: { file: filePath, operation: 'file_system' },
      suggestions,
      recoverable: true,
      cause
    });
  }
}

/**
 * Dependency/Network errors
 */
export class DependencyError extends HypergenError {
  constructor(
    code: ErrorCode,
    message: string,
    packageManager?: string,
    suggestions: ErrorSuggestion[] = []
  ) {
    super(code, message, {
      severity: ErrorSeverity.WARNING,
      context: { tool: packageManager, operation: 'dependency_resolution' },
      suggestions,
      recoverable: true
    });
  }
}

/**
 * Error handler class with recovery mechanisms
 */
export class ErrorHandler {
  private errorLog: HypergenError[] = [];
  private recoveryStrategies: Map<ErrorCode, (error: HypergenError) => Promise<any>> = new Map();

  constructor() {
    this.setupRecoveryStrategies();
  }

  /**
   * Handle an error with optional recovery
   */
  async handleError<T>(error: Error | HypergenError, operation?: string): Promise<T | null> {
    const hypergenError = this.normalizeError(error, operation);
    this.errorLog.push(hypergenError);

    // Log error
    this.logError(hypergenError);

    // Attempt recovery if possible
    if (hypergenError.recoverable) {
      const recovery = this.recoveryStrategies.get(hypergenError.code);
      if (recovery) {
        try {
          console.log(`🔄 Attempting recovery for ${hypergenError.code}...`);
          return await recovery(hypergenError);
        } catch (recoveryError) {
          console.error('❌ Recovery failed:', recoveryError);
        }
      }
    }

    // Display user-friendly error
    console.error(hypergenError.getDisplayMessage());

    // Fatal errors should stop execution
    if (hypergenError.severity === ErrorSeverity.FATAL) {
      process.exit(1);
    }

    return null;
  }

  /**
   * Handle multiple validation errors
   */
  handleValidationErrors(errors: HypergenError[]): void {
    if (errors.length === 0) return;

    console.error('\n❌ Configuration validation failed:');
    
    errors.forEach((error, index) => {
      console.error(`\n${index + 1}. ${error.userMessage}`);
      if (error.context.field) {
        console.error(`   Field: ${error.context.field}`);
      }
      if (error.context.value !== undefined) {
        console.error(`   Value: ${error.context.value}`);
      }
      if (error.suggestions.length > 0) {
        console.error('   Suggestions:');
        error.suggestions.forEach(suggestion => {
          console.error(`   • ${suggestion.description}`);
          if (suggestion.command) {
            console.error(`     Run: ${suggestion.command}`);
          }
        });
      }
    });

    console.error('\nPlease fix these issues and try again.\n');
    process.exit(1);
  }

  /**
   * Get error summary for reporting
   */
  getErrorSummary(): {
    total: number;
    byCode: Record<string, number>;
    bySeverity: Record<string, number>;
    recent: HypergenError[];
  } {
    const byCode: Record<string, number> = {};
    const bySeverity: Record<string, number> = {};

    this.errorLog.forEach(error => {
      byCode[error.code] = (byCode[error.code] || 0) + 1;
      bySeverity[error.severity] = (bySeverity[error.severity] || 0) + 1;
    });

    return {
      total: this.errorLog.length,
      byCode,
      bySeverity,
      recent: this.errorLog.slice(-10)
    };
  }

  /**
   * Clear error log
   */
  clearErrors(): void {
    this.errorLog = [];
  }

  private normalizeError(error: Error | HypergenError, operation?: string): HypergenError {
    if (error instanceof HypergenError) {
      return error;
    }

    // Convert standard errors to HypergenError
    return new HypergenError(
      ErrorCode.UNEXPECTED_ERROR,
      error.message,
      {
        severity: ErrorSeverity.ERROR,
        context: { operation, stackTrace: error.stack },
        cause: error,
        recoverable: false
      }
    );
  }

  private logError(error: HypergenError): void {
    const logLevel = error.severity === ErrorSeverity.FATAL || error.severity === ErrorSeverity.ERROR 
      ? 'error' : error.severity === ErrorSeverity.WARNING ? 'warn' : 'info';
    
    console[logLevel](`[${error.code}] ${error.message}`);
    
    if (error.context.operation) {
      console[logLevel](`Operation: ${error.context.operation}`);
    }
  }

  private setupRecoveryStrategies(): void {
    // Recovery for missing package manager
    this.recoveryStrategies.set(ErrorCode.PACKAGE_MANAGER_NOT_FOUND, async (error) => {
      console.log('🔄 Falling back to default package manager (bun)...');
      return 'bun';
    });

    // Recovery for missing template files
    this.recoveryStrategies.set(ErrorCode.TEMPLATE_FILE_NOT_FOUND, async (error) => {
      console.log('🔄 Using minimal template fallback...');
      return null; // Signal to use minimal template
    });

    // Recovery for invalid tool combinations
    this.recoveryStrategies.set(ErrorCode.INVALID_TOOL_COMBINATION, async (error) => {
      console.log('🔄 Applying suggested tool configuration...');
      // Return suggested valid combination
      return {
        packageManager: 'bun',
        linter: 'eslint', 
        formatter: 'prettier',
        testFramework: 'vitest'
      };
    });

    // Recovery for preset not found
    this.recoveryStrategies.set(ErrorCode.PRESET_NOT_FOUND, async (error) => {
      console.log('🔄 Using default preset (modern-bun)...');
      return 'modern-bun';
    });
  }
}

/**
 * Global error handler instance
 */
export const errorHandler = new ErrorHandler();

/**
 * Error creation helpers
 */
export const createValidationError = (message: string, field?: string, value?: any): ValidationError => {
  const suggestions: ErrorSuggestion[] = [];
  
  if (field === 'name') {
    suggestions.push({
      action: 'fix_name',
      description: 'Use lowercase letters, numbers, and hyphens only',
      command: 'Example: my-awesome-project'
    });
  } else if (field === 'packageManager') {
    suggestions.push({
      action: 'set_package_manager',
      description: 'Choose from: bun, npm, yarn, or pnpm',
      command: 'Default: bun (recommended)'
    });
  }
  
  return new ValidationError(message, field, value, suggestions);
};

export const createToolCompatibilityError = (
  incompatibleTools: string[], 
  validCombination?: Record<string, string>
): HypergenError => {
  const suggestions: ErrorSuggestion[] = [
    {
      action: 'use_preset',
      description: 'Use a pre-configured preset instead',
      command: 'Available: modern-bun, traditional-node, performance, enterprise'
    }
  ];

  if (validCombination) {
    suggestions.push({
      action: 'apply_suggestion',
      description: 'Use this valid combination',
      command: `${Object.entries(validCombination).map(([k, v]) => `${k}: ${v}`).join(', ')}`
    });
  }

  return new HypergenError(
    ErrorCode.INVALID_TOOL_COMBINATION,
    `Incompatible tool combination: ${incompatibleTools.join(', ')}`,
    {
      severity: ErrorSeverity.ERROR,
      context: { tools: incompatibleTools },
      suggestions,
      recoverable: true
    }
  );
};

export const createFileSystemError = (operation: string, filePath: string, cause?: Error): FileSystemError => {
  const suggestions: ErrorSuggestion[] = [
    {
      action: 'check_permissions',
      description: 'Check file/directory permissions',
      command: `ls -la ${filePath}`
    },
    {
      action: 'check_space',
      description: 'Check available disk space',
      command: 'df -h'
    }
  ];

  return new FileSystemError(
    ErrorCode.FILE_WRITE_ERROR,
    `Failed to ${operation}: ${filePath}`,
    filePath,
    cause,
    suggestions
  );
};

export const createDependencyError = (packageManager: string, operation: string): DependencyError => {
  const suggestions: ErrorSuggestion[] = [
    {
      action: 'check_installation',
      description: `Ensure ${packageManager} is installed`,
      command: `${packageManager} --version`
    },
    {
      action: 'fallback_manager',
      description: 'Try using a different package manager',
      automated: true
    }
  ];

  return new DependencyError(
    ErrorCode.PACKAGE_MANAGER_NOT_FOUND,
    `Package manager ${packageManager} not available for ${operation}`,
    packageManager,
    suggestions
  );
};

/**
 * Utility function to wrap async operations with error handling
 */
export async function withErrorHandling<T>(
  operation: () => Promise<T>,
  context: string
): Promise<T> {
  try {
    return await operation();
  } catch (error) {
    const handled = await errorHandler.handleError<T>(error as Error, context);
    if (handled !== null) {
      return handled;
    }
    throw error;
  }
}

/**
 * Utility function to validate and sanitize user input
 */
export function validateInput(
  value: any,
  field: string,
  requirements: {
    required?: boolean;
    type?: 'string' | 'number' | 'boolean' | 'object';
    pattern?: RegExp;
    minLength?: number;
    maxLength?: number;
    allowedValues?: any[];
  }
): { valid: boolean; error?: ValidationError; sanitized?: any } {
  const { required, type, pattern, minLength, maxLength, allowedValues } = requirements;

  // Check required
  if (required && (value === undefined || value === null || value === '')) {
    return {
      valid: false,
      error: createValidationError(`${field} is required`, field, value)
    };
  }

  // Skip further validation if not required and empty
  if (!required && (value === undefined || value === null || value === '')) {
    return { valid: true, sanitized: value };
  }

  // Type validation
  if (type && typeof value !== type) {
    return {
      valid: false,
      error: createValidationError(`${field} must be of type ${type}`, field, value)
    };
  }

  // String-specific validations
  if (type === 'string' || typeof value === 'string') {
    const strValue = String(value);
    
    if (minLength && strValue.length < minLength) {
      return {
        valid: false,
        error: createValidationError(`${field} must be at least ${minLength} characters`, field, value)
      };
    }
    
    if (maxLength && strValue.length > maxLength) {
      return {
        valid: false,
        error: createValidationError(`${field} must be no more than ${maxLength} characters`, field, value)
      };
    }
    
    if (pattern && !pattern.test(strValue)) {
      return {
        valid: false,
        error: createValidationError(`${field} format is invalid`, field, value)
      };
    }
  }

  // Allowed values validation
  if (allowedValues && !allowedValues.includes(value)) {
    return {
      valid: false,
      error: createValidationError(
        `${field} must be one of: ${allowedValues.join(', ')}`, 
        field, 
        value
      )
    };
  }

  return { valid: true, sanitized: value };
}