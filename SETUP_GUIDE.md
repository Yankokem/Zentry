# Zentry App - Setup Guide

This guide will help you configure the necessary API keys and services for the Zentry app.

## 🔧 Required Configurations

### 1. Cloudinary Setup (Image Storage)

Cloudinary is used for storing user profile images and other media throughout the application.

#### Steps to Configure:

1. **Create a Cloudinary Account**
   - Go to [https://cloudinary.com/](https://cloudinary.com/)
   - Sign up for a free account

2. **Get Your Credentials**
   - After logging in, go to your [Cloudinary Console Dashboard](https://cloudinary.com/console)
   - You'll find:
     - **Cloud Name** (e.g., `dxxxxxxxxx`)
     - **API Key**
     - **API Secret**

3. **Create an Upload Preset**
   - In the Cloudinary dashboard, go to **Settings** → **Upload**
   - Scroll down to **Upload presets**
   - Click **Add upload preset**
   - Set:
     - **Preset name**: `zentry_uploads` (or any name you prefer)
     - **Signing Mode**: `Unsigned` (for client-side uploads)
     - **Folder**: Optional, you can set a default folder
   - Click **Save**

4. **Update the Code**
   - Open `lib/core/services/cloudinary_service.dart`
   - Replace the placeholder values:
     ```dart
     static const String _cloudName = 'YOUR_CLOUD_NAME'; // Replace with your cloud name
     static const String _uploadPreset = 'YOUR_UPLOAD_PRESET'; // Replace with your preset name
     ```

5. **Initialize Cloudinary Service**
   - The service needs to be initialized when the app starts
   - Add this to your `main.dart` before running the app:
     ```dart
     void main() async {
       WidgetsFlutterBinding.ensureInitialized();
       await Firebase.initializeApp();
       
       // Initialize Cloudinary
       CloudinaryService().initialize();
       
       runApp(const MyApp());
     }
     ```

---

### 2. Google Places API Setup (Location Autocomplete)

The Google Places API is used for the complete address/location search in Account Settings.

#### Steps to Configure:

1. **Get a Google Cloud API Key**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Go to **APIs & Services** → **Library**
   - Search for and enable these APIs:
     - **Places API**
     - **Geocoding API** (optional, for coordinates)
   
2. **Create an API Key**
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **API Key**
   - Copy the generated API key
   
3. **Restrict the API Key (Recommended)**
   - Click on the API key you just created
   - Under **API restrictions**, select **Restrict key**
   - Choose:
     - **Places API**
     - **Geocoding API**
   - Under **Application restrictions** (for production):
     - For Android: Add your app's package name and SHA-1 fingerprint
     - For iOS: Add your app's bundle identifier
   - Click **Save**

4. **Update the Code**
   - Open `lib/features/profile/views/account_settings_screen.dart`
   - Find the line with `googleAPIKey`:
     ```dart
     googleAPIKey: "YOUR_GOOGLE_PLACES_API_KEY", // Replace with your actual API key
     ```
   - Replace `YOUR_GOOGLE_PLACES_API_KEY` with your actual API key

5. **Configure for Android**
   - Open `android/app/src/main/AndroidManifest.xml`
   - Add inside the `<application>` tag:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_GOOGLE_PLACES_API_KEY"/>
     ```

6. **Configure for iOS**
   - Open `ios/Runner/AppDelegate.swift`
   - Add at the top:
     ```swift
     import GoogleMaps
     ```
   - In the `application` function, add:
     ```swift
     GMSServices.provideAPIKey("YOUR_GOOGLE_PLACES_API_KEY")
     ```

---

## 📝 Summary of Changes Made

### Account Settings Screen Updates:

1. ✅ **Image Storage**: Changed from Firebase Storage to **Cloudinary**
   - More efficient and scalable
   - Better image transformations and CDN delivery

2. ✅ **Location Field**: Changed from simple country picker to **Google Places Autocomplete**
   - Now supports complete addresses (street, city, province, postal code, country)
   - Auto-suggestion with search functionality
   - Prioritizes Philippines but allows global search

3. ✅ **Phone Number**: Default country changed to **Philippines (PH)**
   - Previously defaulted to US
   - Now defaults to PH for Philippine users

4. ✅ **Save Button Color**: Theme-aware color scheme
   - **Light Mode**: Black text
   - **Dark Mode**: Yellow (#F9ED69) text

---

## 🚀 Testing the Changes

After configuration, test the following:

1. **Profile Image Upload**
   - Go to Account Settings
   - Tap the profile photo
   - Select an image
   - Click Save
   - Verify the image appears and is stored in your Cloudinary dashboard

2. **Location Search**
   - Go to Account Settings
   - Click on the Location field
   - Start typing an address (e.g., "Manila, Philippines")
   - Select from the dropdown suggestions
   - Verify the complete address is saved

3. **Phone Number**
   - Go to Account Settings
   - Check that Philippines (+63) is the default country
   - Enter a phone number and save

4. **Save Button**
   - Toggle between light and dark mode
   - Verify the Save button is:
     - Black in light mode
     - Yellow in dark mode

---

## 📦 Packages Added

The following packages were added to `pubspec.yaml`:

```yaml
cloudinary_public: ^0.23.1      # For Cloudinary image uploads
google_places_flutter: ^2.0.9   # For Google Places autocomplete
```

Run `flutter pub get` to install these packages.

---

## ⚠️ Important Notes

1. **API Keys Security**
   - Never commit API keys to version control
   - Consider using environment variables or Flutter's build configs
   - For production, use API key restrictions

2. **Cloudinary Free Tier**
   - Free tier includes 25GB storage and 25GB bandwidth/month
   - Sufficient for most applications
   - Monitor usage in the Cloudinary dashboard

3. **Google Places API Billing**
   - Google provides $200 free credit per month
   - Places Autocomplete costs $2.83 per 1000 requests (after free tier)
   - Monitor usage in Google Cloud Console

4. **Testing**
   - Test image uploads in Cloudinary dashboard
   - Test location searches with real addresses
   - Verify data is saved correctly in Firestore

---

## 🔍 Troubleshooting

### Cloudinary Issues
- **Image not uploading**: Check cloud name and upload preset
- **403 Error**: Verify upload preset is set to "Unsigned"
- **Slow uploads**: Check image size (compress if needed)

### Google Places Issues
- **No suggestions**: Verify API key is correct and Places API is enabled
- **Billing error**: Ensure billing is enabled on Google Cloud project
- **Limited results**: Check API key restrictions

---

## 📞 Support

For issues or questions:
- Check the package documentation
- Review error messages in debug console
- Ensure all API keys are correctly configured

Happy coding! 🎉
