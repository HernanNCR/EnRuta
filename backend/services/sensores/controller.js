const sensorManager = require("./manager");

class SensoresController {
  async listSensors(req, res) {
    res.json({
      sensors: sensorManager.listSensors(),
      active: Array.from(sensorManager.activeProcesses.keys())
    });
  }

  async startSensor(req, res) {
    try {
      const { type } = req.params;
      await sensorManager.startSensor(type);
      res.json({ message: `Sensor ${type} started` });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }

  async stopSensor(req, res) {
    const { type } = req.params;
    sensorManager.stopSensor(type);
    res.json({ message: `Sensor ${type} stopped` });
  }

  async getSensorData(req, res) {
    try {
      const { type } = req.params;
      const data = await sensorManager.getSensorData(type);
      res.json({ data });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
}

module.exports = new SensoresController();