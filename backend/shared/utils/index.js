// Utilidades compartidas
const validateObjectId = (id) => {
  return /^[0-9a-fA-F]{24}$/.test(id);
};

const sanitizeInput = (input) => {
  if (typeof input === 'string') {
    return input.trim().replace(/[<>]/g, '');
  }
  return input;
};

const generateId = () => {
  return Math.random().toString(36).substr(2, 9);
};

module.exports = {
  validateObjectId,
  sanitizeInput,
  generateId
};