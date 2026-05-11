const Queue = require('bull');
const logger = require('../shared/logger');

// Cola para tareas asincrónicas
const notificationQueue = new Queue('notifications', {
  redis: process.env.REDIS_URL || 'redis://localhost:6379'
});

notificationQueue.process(async (job) => {
  const { type, data } = job.data;
  logger.info(`Procesando notificación: ${type}`, data);

  // Aquí implementar lógica de notificaciones
  // Ej: enviar email, push notification, etc.

  return { success: true };
});

notificationQueue.on('completed', (job) => {
  logger.info(`Job ${job.id} completed`);
});

notificationQueue.on('failed', (job, err) => {
  logger.error(`Job ${job.id} failed:`, err);
});

const addNotificationJob = async (type, data) => {
  await notificationQueue.add({ type, data });
};

module.exports = {
  notificationQueue,
  addNotificationJob
};