from flask import Flask, request, jsonify
import pymongo

app = Flask(__name__)

myclient = pymongo.MongoClient("mongodb://localhost:27017/")
db = myclient["enRuta"]
mycol = db["colectivos"]
# print(myclient.list_database_names())
# print(db.list_collection_names())






# # funcion de prueba de sensor, si hay movimiento esta función se activa
# @app.route('/movimiento', methods=['POST'])
# def recibir_movimiento():
#     data = request.get_json()
#     print("🚨 Movimiento detectado por ESP32:", data)
#     return jsonify({"status": "ok"}), 200



# # agregaremos segun dependa el sensor que una de las 2 funciones se active, si el sensor 34 se activa es porque un pasajero se agrega
# # si el sensor 35 se activa es porque un pasajero se quita

# agregar usuario al colectivo
@app.route('/agregarPasaje', methods=['POST'])
def agregarPasaje():
    # tomar numero economico de los sensores
    data = request.get_json()
    print("Pasajero Entrando", data)
    print(data["id"])
    
    # buscar y agregar pasajero
    mycolectivos = mycol.find({"numero_economico":data["id"]})
    
    for colectivo in mycolectivos:
        espacios = colectivo.get("lugaresDisponibles", 0)
        newValue = espacios + 1

        # Actualizar el documento
        mycol.update_one(
            {"numero_economico": colectivo["numero_economico"]},   
            {"$set": {"lugaresDisponibles": newValue}}  
        )

        print(f"Actualizado lugaresDisponibles → {newValue}")
        
    
    return jsonify({"status": "ok"}), 200




# # desagregar usuario al colectivo
@app.route('/quitarPasajero', methods=['POST'])
def quitarPasajero():
    # tomar numero economico de los sensores
    data = request.get_json()
    print("Pasajero Saliendo", data)
    print(data["id"])
    
    # buscar y agregar pasajero
    mycolectivos = mycol.find({"numero_economico":data["id"]})
    
    for colectivo in mycolectivos:
        espacios = colectivo.get("lugaresDisponibles", 0)
        newValue = espacios - 1

        # Actualizar el documento
        mycol.update_one(
            {"numero_economico": colectivo["numero_economico"]},   
            {"$set": {"lugaresDisponibles": newValue}}  
        )

        print(f"Actualizado lugaresDisponibles → {newValue}")
    
   
    return jsonify({"status": "ok"}), 200




if __name__ == '__main__':
    app.run(host='192.168.1.73', port=5000)

