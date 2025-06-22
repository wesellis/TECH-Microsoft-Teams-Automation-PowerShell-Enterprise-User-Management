import { Router, Request, Response } from 'express';
import { logger, loggers } from '../utils/logger';
import { WebhookEvent } from '../types';

export const webhookRouter = Router();

// Webhook validation middleware
const validateWebhook = (req: Request, res: Response, next: Function) => {
  const webhookSecret = process.env.WEBHOOK_SECRET;
  
  if (webhookSecret) {
    const signature = req.headers['x-webhook-signature'];
    
    if (!signature || signature !== webhookSecret) {
      loggers.security.warn('Invalid webhook signature', {
        ip: req.ip,
        headers: req.headers
      });
      return res.status(401).json({ error: 'Unauthorized' });
    }
  }
  
  next();
};

// Teams webhook endpoint
webhookRouter.post('/teams', validateWebhook, async (req: Request, res: Response) => {
  try {
    const event: WebhookEvent = {
      id: req.body.id || generateEventId(),
      timestamp: new Date(),
      type: req.body.type || 'unknown',
      teamId: req.body.teamId,
      channelId: req.body.channelId,
      userId: req.body.userId,
      data: req.body
    };
    
    logger.info('Received webhook event', {
      type: event.type,
      teamId: event.teamId,
      channelId: event.channelId
    });
    
    // Process webhook based on type
    await processWebhookEvent(event);
    
    res.status(200).json({ 
      status: 'success',
      eventId: event.id 
    });
    
  } catch (error) {
    logger.error('Webhook processing error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Health check for webhooks
webhookRouter.get('/health', (req: Request, res: Response) => {
  res.json({ 
    status: 'healthy',
    webhooks: {
      enabled: process.env.ENABLE_WEBHOOKS === 'true',
      endpoint: '/webhooks/teams'
    }
  });
});

/**
 * Process webhook event based on type
 */
async function processWebhookEvent(event: WebhookEvent): Promise<void> {
  switch (event.type) {
    case 'message.created':
      await handleMessageCreated(event);
      break;
      
    case 'channel.created':
      await handleChannelCreated(event);
      break;
      
    case 'member.added':
      await handleMemberAdded(event);
      break;
      
    case 'member.removed':
      await handleMemberRemoved(event);
      break;
      
    default:
      logger.warn(`Unhandled webhook event type: ${event.type}`);
  }
  
  // Log to audit
  loggers.audit.info('Webhook event processed', {
    eventId: event.id,
    type: event.type,
    teamId: event.teamId,
    channelId: event.channelId,
    userId: event.userId
  });
}

async function handleMessageCreated(event: WebhookEvent): Promise<void> {
  logger.info('Processing message created event');
  
  // Example: Auto-respond to certain keywords
  const message = event.data.message;
  if (message && message.content) {
    const content = message.content.toLowerCase();
    
    if (content.includes('@bot help')) {
      // Trigger help response
      logger.info('Help request detected, sending response');
      // Implementation here
    }
  }
}

async function handleChannelCreated(event: WebhookEvent): Promise<void> {
  logger.info('Processing channel created event');
  
  // Example: Apply default settings to new channels
  if (event.channelId) {
    logger.info(`Applying default settings to channel ${event.channelId}`);
    // Implementation here
  }
}

async function handleMemberAdded(event: WebhookEvent): Promise<void> {
  logger.info('Processing member added event');
  
  // Example: Send welcome message to new members
  if (event.userId && event.teamId) {
    logger.info(`Sending welcome message to user ${event.userId}`);
    // Implementation here
  }
}

async function handleMemberRemoved(event: WebhookEvent): Promise<void> {
  logger.info('Processing member removed event');
  
  // Example: Clean up user data
  if (event.userId && event.teamId) {
    logger.info(`Cleaning up data for removed user ${event.userId}`);
    // Implementation here
  }
}

function generateEventId(): string {
  return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}