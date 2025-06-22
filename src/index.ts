/**
 * Teams Automation Bot - Enterprise Microsoft Teams Automation Platform
 * 
 * This modern TypeScript implementation provides enterprise-grade automation
 * capabilities for Microsoft Teams, migrated from the original PowerShell scripts.
 */

import * as dotenv from 'dotenv';
import express from 'express';
import { AuthenticationProvider } from './auth/authProvider';
import { TeamsAutomationClient } from './api/teamsClient';
import { CommandHandler } from './utils/commandHandler';
import { logger } from './utils/logger';
import { setupScheduledTasks } from './scheduler';
import { webhookRouter } from './webhooks';

// Load environment variables
dotenv.config();

// Initialize Express app for webhooks and health checks
const app = express();
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    version: '2.0.0',
    timestamp: new Date().toISOString()
  });
});

// Webhook endpoints
app.use('/webhooks', webhookRouter);

// Main application entry point
async function main() {
  try {
    logger.info('Starting Teams Automation Bot v2.0.0');
    
    // Initialize authentication
    const authProvider = new AuthenticationProvider({
      clientId: process.env.AZURE_CLIENT_ID!,
      clientSecret: process.env.AZURE_CLIENT_SECRET!,
      tenantId: process.env.AZURE_TENANT_ID!
    });
    
    // Validate authentication
    const authenticated = await authProvider.initialize();
    if (!authenticated) {
      throw new Error('Failed to authenticate with Microsoft Graph');
    }
    
    logger.info('Successfully authenticated with Microsoft Graph');
    
    // Initialize Teams client
    const teamsClient = new TeamsAutomationClient(authProvider);
    
    // Initialize command handler for CLI operations
    const commandHandler = new CommandHandler(teamsClient);
    
    // Parse command line arguments
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
      // No arguments - start as a service
      startService();
    } else {
      // Execute command line operation
      await commandHandler.execute(args);
    }
    
  } catch (error) {
    logger.error('Fatal error in main:', error);
    process.exit(1);
  }
}

/**
 * Start the automation bot as a service
 */
function startService() {
  const port = process.env.PORT || 3000;
  
  // Setup scheduled tasks
  setupScheduledTasks();
  
  // Start Express server for webhooks
  app.listen(port, () => {
    logger.info(`Teams Automation Bot service running on port ${port}`);
    logger.info('Webhook endpoint: /webhooks/teams');
    logger.info('Health check: /health');
    logger.info('Scheduled tasks: Active');
  });
  
  // Graceful shutdown handling
  process.on('SIGTERM', gracefulShutdown);
  process.on('SIGINT', gracefulShutdown);
}

/**
 * Gracefully shutdown the service
 */
function gracefulShutdown() {
  logger.info('Received shutdown signal, cleaning up...');
  
  // Close server
  process.exit(0);
}

// Execute main function
main().catch(error => {
  logger.error('Unhandled error:', error);
  process.exit(1);
});