import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { TeamsAutomationClient } from '../api/teamsClient';
import { logger } from './logger';

export class CommandHandler {
  constructor(private teamsClient: TeamsAutomationClient) {}
  
  async execute(args: string[]): Promise<void> {
    const argv = await yargs(hideBin(args))
      .command('send-message', 'Send a message to a Teams channel', {
        team: {
          alias: 't',
          describe: 'Team ID',
          demandOption: true,
          type: 'string'
        },
        channel: {
          alias: 'c',
          describe: 'Channel ID',
          demandOption: true,
          type: 'string'
        },
        message: {
          alias: 'm',
          describe: 'Message content',
          demandOption: true,
          type: 'string'
        },
        mentions: {
          describe: 'User IDs to mention (comma-separated)',
          type: 'string'
        }
      }, async (argv) => {
        const mentions = argv.mentions ? argv.mentions.split(',') : undefined;
        await this.sendMessage(argv.team, argv.channel, argv.message, mentions);
      })
      .command('list-teams', 'List all teams', {}, async () => {
        await this.listTeams();
      })
      .command('list-channels', 'List channels in a team', {
        team: {
          alias: 't',
          describe: 'Team ID',
          demandOption: true,
          type: 'string'
        }
      }, async (argv) => {
        await this.listChannels(argv.team);
      })
      .command('create-channel', 'Create a new channel', {
        team: {
          alias: 't',
          describe: 'Team ID',
          demandOption: true,
          type: 'string'
        },
        name: {
          alias: 'n',
          describe: 'Channel name',
          demandOption: true,
          type: 'string'
        },
        description: {
          alias: 'd',
          describe: 'Channel description',
          type: 'string'
        }
      }, async (argv) => {
        await this.createChannel(argv.team, argv.name, argv.description);
      })
      .command('add-user', 'Add user to a team', {
        team: {
          alias: 't',
          describe: 'Team ID',
          demandOption: true,
          type: 'string'
        },
        user: {
          alias: 'u',
          describe: 'User ID or email',
          demandOption: true,
          type: 'string'
        },
        role: {
          alias: 'r',
          describe: 'User role',
          choices: ['member', 'owner'],
          default: 'member'
        }
      }, async (argv) => {
        await this.addUser(argv.team, argv.user, argv.role as 'member' | 'owner');
      })
      .command('search-users', 'Search for users', {
        query: {
          alias: 'q',
          describe: 'Search query',
          demandOption: true,
          type: 'string'
        }
      }, async (argv) => {
        await this.searchUsers(argv.query);
      })
      .demandCommand()
      .help()
      .argv;
  }
  
  private async sendMessage(teamId: string, channelId: string, content: string, mentions?: string[]): Promise<void> {
    try {
      const result = await this.teamsClient.sendMessage(teamId, channelId, content, mentions);
      console.log('Message sent successfully!');
      console.log(`Message ID: ${result.id}`);
    } catch (error) {
      console.error('Failed to send message:', error);
      process.exit(1);
    }
  }
  
  private async listTeams(): Promise<void> {
    try {
      const teams = await this.teamsClient.listTeams();
      console.log('\nTeams:');
      console.log('======');
      teams.forEach(team => {
        console.log(`- ${team.displayName} (ID: ${team.id})`);
        if (team.description) {
          console.log(`  Description: ${team.description}`);
        }
      });
    } catch (error) {
      console.error('Failed to list teams:', error);
      process.exit(1);
    }
  }
  
  private async listChannels(teamId: string): Promise<void> {
    try {
      const channels = await this.teamsClient.listChannels(teamId);
      console.log('\nChannels:');
      console.log('=========');
      channels.forEach(channel => {
        console.log(`- ${channel.displayName} (ID: ${channel.id})`);
        if (channel.description) {
          console.log(`  Description: ${channel.description}`);
        }
        console.log(`  Type: ${channel.membershipType || 'standard'}`);
      });
    } catch (error) {
      console.error('Failed to list channels:', error);
      process.exit(1);
    }
  }
  
  private async createChannel(teamId: string, name: string, description?: string): Promise<void> {
    try {
      const channel = await this.teamsClient.createChannel(teamId, name, description);
      console.log('Channel created successfully!');
      console.log(`Channel ID: ${channel.id}`);
      console.log(`Channel Name: ${channel.displayName}`);
    } catch (error) {
      console.error('Failed to create channel:', error);
      process.exit(1);
    }
  }
  
  private async addUser(teamId: string, userIdOrEmail: string, role: 'member' | 'owner'): Promise<void> {
    try {
      // If it looks like an email, search for the user first
      let userId = userIdOrEmail;
      if (userIdOrEmail.includes('@')) {
        const users = await this.teamsClient.searchUsers(userIdOrEmail);
        if (users.length === 0) {
          throw new Error(`User not found: ${userIdOrEmail}`);
        }
        userId = users[0].id;
      }
      
      await this.teamsClient.addUserToTeam(teamId, userId, role);
      console.log(`User added successfully as ${role}!`);
    } catch (error) {
      console.error('Failed to add user:', error);
      process.exit(1);
    }
  }
  
  private async searchUsers(query: string): Promise<void> {
    try {
      const users = await this.teamsClient.searchUsers(query);
      console.log('\nSearch Results:');
      console.log('===============');
      if (users.length === 0) {
        console.log('No users found');
      } else {
        users.forEach(user => {
          console.log(`- ${user.displayName}`);
          console.log(`  ID: ${user.id}`);
          console.log(`  Email: ${user.mail || user.userPrincipalName}`);
          if (user.jobTitle) {
            console.log(`  Title: ${user.jobTitle}`);
          }
          console.log('');
        });
      }
    } catch (error) {
      console.error('Failed to search users:', error);
      process.exit(1);
    }
  }
}