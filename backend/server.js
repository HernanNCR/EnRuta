const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const mongoose = require("mongoose");
const ColectivosRutas = require('./routes/colectivos_rutas');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get("/api/hello", (req, res) => {
  res.json({ message: "Servidor funcionando" });
});

app.use('/api/ColectivosRutas', ColectivosRutas);

async function startServer() {
  try {
    await mongoose.connect(process.env.MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log("conetado a mongo");

    app.listen(PORT, () => {
      console.log(`Servidor corriendo en local ${PORT}`);
    });
  } catch (err) {
    console.error("error al conectarse a mongo", err.message);
    process.exit(1);
  }
}

startServer();
