const redis = require('redis');

// Crear cliente Redis
const redisClient = redis.createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379'
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));

const connectRedis = async () => {
  try {
    await redisClient.connect();
    console.log('Conectado a Redis');
  } catch (err) {
    console.error('Error conectando a Redis:', err);
  }
};

const cache = {
  get: async (key) => {
    try {
      const value = await redisClient.get(key);
      return value ? JSON.parse(value) : null;
    } catch (err) {
      console.error('Error getting from cache:', err);
      return null;
    }
  },

  set: async (key, value, ttl = 3600) => {
    try {
      await redisClient.setEx(key, ttl, JSON.stringify(value));
    } catch (err) {
      console.error('Error setting cache:', err);
    }
  },

  del: async (key) => {
    try {
      await redisClient.del(key);
    } catch (err) {
      console.error('Error deleting from cache:', err);
    }
  }
};

module.exports = { redisClient, connectRedis, cache };