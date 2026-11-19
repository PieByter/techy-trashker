import type { FastifyPluginAsync } from 'fastify';
import { adminRoutes } from './admin';
import { authRoutes } from './auth';
import { depositRoutes } from './deposits';
import { leaderboardRoutes } from './leaderboard';
import { meRoutes } from './me';
import { newsRoutes } from './news';
import { officerRoutes } from './officer';
import { pointRoutes } from './points';
import { qrRoutes } from './qr';
import { rewardRoutes } from './rewards';
import { wasteBankRoutes } from './waste-banks';

export const apiRoutes: FastifyPluginAsync = async (app) => {
  app.get('/', async () => ({
    name: 'Techy Trashker API',
    version: '0.1.0',
    docs: '/docs',
    endpoints: {
      auth: '/api/v1/auth',
      me: '/api/v1/me',
      news: '/api/v1/news',
      deposits: '/api/v1/deposits',
      officer: '/api/v1/officer/deposits',
      qr: '/api/v1/qr',
      wasteBanks: '/api/v1/waste-banks',
      rewards: '/api/v1/rewards',
      redemptions: '/api/v1/redemptions',
      points: '/api/v1/points/history',
      leaderboard: '/api/v1/leaderboard',
      admin: '/api/v1/admin',
    },
  }));

  await app.register(authRoutes);
  await app.register(meRoutes);
  await app.register(newsRoutes);
  await app.register(wasteBankRoutes);
  await app.register(depositRoutes);
  await app.register(officerRoutes);
  await app.register(qrRoutes);
  await app.register(rewardRoutes);
  await app.register(leaderboardRoutes);
  await app.register(pointRoutes);
  await app.register(adminRoutes);
};
