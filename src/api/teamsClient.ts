import { Client } from '@microsoft/microsoft-graph-client';
import { AuthenticationProvider } from '../auth/authProvider';
import { logger } from '../utils/logger';
import { Team, Channel, Message, User } from '../types';

export class TeamsAutomationClient {
  private graphClient: Client;
  
  constructor(private authProvider: AuthenticationProvider) {
    this.graphClient = Client.init({
      authProvider: async (done) => {
        try {
          const token = await this.authProvider.getAccessToken();
          done(null, token);
        } catch (error) {
          done(error as Error, null);
        }
      }
    });
  }
  
  /**
   * Send a message to a Teams channel
   */
  async sendMessage(teamId: string, channelId: string, content: string, mentions?: string[]): Promise<Message> {
    try {
      logger.info(`Sending message to team ${teamId}, channel ${channelId}`);
      
      const messageBody: any = {
        body: {
          contentType: 'html',
          content: content
        }
      };
      
      // Add mentions if provided
      if (mentions && mentions.length > 0) {
        messageBody.mentions = mentions.map((userId, index) => ({
          id: index,
          mentionText: `<at id="${index}">User</at>`,
          mentioned: {
            user: {
              id: userId,
              displayName: 'User'
            }
          }
        }));
        
        // Update content to include mention tags
        mentions.forEach((userId, index) => {
          content = content.replace(`@${userId}`, `<at id="${index}">User</at>`);
        });
        
        messageBody.body.content = content;
      }
      
      const response = await this.graphClient
        .api(`/teams/${teamId}/channels/${channelId}/messages`)
        .post(messageBody);
      
      logger.info('Message sent successfully');
      return response;
      
    } catch (error) {
      logger.error('Failed to send message:', error);
      throw error;
    }
  }
  
  /**
   * List all teams for the authenticated user/app
   */
  async listTeams(): Promise<Team[]> {
    try {
      logger.info('Fetching teams list');
      
      const response = await this.graphClient
        .api('/groups')
        .filter("resourceProvisioningOptions/Any(x:x eq 'Team')")
        .select('id,displayName,description')
        .get();
      
      logger.info(`Found ${response.value.length} teams`);
      return response.value;
      
    } catch (error) {
      logger.error('Failed to list teams:', error);
      throw error;
    }
  }
  
  /**
   * List channels in a team
   */
  async listChannels(teamId: string): Promise<Channel[]> {
    try {
      logger.info(`Fetching channels for team ${teamId}`);
      
      const response = await this.graphClient
        .api(`/teams/${teamId}/channels`)
        .get();
      
      logger.info(`Found ${response.value.length} channels`);
      return response.value;
      
    } catch (error) {
      logger.error('Failed to list channels:', error);
      throw error;
    }
  }
  
  /**
   * Create a new channel in a team
   */
  async createChannel(teamId: string, displayName: string, description?: string): Promise<Channel> {
    try {
      logger.info(`Creating channel "${displayName}" in team ${teamId}`);
      
      const channelData = {
        displayName,
        description: description || '',
        membershipType: 'standard'
      };
      
      const response = await this.graphClient
        .api(`/teams/${teamId}/channels`)
        .post(channelData);
      
      logger.info('Channel created successfully');
      return response;
      
    } catch (error) {
      logger.error('Failed to create channel:', error);
      throw error;
    }
  }
  
  /**
   * Add user to a team
   */
  async addUserToTeam(teamId: string, userId: string, role: 'member' | 'owner' = 'member'): Promise<void> {
    try {
      logger.info(`Adding user ${userId} to team ${teamId} as ${role}`);
      
      const memberData = {
        '@odata.type': '#microsoft.graph.aadUserConversationMember',
        'user@odata.bind': `https://graph.microsoft.com/v1.0/users/${userId}`,
        roles: role === 'owner' ? ['owner'] : []
      };
      
      await this.graphClient
        .api(`/teams/${teamId}/members`)
        .post(memberData);
      
      logger.info('User added successfully');
      
    } catch (error) {
      logger.error('Failed to add user to team:', error);
      throw error;
    }
  }
  
  /**
   * Get team details
   */
  async getTeam(teamId: string): Promise<Team> {
    try {
      logger.info(`Fetching team details for ${teamId}`);
      
      const response = await this.graphClient
        .api(`/teams/${teamId}`)
        .get();
      
      return response;
      
    } catch (error) {
      logger.error('Failed to get team details:', error);
      throw error;
    }
  }
  
  /**
   * Get user details
   */
  async getUser(userId: string): Promise<User> {
    try {
      logger.info(`Fetching user details for ${userId}`);
      
      const response = await this.graphClient
        .api(`/users/${userId}`)
        .select('id,displayName,mail,userPrincipalName')
        .get();
      
      return response;
      
    } catch (error) {
      logger.error('Failed to get user details:', error);
      throw error;
    }
  }
  
  /**
   * Search users by display name or email
   */
  async searchUsers(query: string): Promise<User[]> {
    try {
      logger.info(`Searching users with query: ${query}`);
      
      const response = await this.graphClient
        .api('/users')
        .filter(`startswith(displayName,'${query}') or startswith(mail,'${query}') or startswith(userPrincipalName,'${query}')`)
        .select('id,displayName,mail,userPrincipalName')
        .top(10)
        .get();
      
      logger.info(`Found ${response.value.length} users`);
      return response.value;
      
    } catch (error) {
      logger.error('Failed to search users:', error);
      throw error;
    }
  }
  
  /**
   * Delete a channel from a team
   */
  async deleteChannel(teamId: string, channelId: string): Promise<void> {
    try {
      logger.info(`Deleting channel ${channelId} from team ${teamId}`);
      
      await this.graphClient
        .api(`/teams/${teamId}/channels/${channelId}`)
        .delete();
      
      logger.info('Channel deleted successfully');
      
    } catch (error) {
      logger.error('Failed to delete channel:', error);
      throw error;
    }
  }
  
  /**
   * Archive a team
   */
  async archiveTeam(teamId: string, shouldSetSpoSiteReadOnly: boolean = false): Promise<void> {
    try {
      logger.info(`Archiving team ${teamId}`);
      
      await this.graphClient
        .api(`/teams/${teamId}/archive`)
        .post({ shouldSetSpoSiteReadOnly });
      
      logger.info('Team archived successfully');
      
    } catch (error) {
      logger.error('Failed to archive team:', error);
      throw error;
    }
  }
}