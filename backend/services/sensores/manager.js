// Módulo extensible para sensores
// Sin tocar el sensor_simulador.py existente

const { spawn } = require('child_process');
const path = require('path');

class SensorManager {
  constructor() {
    this.sensors = new Map(); // Mapa de sensores registrados
    this.activeProcesses = new Map(); // Procesos activos
  }

  // Registrar un nuevo tipo de sensor
  registerSensor(type, config) {
    this.sensors.set(type, config);
  }

  // Iniciar un sensor
  async startSensor(type, options = {}) {
    const config = this.sensors.get(type);
    if (!config) {
      throw new Error(`Sensor type ${type} not registered`);
    }

    // Para sensores Python, ejecutar el script
    if (config.script) {
      const process = spawn('python', [config.script, ...config.args], {
        cwd: path.dirname(config.script),
        stdio: ['pipe', 'pipe', 'pipe']
      });

      this.activeProcesses.set(type, process);

      process.stdout.on('data', (data) => {
        console.log(`Sensor ${type}: ${data}`);
        // Aquí podrías emitir eventos o guardar datos
      });

      process.stderr.on('data', (data) => {
        console.error(`Sensor ${type} error: ${data}`);
      });

      process.on('close', (code) => {
        console.log(`Sensor ${type} exited with code ${code}`);
        this.activeProcesses.delete(type);
      });

      return process;
    }

    // Para otros tipos de sensores (API, hardware, etc.)
    if (config.startFunction) {
      return await config.startFunction(options);
    }
  }

  // Detener un sensor
  stopSensor(type) {
    const process = this.activeProcesses.get(type);
    if (process) {
      process.kill();
      this.activeProcesses.delete(type);
    }
  }

  // Obtener datos de un sensor
  async getSensorData(type) {
    const config = this.sensors.get(type);
    if (config && config.getDataFunction) {
      return await config.getDataFunction();
    }
    return null;
  }

  // Listar sensores registrados
  listSensors() {
    return Array.from(this.sensors.keys());
  }
}

// Instancia singleton
const sensorManager = new SensorManager();

// Registrar el sensor simulador existente (sin modificarlo)
sensorManager.registerSensor('simulador', {
  script: path.join(__dirname, '../../sensores/sensor_simulador.py'),
  args: []
});

// Ejemplo de cómo registrar un sensor futuro
// sensorManager.registerSensor('gps', {
//   startFunction: async (options) => { /* lógica para GPS */ },
//   getDataFunction: async () => { /* obtener datos GPS */ }
// });

module.exports = sensorManager;