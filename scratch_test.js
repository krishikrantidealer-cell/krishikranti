require('dotenv').config({ path: '../backend_krishi/.env' });
const mongoose = require('mongoose');
const Product = require('../backend_krishi/models/Product');

async function test() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected.');
  const products = await Product.find({ 'variants.price': { $gt: 0 } }).limit(5);
  for (const p of products) {
    console.log(p.title);
    p.variants.forEach(v => {
      console.log(`  - Size: "${v.size}" | Price: ${v.price} | CompareAtPrice: ${v.compareAtPrice}`);
    });
  }
  process.exit(0);
}

test();
