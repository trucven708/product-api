require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');

const app = express();
app.use(express.json());
app.use('/api/products', require('./routes/products'));

const PORT = process.env.PORT || 3000;

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('Đã kết nối MongoDB');
    app.listen(PORT, () => console.log(`API chạy tại http://localhost:${PORT}`));
  })
  .catch((err) => {
    console.error('Kết nối MongoDB thất bại:', err.message);
    process.exit(1);
    const = ;
  });
  