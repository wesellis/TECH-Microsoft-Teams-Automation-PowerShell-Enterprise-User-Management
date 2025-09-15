import { ConfidentialClientApplication, AuthenticationResult } from '@azure/msal-node';
import { logger } from '../utils/logger';

export interface AuthConfig {
  clientId: string;
  clientSecret: string;
  tenantId: string;
  scopes?: string[];
}

export class AuthenticationProvider {
  private msalClient: ConfidentialClientApplication;
  private config: AuthConfig;
  private tokenCache: AuthenticationResult | null = null;
  
  constructor(config: AuthConfig) {
    this.config = {
      ...config,
      scopes: config.scopes || ['https://graph.microsoft.com/.default']
    };
    
    this.msalClient = new ConfidentialClientApplication({
      auth: {
        clientId: config.clientId,
        authority: `https://login.microsoftonline.com/${config.tenantId}`,
        clientSecret: config.clientSecret
      },
      system: {
        loggerOptions: {
          loggerCallback(loglevel, message) {
            logger.debug(`MSAL: ${message}`);
          },
          piiLoggingEnabled: false,
          logLevel: 3
        }
      }
    });
  }
  
  /**
   * Initialize authentication and acquire initial token
   */
  async initialize(): Promise<boolean> {
    try {
      await this.getAccessToken();
      return true;
    } catch (error) {
      logger.error('Failed to initialize authentication:', error);
      return false;
    }
  }
  
  /**
   * Get access token for Microsoft Graph API
   */
  async getAccessToken(): Promise<string> {
    try {
      // Check if we have a valid cached token
      if (this.tokenCache && new Date(this.tokenCache.expiresOn!) > new Date()) {
        return this.tokenCache.accessToken;
      }
      
      // Acquire new token
      const result = await this.msalClient.acquireTokenByClientCredential({
        scopes: this.config.scopes!
      });
      
      if (!result) {
        throw new Error('Failed to acquire access token');
      }
      
      this.tokenCache = result;
      logger.debug('Successfully acquired new access token');
      
      return result.accessToken;
      
    } catch (error) {
      logger.error('Error acquiring access token:', error);
      throw error;
    }
  }
  
  /**
   * Get authentication headers for API requests
   */
  async getAuthHeaders(): Promise<Record<string, string>> {
    const token = await this.getAccessToken();
    return {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };
  }
  
  /**
   * Validate current authentication status
   */
  async isAuthenticated(): Promise<boolean> {
    try {
      await this.getAccessToken();
      return true;
    } catch {
      return false;
    }
  }
  
  /**
   * Clear token cache
   */
  clearCache(): void {
    this.tokenCache = null;
    logger.debug('Token cache cleared');
  }
}