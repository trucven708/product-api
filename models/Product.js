const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  pid:      { type: Number, required: true, unique: false },
  pname:    { type: String, required: true, trim: true },
  price:    { type: Number, required: true, min: 0 },
  quantity: { type: Number, required: true, min: 0 }
});

module.exports = mongoose.model('Product', productSchema);