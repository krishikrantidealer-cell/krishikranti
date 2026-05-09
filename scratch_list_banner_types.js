// Inject backend node_modules path so we can resolve mongoose
module.paths.push('c:/Users/yashs/office projects/backend_krishi/node_modules');

const mongoose = require('mongoose');

const MONGODB_URI = 'mongodb+srv://krishikrantidealer_db_user:oGAe7oVFsuMTG84X@cluster0.ky5rerp.mongodb.net/krishikranti_db?appName=Cluster0';

async function run() {
  try {
    console.log('Connecting to database...');
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB!');

    // Define schema
    const bannerSchema = new mongoose.Schema({}, { strict: false, collection: 'banners' });
    const Banner = mongoose.model('Banner', bannerSchema);

    // 1. Get unique types of banners
    const types = await Banner.distinct('type');
    console.log('\nUnique Banner Types in Database:', types);

    // 2. Print a sample of each type
    for (const t of types) {
      const sample = await Banner.findOne({ type: t }).lean();
      console.log(`\n--- Type: "${t}" (Total Count: ${await Banner.countDocuments({ type: t })}) ---`);
      if (sample) {
        console.log(`ID: ${sample._id}`);
        console.log(`Title: ${sample.title}`);
        console.log(`ImageUrl: ${sample.imageUrl}`);
        console.log(`RedirectType: ${sample.redirectType}`);
        console.log(`RedirectTarget: ${sample.redirectTarget}`);
        if (sample.homebanners) console.log(`homebanners array length: ${sample.homebanners.length}`);
        if (sample.categorybanners) console.log(`categorybanners array length: ${sample.categorybanners.length}`);
        if (sample.categorycardbanners) console.log(`categorycardbanners array length: ${sample.categorycardbanners.length}`);
      }
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from database.');
  }
}

run();
