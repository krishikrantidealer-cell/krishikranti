const mongoose = require('mongoose');

const variantSchema = new mongoose.Schema({
  size: { 
    type: String, 
    required: true 
  }, // e.g., '1kg', '50kg', '500ml', '18 Liters'
  price: { 
    type: Number, 
    required: true 
  }, // The discounted 'Krishi Kranti' price
  compareAtPrice: { 
    type: Number, 
    required: true 
  }, // The actual/original market price
  weight: { 
    type: Number, 
    required: true 
  }, // Numerical weight for potential shipping calculations
});

const productSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
  },
  body: {
    type: String,
    trim: true,
  },
  vendor: {
    type: String,
    default: 'krishikranti',
  },
  productCategory: {
    type: String,
    required: true,
  },
  tags: [{
    type: String,
    enum: ['cod', 'prepaid', 'partial payment'],
    trim: true,
  }],
  variants: [variantSchema],
  images: [{
    type: String,
  }],
  availabilityStatus: {
    type: String,
    enum: ['In Stock', 'Out of Stock', 'Pre-order'],
    default: 'In Stock',
  },
  averageRating: {
    type: Number,
    default: 0,
  },
  numReviews: {
    type: Number,
    default: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Product', productSchema);
