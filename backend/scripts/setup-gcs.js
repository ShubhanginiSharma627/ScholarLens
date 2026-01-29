#!/usr/bin/env node

/**
 * Setup script for Google Cloud Storage
 * This script creates the GCS bucket if it doesn't exist
 */

require('dotenv').config();
const gcsStorage = require('../src/services/gcs-storage.service');

async function setupGCS() {
  try {
    console.log('🔧 Setting up Google Cloud Storage...');
    
    // Check configuration
    const config = gcsStorage.getConfigStatus();
    console.log('Configuration status:', config);
    
    if (!config.initialized) {
      console.error('❌ GCS not initialized. Check your configuration.');
      process.exit(1);
    }
    
    // Create bucket if it doesn't exist
    const bucketName = process.env.GCS_BUCKET || `${process.env.GOOGLE_CLOUD_PROJECT}-storage`;
    console.log(`📦 Creating bucket if not exists: ${bucketName}`);
    
    await gcsStorage.createBucketIfNotExists(bucketName, {
      location: 'US',
      storageClass: 'STANDARD'
    });
    
    // Test bucket access
    console.log('🧪 Testing bucket access...');
    const bucketInfo = await gcsStorage.getBucketInfo();
    console.log('Bucket info:', bucketInfo);
    
    console.log('✅ Google Cloud Storage setup completed successfully!');
    
  } catch (error) {
    console.error('❌ GCS setup failed:', error.message);
    process.exit(1);
  }
}

// Run setup if called directly
if (require.main === module) {
  setupGCS();
}

module.exports = { setupGCS };