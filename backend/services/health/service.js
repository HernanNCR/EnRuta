const mongoose = require("../../shared/db");
const { redisClient, connectRedis } = require("../../shared/cache");
const logger = require("../../shared/logger");
class HealthService {
  async checkDatabase() {
    try {
      await mongoose.connection.db.admin().ping();
      return { status: "ok", database: "connected" };
    } catch (error) {
      return {
        status: "error",
        database: "disconnected",
        error: error.message,
      };
    }
  }

  async checkRedis() {
    try {
      await redisClient.ping();
      return { status: "ok", redis: "connected" };
    } catch (error) {
      return { status: "error", redis: "disconnected", error: error.message };
    }
  }

  async checkMemory() {
    const memUsage = process.memoryUsage();
    return {
      rss: `${Math.round(memUsage.rss / 1024 / 1024)}MB`,
      heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)}MB`,
      heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`,
      external: `${Math.round(memUsage.external / 1024 / 1024)}MB`,
    };
  }

  async getHealthStatus() {
    const [dbStatus, redisStatus, memory] = await Promise.all([
      this.checkDatabase(),
      this.checkRedis(),
      this.checkMemory(),
    ]);

    const overall =
      dbStatus.status === "ok" && redisStatus.status === "ok"
        ? "healthy"
        : "unhealthy";

    return {
      status: overall,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      services: {
        database: dbStatus,
        redis: redisStatus,
      },
      system: {
        memory,
        nodeVersion: process.version,
        platform: process.platform,
      },
    };
  }
}

module.exports = new HealthService();
