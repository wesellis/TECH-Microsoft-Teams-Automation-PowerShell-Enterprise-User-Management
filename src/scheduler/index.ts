import * as cron from 'node-cron';
import { logger } from '../utils/logger';
import { ScheduledTask } from '../types';

const scheduledTasks: Map<string, cron.ScheduledTask> = new Map();

/**
 * Setup scheduled tasks for automation
 */
export function setupScheduledTasks(): void {
  if (process.env.ENABLE_SCHEDULED_TASKS !== 'true') {
    logger.info('Scheduled tasks are disabled');
    return;
  }
  
  logger.info('Setting up scheduled tasks...');
  
  // Example: Daily team activity report at 9 AM
  scheduleTask({
    id: 'daily-activity-report',
    name: 'Daily Activity Report',
    description: 'Send daily team activity summary',
    schedule: '0 9 * * *', // Every day at 9:00 AM
    enabled: true,
    action: async () => {
      logger.info('Generating daily activity report...');
      // Implementation here
    }
  });
  
  // Example: Weekly team member sync every Monday at 2 AM
  scheduleTask({
    id: 'weekly-member-sync',
    name: 'Weekly Member Sync',
    description: 'Synchronize team members with AD',
    schedule: '0 2 * * 1', // Every Monday at 2:00 AM
    enabled: true,
    action: async () => {
      logger.info('Synchronizing team members...');
      // Implementation here
    }
  });
  
  // Example: Hourly webhook health check
  scheduleTask({
    id: 'webhook-health-check',
    name: 'Webhook Health Check',
    description: 'Check webhook connectivity',
    schedule: '0 * * * *', // Every hour
    enabled: true,
    action: async () => {
      logger.info('Checking webhook health...');
      // Implementation here
    }
  });
  
  logger.info(`Scheduled ${scheduledTasks.size} tasks`);
}

/**
 * Schedule a task
 */
export function scheduleTask(task: ScheduledTask): void {
  if (!task.enabled) {
    logger.info(`Task ${task.name} is disabled, skipping`);
    return;
  }
  
  if (!cron.validate(task.schedule)) {
    logger.error(`Invalid cron expression for task ${task.name}: ${task.schedule}`);
    return;
  }
  
  const cronTask = cron.schedule(task.schedule, async () => {
    logger.info(`Executing scheduled task: ${task.name}`);
    const startTime = Date.now();
    
    try {
      await task.action();
      const duration = Date.now() - startTime;
      logger.info(`Task ${task.name} completed in ${duration}ms`);
    } catch (error) {
      logger.error(`Task ${task.name} failed:`, error);
    }
  }, {
    scheduled: true
  });
  
  scheduledTasks.set(task.id, cronTask);
  logger.info(`Scheduled task: ${task.name} (${task.schedule})`);
}

/**
 * Stop a scheduled task
 */
export function stopTask(taskId: string): void {
  const task = scheduledTasks.get(taskId);
  if (task) {
    task.stop();
    scheduledTasks.delete(taskId);
    logger.info(`Stopped task: ${taskId}`);
  }
}

/**
 * Stop all scheduled tasks
 */
export function stopAllTasks(): void {
  scheduledTasks.forEach((task, id) => {
    task.stop();
    logger.info(`Stopped task: ${id}`);
  });
  scheduledTasks.clear();
}

/**
 * Get status of all scheduled tasks
 */
export function getTaskStatus(): Array<{ id: string; running: boolean }> {
  const status: Array<{ id: string; running: boolean }> = [];
  
  scheduledTasks.forEach((task, id) => {
    status.push({
      id,
      running: true // cron tasks don't expose running state directly
    });
  });
  
  return status;
}