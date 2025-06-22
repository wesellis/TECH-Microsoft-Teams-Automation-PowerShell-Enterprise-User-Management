/**
 * Type definitions for Teams Automation Bot
 */

export interface Team {
  id: string;
  displayName: string;
  description?: string;
  visibility?: 'public' | 'private';
  createdDateTime?: string;
  webUrl?: string;
}

export interface Channel {
  id: string;
  displayName: string;
  description?: string;
  membershipType?: 'standard' | 'private' | 'shared';
  webUrl?: string;
  createdDateTime?: string;
}

export interface Message {
  id: string;
  replyToId?: string;
  etag?: string;
  messageType?: string;
  createdDateTime?: string;
  lastModifiedDateTime?: string;
  lastEditedDateTime?: string;
  deletedDateTime?: string;
  subject?: string;
  summary?: string;
  chatId?: string;
  importance?: 'normal' | 'high' | 'urgent';
  locale?: string;
  webUrl?: string;
  channelIdentity?: {
    teamId: string;
    channelId: string;
  };
  from?: {
    application?: any;
    device?: any;
    user?: User;
  };
  body: {
    contentType: 'text' | 'html';
    content: string;
  };
  attachments?: Attachment[];
  mentions?: Mention[];
  reactions?: Reaction[];
}

export interface User {
  id: string;
  displayName: string;
  mail?: string;
  userPrincipalName: string;
  businessPhones?: string[];
  jobTitle?: string;
  department?: string;
  officeLocation?: string;
}

export interface Attachment {
  id: string;
  contentType: string;
  contentUrl?: string;
  content?: string;
  name?: string;
  thumbnailUrl?: string;
}

export interface Mention {
  id: number;
  mentionText: string;
  mentioned: {
    user?: User;
    application?: any;
    device?: any;
  };
}

export interface Reaction {
  reactionType: string;
  createdDateTime: string;
  user: User;
}

export interface TeamMember {
  id: string;
  displayName: string;
  userId: string;
  email?: string;
  roles: string[];
}

export interface ScheduledTask {
  id: string;
  name: string;
  description?: string;
  schedule: string; // Cron expression
  enabled: boolean;
  lastRun?: Date;
  nextRun?: Date;
  action: () => Promise<void>;
}

export interface WebhookEvent {
  id: string;
  timestamp: Date;
  type: string;
  teamId?: string;
  channelId?: string;
  userId?: string;
  data: any;
}

export interface CommandOptions {
  command: string;
  args: string[];
  options: Record<string, any>;
}

export interface ApiError {
  code: string;
  message: string;
  details?: any;
  timestamp: Date;
}