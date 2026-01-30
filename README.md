# ScholarLens 🎓

An intelligent educational assistant powered by AI that helps students learn effectively through interactive features like AI tutoring, flashcard generation, and study planning.

## 🌟 Features

### Core Features
- **AI Tutor Chat** - Socratic method-based AI tutoring with guided discovery learning
- **Smart Flashcard Generation** - AI-powered flashcard creation from study materials
- **Image Analysis** - Snap photos of textbooks, problems, or notes for instant explanations
- **Study Planning** - Personalized study schedules and revision plans
- **Progress Tracking** - Monitor learning progress and performance analytics
- **Multi-platform Support** - Available on iOS, Android, and Web

### AI-Powered Learning Tools
- **Concept Explanations** - Step-by-step breakdowns of complex topics
- **Quiz Generation** - Automated quiz creation for self-assessment
- **Syllabus Analysis** - Smart analysis of course syllabi for study planning
- **Document Processing** - Extract key information from PDFs and images

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **State Management**: Provider pattern
- **Authentication**: Google Sign-In integration
- **Storage**: Secure local storage with encryption
- **Animations**: Custom animation system with performance optimization

### Backend (Node.js)
- **Runtime**: Node.js with Express.js
- **AI Integration**: Google Vertex AI (Gemini models)
- **Authentication**: JWT-based auth with Google OAuth
- **Storage**: Google Cloud Storage for file uploads
- **Database**: Firebase integration
- **Logging**: Comprehensive Winston-based logging system

### AI Services
- **Primary AI**: Google Vertex AI (Gemini 1.5 Pro/Flash)
- **ScienceQA Integration**: Specialized science question answering
- **Image Processing**: Vision AI for document and image analysis
- **Prompt Engineering**: Optimized prompts for educational contexts

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** (3.0+)
- **Node.js** (18+)
- **Google Cloud Account** with billing enabled
- **Firebase Project** setup

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <[repository-url](https://github.com/ShubhanginiSharma627/ScholarLens.git)>
   cd ScholarLens/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Required Environment Variables**
   ```env
   # Google Cloud Configuration
   GOOGLE_CLOUD_PROJECT=your-project-id
   GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json
   VERTEX_AI_LOCATION=us-central1
   
   # Firebase Configuration
   FIREBASE_PROJECT_ID=your-firebase-project
   FIREBASE_STORAGE_BUCKET=your-bucket.appspot.com
   
   # AI Model Configuration
   DEFAULT_TEXT_MODEL=gemini-2.5-pro
   DEFAULT_VISION_MODEL=gemini-2.5-pro
   DEFAULT_DOCUMENT_MODEL=gemini-3.0-pro
   
   # Security
   JWT_SECRET=your-jwt-secret
   JWT_EXPIRES_IN=7d
   ```

5. **Start the backend server**
   ```bash
   npm start
   ```

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd ../frontend
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` (Android) to `android/app/`
   - Add `GoogleService-Info.plist` (iOS) to `ios/Runner/`

4. **Run the app**
   ```bash
   # For development
   flutter run
   
   # For specific platform
   flutter run -d chrome  # Web
   flutter run -d ios     # iOS
   flutter run -d android # Android
   ```

## 🔧 Configuration

### Google Cloud Setup

1. **Enable required APIs**
   ```bash
   gcloud services enable aiplatform.googleapis.com
   gcloud services enable storage.googleapis.com
   gcloud services enable firebase.googleapis.com
   ```

2. **Create service account**
   ```bash
   gcloud iam service-accounts create scholarlens-service
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:scholarlens-service@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/aiplatform.user"
   ```

3. **Download service account key**
   ```bash
   gcloud iam service-accounts keys create service-account.json \
     --iam-account=scholarlens-service@YOUR_PROJECT_ID.iam.gserviceaccount.com
   ```

### Firebase Setup

1. Create a new Firebase project
2. Enable Authentication with Google Sign-In
3. Set up Cloud Storage
4. Configure security rules for your use case

## 🧪 Testing

### Backend Testing
```bash
cd backend
npm test
npm run test:integration
```

### Frontend Testing
```bash
cd frontend
flutter test
flutter test integration_test/
```

### Performance Testing
```bash
# Flutter performance profiling
flutter run --profile
flutter drive --target=test_driver/perf_test.dart
```

## 📊 Monitoring & Logging

### Backend Logs
Logs are stored in `backend/logs/` with different categories:
- `ai-service.log` - AI service operations
- `ai-controller.log` - API controller logs
- `performance.log` - Performance metrics
- `security.log` - Authentication and security events

### Performance Monitoring
- Flutter performance metrics tracked automatically
- Backend API response times logged
- AI model performance monitoring
- Error tracking and alerting

## 🔒 Security

### Authentication
- JWT-based authentication
- Google OAuth integration
- Secure token storage
- Session management

### Data Protection
- Encrypted local storage
- Secure API communication (HTTPS)
- Input validation and sanitisation
- Rate limiting on API endpoints

## 🚨 Troubleshooting

### Common Issues

#### Backend Issues
1. **Google Cloud Authentication Errors**
   ```bash
   # Verify service account
   gcloud auth application-default login
   # Check project configuration
   gcloud config get-value project
   ```

2. **AI Model Access Issues**
   - Ensure billing is enabled on Google Cloud
   - Verify Vertex AI API is enabled
   - Check model availability in your region

3. **Performance Issues**
   - Monitor logs in `backend/logs/`
   - Check API response times
   - Verify database connection

#### Frontend Issues
1. **Animation Performance**
   - Check for animation controller disposal errors
   - Monitor frame rates in debug mode
   - Use performance profiling tools

2. **Build Issues**
   ```bash
   flutter clean
   flutter pub get
   flutter pub deps
   ```

### Performance Optimisation

#### Recent Fixes Applied
- ✅ Fixed animation controller double disposal
- ✅ Added comprehensive backend logging
- ✅ Improved error handling in AI services
- ✅ Enhanced performance monitoring

#### Known Issues
- Some Gemini models may not be available in all regions
- Large image uploads may timeout (implement chunked upload)
- Animation performance on older devices needs optimisation

## 📈 Performance Metrics

### Target Performance
- **App Launch Time**: < 3 seconds
- **AI Response Time**: < 10 seconds
- **Image Analysis**: < 15 seconds
- **Frame Rate**: 60 FPS on modern devices

### Monitoring
```bash
# Check backend performance
tail -f backend/logs/performance.log

# Monitor Flutter performance
flutter run --profile
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write comprehensive tests
- Update documentation
- Ensure performance benchmarks are met

## 🙏 Acknowledgments

- Google Cloud AI Platform for Vertex AI services
- Flutter team for the amazing framework
- Firebase for backend services
- Open source community for various packages used

