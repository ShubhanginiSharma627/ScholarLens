const { OAuth2Client } = require('google-auth-library');
const winston = require('winston');
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/google-auth.log' })
  ]
});
class GoogleAuthService {
  constructor() {
    this.client = new OAuth2Client(process.env.GOOGLE_OAUTH_CLIENT_ID);
    this.webClientId = process.env.GOOGLE_OAUTH_CLIENT_ID;
    this.androidClientId = process.env.GOOGLE_OAUTH_ANDROID_CLIENT_ID;
    this.iosClientId = process.env.GOOGLE_OAUTH_IOS_CLIENT_ID;
  }
  async verifyGoogleToken(idToken, clientType = 'web') {
    try {
      logger.info(`Verifying Google token for client type: ${clientType}`);
      let audience = this.webClientId;
      if (clientType === 'android' && this.androidClientId) {
        audience = this.androidClientId;
      } else if (clientType === 'ios' && this.iosClientId) {
        audience = this.iosClientId;
      }
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: [audience, this.webClientId], // Accept both platform-specific and web client IDs
      });
      const payload = ticket.getPayload();
      if (!payload.sub || !payload.email) {
        throw new Error('Invalid token payload: missing required fields');
      }
      if (!payload.email_verified) {
        throw new Error('Email not verified by Google');
      }
      logger.info(`Google token verified successfully for user: ${payload.email}`);
      return {
        googleId: payload.sub,
        email: payload.email,
        name: payload.name || '',
        firstName: payload.given_name || '',
        lastName: payload.family_name || '',
        picture: payload.picture || '',
        emailVerified: payload.email_verified,
        locale: payload.locale || 'en',
        hd: payload.hd, // Hosted domain (for G Suite accounts)
      };
    } catch (error) {
      logger.error(`Google token verification failed: ${error.message}`);
      throw new Error(`Invalid Google token: ${error.message}`);
    }
  }
  async verifyAndValidateToken(idToken, clientType = 'web', options = {}) {
    try {
      const userInfo = await this.verifyGoogleToken(idToken, clientType);
      if (options.requireVerifiedEmail && !userInfo.emailVerified) {
        throw new Error('Email verification required');
      }
      if (options.allowedDomains && options.allowedDomains.length > 0) {
        const emailDomain = userInfo.email.split('@')[1];
        if (!options.allowedDomains.includes(emailDomain)) {
          throw new Error(`Email domain ${emailDomain} not allowed`);
        }
      }
      if (options.requireHostedDomain && !userInfo.hd) {
        throw new Error('G Suite account required');
      }
      return userInfo;
    } catch (error) {
      logger.error(`Google token validation failed: ${error.message}`);
      throw error;
    }
  }
  isConfigured() {
    const isConfigured = !!(this.webClientId);
    if (!isConfigured) {
      logger.warn('Google OAuth not configured: GOOGLE_OAUTH_CLIENT_ID missing');
    }
    return isConfigured;
  }
  getConfigStatus() {
    return {
      webClientConfigured: !!this.webClientId,
      androidClientConfigured: !!this.androidClientId,
      iosClientConfigured: !!this.iosClientId,
      fullyConfigured: this.isConfigured(),
    };
  }
}
module.exports = new GoogleAuthService();