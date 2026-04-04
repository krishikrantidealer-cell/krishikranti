const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Product = require('./models/Product');

dotenv.config();

const dummyProducts = [
  {
    title: 'Urea Fertilizer',
    body: 'High quality urea for providing essential nitrogen to your crops. Enhances growth and leaf size.',
    vendor: 'krishikranti',
    productCategory: 'Fertilizers',
    tags: ['cod', 'prepaid'],
    images: ['https://via.placeholder.com/400x400?text=Urea+Fertilizer'],
    availabilityStatus: 'In Stock',
    variants: [
      { size: '10kg', price: 90, compareAtPrice: 120, weight: 10 },
      { size: '50kg', price: 266, compareAtPrice: 350, weight: 50 }
    ]
  },
  {
    title: 'Hybrid Wheat Seeds (HD-2967)',
    body: 'High yield wheat seeds suitable for various climates. Excellent resistance to yellow rust.',
    vendor: 'krishikranti',
    productCategory: 'Seeds',
    tags: ['prepaid', 'partial payment'],
    images: ['https://via.placeholder.com/400x400?text=Wheat+Seeds'],
    availabilityStatus: 'In Stock',
    variants: [
      { size: '10kg', price: 450, compareAtPrice: 550, weight: 10 },
      { size: '40kg', price: 1700, compareAtPrice: 2100, weight: 40 }
    ]
  },
  {
    title: 'Organic Neem Oil Pesticide',
    body: 'Eco-friendly pesticide to protect crops without harming the soil. Works effectively on aphids and whiteflies.',
    vendor: 'krishikranti',
    productCategory: 'Pesticides',
    tags: ['cod'],
    images: ['https://via.placeholder.com/400x400?text=Neem+Oil'],
    availabilityStatus: 'In Stock',
    variants: [
      { size: '500ml', price: 450, compareAtPrice: 600, weight: 0.5 },
      { size: '1 Liter', price: 800, compareAtPrice: 1100, weight: 1 },
      { size: '5 Liters', price: 3800, compareAtPrice: 4500, weight: 5 }
    ]
  },
  {
    title: 'DAP Fertilizer (Di-ammonium Phosphate)',
    body: 'Excellent source of Phosphorus and Nitrogen for healthy root development.',
    vendor: 'krishikranti',
    productCategory: 'Fertilizers',
    tags: ['cod', 'prepaid', 'partial payment'],
    images: ['https://via.placeholder.com/400x400?text=DAP+Fertilizer'],
    availabilityStatus: 'In Stock',
    variants: [
      { size: '50kg', price: 1350, compareAtPrice: 1500, weight: 50 },
      { size: '100kg', price: 2600, compareAtPrice: 3000, weight: 100 }
    ]
  },
  {
    title: 'N-P-K 19:19:19 Water Soluble',
    body: '100% water soluble balanced fertilizer for foliar spray and drip irrigation.',
    vendor: 'krishikranti',
    productCategory: 'Fertilizers',
    tags: ['prepaid'],
    images: ['https://via.placeholder.com/400x400?text=NPK+19-19-19'],
    availabilityStatus: 'In Stock',
    variants: [
      { size: '1kg', price: 150, compareAtPrice: 200, weight: 1 },
      { size: '5kg', price: 600, compareAtPrice: 900, weight: 5 }
    ]
  },
  {
    title: 'Premium Bt Cotton Seeds',
    body: 'Advanced cotton seeds highly resistant to bollworms. Specifically developed for medium to heavy soils.',
    vendor: 'krishikranti',
    productCategory: 'Seeds',
    tags: ['cod', 'partial payment'],
    images: ['https://via.placeholder.com/400x400?text=Cotton+Seeds'],
    availabilityStatus: 'In Stock',
    variants: [
      { size: '450gm', price: 800, compareAtPrice: 950, weight: 0.45 },
      { size: '900gm', price: 1550, compareAtPrice: 1900, weight: 0.90 }
    ]
  },
  {
    title: 'Manual Knapsack Sprayer',
    body: 'Comfortable manual pump sprayer for liquid fertilizers and pesticides. Features adjustable nozzles and a durable tank.',
    vendor: 'krishikranti',
    productCategory: 'Equipment',
    tags: ['prepaid', 'partial payment'],
    images: ['https://via.placeholder.com/400x400?text=Knapsack+Sprayer'],
    availabilityStatus: 'In Stock',
    variants: [
      { size: '16 Liters', price: 1200, compareAtPrice: 1500, weight: 3.5 },
      { size: '20 Liters', price: 1450, compareAtPrice: 1800, weight: 4.2 }
    ]
  },
  {
    title: 'Systemic Fungicide (Hexaconazole 5% EC)',
    body: 'Highly effective systemic fungicide used for the control of powdery mildew, sheath blight, and leaf spots.',
    vendor: 'krishikranti',
    productCategory: 'Pesticides',
    tags: ['cod', 'prepaid'],
    images: ['https://via.placeholder.com/400x400?text=Fungicide'],
    availabilityStatus: 'In Stock',
    variants: [
      { size: '250ml', price: 210, compareAtPrice: 280, weight: 0.25 },
      { size: '500ml', price: 380, compareAtPrice: 500, weight: 0.5 },
      { size: '1 Liter', price: 720, compareAtPrice: 950, weight: 1 }
    ]
  },
  {
    title: 'Tomato Seeds (Hybrid Arka Rakshak)',
    body: 'Triple disease resistant hybrid tomato seeds. Produces firm, deep red fruits suitable for long transport.',
    vendor: 'krishikranti',
    productCategory: 'Seeds',
    tags: ['cod'],
    images: ['https://via.placeholder.com/400x400?text=Tomato+Seeds'],
    availabilityStatus: 'Out of Stock',
    variants: [
      { size: '10gm', price: 450, compareAtPrice: 600, weight: 0.01 },
      { size: '50gm', price: 2000, compareAtPrice: 2800, weight: 0.05 }
    ]
  },
  {
    title: 'Battery Operated Sprayer',
    body: 'High pressure double motor battery sprayer. Ideal for large farms and orchards. Includes 12V 12Ah battery.',
    vendor: 'krishikranti',
    productCategory: 'Equipment',
    tags: ['prepaid', 'partial payment'],
    images: ['https://via.placeholder.com/400x400?text=Battery+Sprayer'],
    availabilityStatus: 'In Stock',
    variants: [
      { size: '18 Liters (Single Motor)', price: 2800, compareAtPrice: 3500, weight: 6 },
      { size: '18 Liters (Double Motor)', price: 3500, compareAtPrice: 4200, weight: 6.5 }
    ]
  }
];

async function seedDatabase() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB for seeding...');

    await Product.deleteMany();
    console.log('🗑️  Cleared existing products.');

    await Product.insertMany(dummyProducts);
    console.log('🌱 Successfully added 10 advanced product variations to the Krishi Kranti database!');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
}

seedDatabase();
