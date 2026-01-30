const admin = require('firebase-admin');
const fs = require('fs-extra');
const path = require('path');
const winston = require('winston');
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/firebase-storage.log' })
  ]
});
class FirebaseStorageService {
  constructor() {
    this.bucket = null;
    this.initialized = false;
    this.initializeFirebase();
  }
  initializeFirebase() {
    try {
       if (!admin.apps.length) {
          admin.initializeApp({
               credential: admin.credential.applicationDefault(),
               storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
           });
        }
      this.bucket = admin.storage().bucket();
      this.initialized = true;
      logger.info('Firebase Storage initialized successfully');
    } catch (error) {
      logger.error('Firebase Storage initialization failed', {
      name: error.name,
      message: error.message,
       stack: error.stack,
     });
      this.initialized = false;
    }
  }
  async uploadFile(filePath, destination, metadata = {}) {
    if (!this.initialized) {
      throw new Error('Firebase Storage not initialized');
    }
    try {
      logger.info(`Uploading file to Firebase Storage: ${destination}`);
      const file = this.bucket.file(destination);
      await file.save(await fs.readFile(filePath), {
        metadata: {
          contentType: metadata.contentType || 'application/octet-stream',
          metadata: {
            ...metadata,
            uploadedAt: new Date().toISOString(),
          }
        }
      });
      if (metadata.makePublic) {
        await file.makePublic();
      }
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: metadata.expires || '03-09-2491' // Far future date
      });
      logger.info(`File uploaded successfully: ${destination}`);
      return url;
    } catch (error) {
      logger.error(`File upload failed: ${error.message}`);
      throw error;
    }
  }
  async uploadBuffer(buffer, destination, metadata = {}) {
    if (!this.initialized) {
      throw new Error('Firebase Storage not initialized');
    }
    try {
      logger.info(`Uploading buffer to Firebase Storage: ${destination}`);
      const file = this.bucket.file(destination);
      await file.save(buffer, {
        metadata: {
          contentType: metadata.contentType || 'application/octet-stream',
          metadata: {
            ...metadata,
            uploadedAt: new Date().toISOString(),
          }
        }
      });
      if (metadata.makePublic) {
        await file.makePublic();
      }
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: metadata.expires || '03-09-2491'
      });
      logger.info(`Buffer uploaded successfully: ${destination}`);
      return url;
    } catch (error) {
      logger.error(`Buffer upload failed: ${error.message}`);
      throw error;
    }
  }
  async deleteFile(filePath) {
    if (!this.initialized) {
      throw new Error('Firebase Storage not initialized');
    }
    try {
      logger.info(`Deleting file from Firebase Storage: ${filePath}`);
      const file = this.bucket.file(filePath);
      await file.delete();
      logger.info(`File deleted successfully: ${filePath}`);
    } catch (error) {
      logger.error(`File deletion failed: ${error.message}`);
      throw error;
    }
  }
  async getDownloadUrl(filePath, options = {}) {
    if (!this.initialized) {
      throw new Error('Firebase Storage not initialized');
    }
    try {
      const file = this.bucket.file(filePath);
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: options.expires || '03-09-2491'
      });
      return url;
    } catch (error) {
      logger.error(`Get download URL failed: ${error.message}`);
      throw error;
    }
  }
  async fileExists(filePath) {
    if (!this.initialized) {
      throw new Error('Firebase Storage not initialized');
    }
    try {
      const file = this.bucket.file(filePath);
      const [exists] = await file.exists();
      return exists;
    } catch (error) {
      logger.error(`File exists check failed: ${error.message}`);
      return false;
    }
  }
  async listFiles(prefix = '', options = {}) {
    if (!this.initialized) {
      throw new Error('Firebase Storage not initialized');
    }
    try {
      const [files] = await this.bucket.getFiles({
        prefix,
        maxResults: options.maxResults || 100,
      });
      return files.map(file => ({
        name: file.name,
        size: file.metadata.size,
        contentType: file.metadata.contentType,
        created: file.metadata.timeCreated,
        updated: file.metadata.updated,
      }));
    } catch (error) {
      logger.error(`List files failed: ${error.message}`);
      throw error;
    }
  }
  generateUniqueFilename(originalName, prefix = '') {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    const extension = path.extname(originalName);
    const baseName = path.basename(originalName, extension);
    return `${prefix}${timestamp}-${random}-${baseName}${extension}`;
  }
  async getFileMetadata(filePath) {
    if (!this.initialized) {
      throw new Error('Firebase Storage not initialized');
    }
    try {
      const file = this.bucket.file(filePath);
      const [metadata] = await file.getMetadata();
      return metadata;
    } catch (error) {
      logger.error(`Get file metadata failed: ${error.message}`);
      throw error;
    }
  }
  isConfigured() {
    return this.initialized && !!process.env.FIREBASE_STORAGE_BUCKET;
  }
  getConfigStatus() {
    return {
      initialized: this.initialized,
      bucketConfigured: !!process.env.FIREBASE_STORAGE_BUCKET,
      projectConfigured: !!process.env.FIREBASE_PROJECT_ID,
      credentialsConfigured: !!(process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL),
    };
  }
}
module.exports = new FirebaseStorageService();