// Servicio base para integraciones con proveedores de pago
class ProveedorPagoBase {
  constructor(config) {
    this.config = config;
  }

  // Método que deben implementar los proveedores específicos
  async procesarPago(pagoId) {
    throw new Error('Método procesarPago debe ser implementado por el proveedor');
  }

  async reembolsarPago(pagoId, monto) {
    throw new Error('Método reembolsarPago debe ser implementado por el proveedor');
  }

  async verificarEstado(pagoId) {
    throw new Error('Método verificarEstado debe ser implementado por el proveedor');
  }
}

// Ejemplo de implementación para Stripe (placeholder)
class StripeProvider extends ProveedorPagoBase {
  async procesarPago(pagoId) {
    // Aquí iría la integración real con Stripe
    console.log(`Procesando pago ${pagoId} con Stripe`);
    return {
      exito: true,
      referencia: `stripe_${Date.now()}`,
      estado: 'completado'
    };
  }
}

// Ejemplo de implementación para MercadoPago
class MercadoPagoProvider extends ProveedorPagoBase {
  async procesarPago(pagoId) {
    // Aquí iría la integración real con MercadoPago
    console.log(`Procesando pago ${pagoId} con MercadoPago`);
    return {
      exito: true,
      referencia: `mp_${Date.now()}`,
      estado: 'completado'
    };
  }
}

module.exports = {
  ProveedorPagoBase,
  StripeProvider,
  MercadoPagoProvider
};