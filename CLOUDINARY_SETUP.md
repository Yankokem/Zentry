# Cloudinary Setup Guide - Signed Upload Presets

Cloud Name: **dg1cz2twr**

## 📋 Overview

This guide will walk you through creating **signed upload presets** for all image upload types in the Zentry app. Signed presets are more secure than unsigned presets because they require server-side signature generation.

---

## 🔐 Why Use Signed Presets?

- **Security**: Prevents unauthorized uploads
- **Control**: You can restrict file types, sizes, and transformations
- **Organization**: Separate folders for different image types
- **Quota Management**: Better control over storage usage

---

## 📝 Step-by-Step: Creating Upload Presets

### 1. Access Cloudinary Dashboard

1. Go to [https://cloudinary.com/console](https://cloudinary.com/console)
2. Log in to your account
3. You should see your cloud name: **dg1cz2twr**

---

### 2. Create Upload Presets

Go to **Settings** (gear icon) → **Upload** → Scroll to **Upload presets**

Create **6 separate upload presets** for each image type:

---

#### ✅ Preset 1: Account Photos

**Click "Add upload preset"**

**Basic Settings:**
- **Preset name**: `zentry_account_photos`
- **Signing Mode**: **Signed** ⚠️ (Important!)
- **Folder**: `zentry/account_photos`

**Upload Manipulations:**
- **Allowed formats**: `jpg, png, jpeg, webp`
- **Max file size**: `5 MB` (5000000 bytes)
- **Max image width**: `2048 px`
- **Max image height**: `2048 px`

**Transformations:**
- **Incoming Transformation**: 
  - Width: `1024`
  - Height: `1024`
  - Crop: `limit`
  - Quality: `auto:good`
  - Format: `auto`

**Click "Save"**

---

#### ✅ Preset 2: Journal Image Attachments

**Click "Add upload preset"**

**Basic Settings:**
- **Preset name**: `zentry_journal_images`
- **Signing Mode**: **Signed**
- **Folder**: `zentry/journal_images`

**Upload Manipulations:**
- **Allowed formats**: `jpg, png, jpeg, webp, gif`
- **Max file size**: `10 MB` (10000000 bytes)
- **Max image width**: `4096 px`
- **Max image height**: `4096 px`

**Transformations:**
- **Incoming Transformation**: 
  - Width: `2048`
  - Height: `2048`
  - Crop: `limit`
  - Quality: `auto:good`
  - Format: `auto`

**Click "Save"**

---

#### ✅ Preset 3: Project Image Attachments

**Click "Add upload preset"**

**Basic Settings:**
- **Preset name**: `zentry_project_images`
- **Signing Mode**: **Signed**
- **Folder**: `zentry/project_images`

**Upload Manipulations:**
- **Allowed formats**: `jpg, png, jpeg, webp`
- **Max file size**: `10 MB` (10000000 bytes)
- **Max image width**: `4096 px`
- **Max image height**: `4096 px`

**Transformations:**
- **Incoming Transformation**: 
  - Width: `2048`
  - Height: `2048`
  - Crop: `limit`
  - Quality: `auto:good`
  - Format: `auto`

**Click "Save"**

---

#### ✅ Preset 4: Wishlist Image Attachments

**Click "Add upload preset"**

**Basic Settings:**
- **Preset name**: `zentry_wishlist_images`
- **Signing Mode**: **Signed**
- **Folder**: `zentry/wishlist_images`

**Upload Manipulations:**
- **Allowed formats**: `jpg, png, jpeg, webp`
- **Max file size**: `8 MB` (8000000 bytes)
- **Max image width**: `3072 px`
- **Max image height**: `3072 px`

**Transformations:**
- **Incoming Transformation**: 
  - Width: `1920`
  - Height: `1920`
  - Crop: `limit`
  - Quality: `auto:good`
  - Format: `auto`

**Click "Save"**

---

#### ✅ Preset 5: Bug Report Image Attachments

**Click "Add upload preset"**

**Basic Settings:**
- **Preset name**: `zentry_bug_reports`
- **Signing Mode**: **Signed**
- **Folder**: `zentry/bug_reports`

**Upload Manipulations:**
- **Allowed formats**: `jpg, png, jpeg, webp`
- **Max file size**: `5 MB` (5000000 bytes)
- **Max image width**: `2048 px`
- **Max image height**: `2048 px`

**Transformations:**
- **Incoming Transformation**: 
  - Width: `1920`
  - Height: `1920`
  - Crop: `limit`
  - Quality: `auto:good`
  - Format: `auto`

**Click "Save"**

---

#### ✅ Preset 6: Account Appeal Image Attachments

**Click "Add upload preset"**

**Basic Settings:**
- **Preset name**: `zentry_account_appeals`
- **Signing Mode**: **Signed**
- **Folder**: `zentry/account_appeals`

**Upload Manipulations:**
- **Allowed formats**: `jpg, png, jpeg, webp, pdf`
- **Max file size**: `5 MB` (5000000 bytes)
- **Max image width**: `2048 px`
- **Max image height**: `2048 px`

**Transformations:**
- **Incoming Transformation**: 
  - Width: `1920`
  - Height: `1920`
  - Crop: `limit`
  - Quality: `auto:good`
  - Format: `auto`

**Click "Save"**

---

## 🔑 Get Your API Credentials

After creating all presets, you need your API credentials:

1. Go to **Settings** → **Access Keys** (or Dashboard home)
2. You'll find:
   - **Cloud Name**: `dg1cz2twr` ✅ (You already have this)
   - **API Key**: (Copy this - looks like: `123456789012345`)
   - **API Secret**: (Copy this - keep it secret!)

---

## 💻 Update Your Code

### Option 1: Using Environment Variables (Recommended for Security)

**Note**: Since `cloudinary_public` package only supports **unsigned** uploads, and you want to use **signed** presets, you have two options:

#### ⚠️ IMPORTANT: Use Unsigned Presets

The `cloudinary_public` package used in this app **only supports UNSIGNED presets**.

**You MUST change "Signing Mode" to UNSIGNED** for all presets above.

**Steps:**
1. When creating each preset, set **Signing Mode** to **Unsigned**
2. All other settings (folder, file size, transformations) remain the same
3. After creating unsigned presets, the app will work without errors

**Why Unsigned?**
- The `cloudinary_public` package doesn't support signed uploads
- Unsigned presets still provide folder organization and transformations
- For production apps with high security needs, you would switch to the full `cloudinary` SDK

**Security Note:**
While unsigned presets are less secure than signed ones, you can still protect your account by:
- Setting strict file size limits in each preset
- Configuring allowed file formats
- Monitoring upload activity in Cloudinary dashboard
- Using Cloudinary's usage quotas and alerts

---

## 📊 Folder Structure in Cloudinary

After setup, your Cloudinary will have this structure:

```
zentry/
├── account_photos/       (Profile pictures)
├── journal_images/       (Journal entries images)
├── project_images/       (Project attachments)
├── wishlist_images/      (Wishlist item images)
├── bug_reports/          (Bug report screenshots)
└── account_appeals/      (Account appeal documents)
```

---

## ✅ Verification Checklist

After creating all presets:

- [ ] All 6 presets created
- [ ] All set to **Signed** mode
- [ ] Each has correct folder path
- [ ] File size limits configured
- [ ] Image transformations added
- [ ] API Key and Secret copied
- [ ] Code updated with credentials

---

## 🚀 Next Steps

1. **Create all 6 presets** following the steps above
2. **Copy your API Key and Secret**
3. **Let me know when done**, and I'll update the `cloudinary_service.dart` to use signed uploads with proper security
4. **Test each upload type** to ensure everything works

---

## 🔒 Security Best Practices

1. **Never commit API secrets to Git**
   - Use environment variables
   - Add to `.gitignore`

2. **Use signed presets** for production
   - More secure than unsigned
   - Prevents unauthorized uploads

3. **Set file size limits** to prevent abuse
   - Profile photos: 5 MB
   - Content images: 10 MB
   - Bug reports: 5 MB

4. **Monitor usage** in Cloudinary dashboard
   - Check storage quotas
   - Review bandwidth usage

---

## 📞 Need Help?

If you encounter issues:
1. Check preset names match exactly
2. Verify signing mode is correct
3. Ensure API credentials are correct
4. Check Cloudinary quota limits

---

**Ready to proceed?** Create the presets and let me know, then I'll update your code to use signed uploads properly! 🎉
