# Bait Guard — Firebase Web Integration Guide

**Document Purpose**: This guide provides complete, step-by-step instructions for connecting the **Bait Guard Web Application** to the shared Firebase project already integrated with the Flutter mobile application.  
**Target Audience**: Web Developer / Frontend Engineering Intern  
**Project Name**: Bait Guard  
**Firebase Project ID**: `bait-guard-6f470`  
**Firebase Project Number**: `609454017958`  
**Plan Tier**: Firebase Spark (Free Tier)  

---

## 1. Firebase Project Overview

The Bait Guard system uses a single unified Firebase project shared between:
1. The **Flutter Mobile Application** (Android & iOS).
2. The **Web Dashboard Application** (React / Vue / Next.js / Vanilla JS).

Both clients share the exact same:
- **Firebase Authentication** users (Email & Password).
- **Cloud Firestore** database schema and real-time listeners.
- **Firestore Security Rules** (`firestore.rules`).

> [!IMPORTANT]
> **Spark Plan Boundary**: The project runs on the Spark tier without Cloud Functions or backend Node Admin SDK. Identity, roles, and facility access permissions are stored directly in Cloud Firestore (`users/{uid}` collection) and secured via Firestore Security Rules.

---

## 2. Step 1: Register the Web App in Firebase Console

To obtain the web credentials (`apiKey` and `appId`), follow these quick steps:

1. Log into the [Firebase Console](https://console.firebase.google.com/).
2. Select the project: **Bait Guard** (`bait-guard-6f470`).
3. Click on the **Settings Gear (⚙️)** in the top left sidebar → **Project settings**.
4. In the **General** tab, scroll down to the **"Your apps"** section.
5. Click **Add app** and select the **Web (`</>`)** icon.
6. Enter an **App nickname** (e.g., `Bait Guard Web` or `baitguard-web-dashboard`).
7. *(Optional)* Check "Also set up Firebase Hosting" if you plan to deploy through Firebase Hosting.
8. Click **Register app**.
9. Firebase will display your `firebaseConfig` credentials object. Copy this object.

---

## 3. Step 2: Install and Initialize Firebase in the Web App

### 3.1 Install the Firebase SDK
In your web project root directory, run:

```bash
npm install firebase
# or
yarn add firebase
# or
pnpm add firebase
```

### 3.2 Create Firebase Configuration File
Create a new file in your source code, for example `src/firebase/config.js` (or `src/firebase/config.ts`):

```javascript
import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getAnalytics } from "firebase/analytics";

// Configured credentials for Bait Guard Web App
export const firebaseConfig = {
  apiKey: "AIzaSyCETKZpFXuyvY7dGEpyz5Q2dtqpDpE3kDg",
  authDomain: "bait-guard-6f470.firebaseapp.com",
  databaseURL: "https://bait-guard-6f470-default-rtdb.firebaseio.com",
  projectId: "bait-guard-6f470",
  storageBucket: "bait-guard-6f470.firebasestorage.app",
  messagingSenderId: "609454017958",
  appId: "1:609454017958:web:7e2c5b584bd0878ec8d367",
  measurementId: "G-5BRL68FG0Y"
};

// Initialize Firebase
export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const analytics = typeof window !== "undefined" ? getAnalytics(app) : null;
```

---

## 4. Step 3: Authentication & Session Management

### 4.1 Sign-In Method
The project uses **Email/Password** authentication.

```javascript
import { signInWithEmailAndPassword, signOut, onAuthStateChanged } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "./config";

// 1. Sign In
export async function loginUser(email, password) {
  const normalizedEmail = email.trim().toLowerCase();
  const userCredential = await signInWithEmailAndPassword(auth, normalizedEmail, password);
  const firebaseUser = userCredential.user;

  // 2. Fetch User Profile from Firestore (contains role & facility permissions)
  const profileDoc = await getDoc(doc(db, "users", firebaseUser.uid));
  
  if (!profileDoc.exists()) {
    await signOut(auth);
    throw new Error("No application profile found. Please contact an administrator.");
  }

  const profile = profileDoc.data();

  // 3. Check if account is active
  if (profile.status !== "active") {
    await signOut(auth);
    throw new Error("Your account has been disabled. Please contact an administrator.");
  }

  return { firebaseUser, profile };
}

// 2. Sign Out
export async function logoutUser() {
  await signOut(auth);
}
```

### 4.2 Auth State Observer & Session Restoration
On app load, monitor user state using `onAuthStateChanged`:

```javascript
onAuthStateChanged(auth, async (user) => {
  if (user) {
    // User is signed into Firebase Auth; load their Firestore profile
    const profileSnap = await getDoc(doc(db, "users", user.uid));
    if (profileSnap.exists() && profileSnap.data().status === "active") {
      const userProfile = profileSnap.data();
      console.log("Logged in user:", userProfile.displayName, "Role:", userProfile.role);
      // Route based on role: 'admin' vs 'technician' / 'viewer'
    } else {
      await signOut(auth);
    }
  } else {
    // User is logged out; redirect to login
  }
});
```

---

## 5. Step 4: Firestore Data Model & Schemas

### 5.1 Collection: `users`
**Path**: `users/{uid}` (where document ID **must equal** the Firebase Auth UID).

| Field Name | Type | Description |
|---|---|---|
| `uid` | string | **Must equal document ID and Firebase Auth UID** |
| `displayName` | string | Full name displayed across the app |
| `firstName` | string | User's first name |
| `lastName` | string | User's last name |
| `email` | string | Lowercase normalized email |
| `role` | string | `"admin"` \| `"technician"` \| `"viewer"` |
| `status` | string | `"active"` \| `"disabled"` |
| `facilityIds` | array of strings | Assigned site IDs (e.g. `["site_1", "site_2"]`) |
| `company` | string | Company/Organization name |
| `department` | string | Optional department name (can be `""`) |
| `phone` | string | Optional contact phone (can be `""`) |
| `jobTitle` | string | Optional job title (can be `""`) |
| `bio` | string | Optional bio / notes (can be `""`) |
| `createdAt` | Timestamp | Server timestamp when profile was created |
| `updatedAt` | Timestamp | Server timestamp when profile was last modified |

### 5.2 Collection: `accessRequests`
**Path**: `accessRequests/{autoId}`  
Used for the public "Request Access" form and admin review pipeline.

| Field Name | Type | Description |
|---|---|---|
| `fullName` | string | Applicant's full name |
| `email` | string | Original input email |
| `normalizedEmail` | string | Trimmed, lowercase email (`email.trim().toLowerCase()`) |
| `company` | string | Company / Organization |
| `phone` | string | Contact phone |
| `department` | string | Optional department |
| `message` | string | Optional reason / request message |
| `status` | string | `"pending"` \| `"approved"` \| `"rejected"` |
| `submittedAt` | Timestamp | Timestamp when request was submitted |
| `reviewedBy` | string | UID of reviewing Admin (added upon approval/rejection) |
| `reviewedAt` | Timestamp | Review timestamp |
| `assignedRole` | string | `"technician"` \| `"viewer"` (added upon approval) |
| `assignedFacilityIds` | array of strings | Assigned facility IDs (added upon approval) |
| `approvalSource` | string | `"request"` or `"admin"` |
| `rejectionReason` | string | Optional rejection reason (added upon rejection) |
| `activatedUid` | string | User UID who completed activation |
| `activatedAt` | Timestamp | Activation completion timestamp |

---

## 6. Step 5: Security Rules & Permissions Contract

The security rules are deployed at `firestore.rules`. Here is what the web app can and cannot do:

1. **Public / Unauthenticated Users**:
   - Can **only** create a new document in `accessRequests` with `status == 'pending'`.
   - Cannot read, list, update, or delete any requests or users.
2. **Authenticated Users**:
   - Can read their own `users/{uid}` document.
   - Can update only their personal profile fields (`firstName`, `lastName`, `displayName`, `jobTitle`, `department`, `phone`, `bio`, `updatedAt`).
   - Cannot modify their own `role`, `status`, or `facilityIds`.
3. **Admins (`role == 'admin' && status == 'active'`)**:
   - Can list and read all `users`.
   - Can update non-admin users' `role` (`technician` ↔ `viewer`), `status` (`active` ↔ `disabled`), and `facilityIds`.
   - Can list, view, approve, or reject `accessRequests`.
   - Cannot delete records or demote/edit other admins.

---

## 7. Step 6: Composite Indexes

If your web application queries pending requests or user invitations, ensure these composite indexes exist in Firebase Console under **Firestore Database → Indexes**:

1. **Pending Requests Query**:
   - Collection: `accessRequests`
   - Fields:
     - `status` (Ascending)
     - `submittedAt` (Descending)
2. **Account Activation Query**:
   - Collection: `accessRequests`
   - Fields:
     - `normalizedEmail` (Ascending)
     - `status` (Ascending)
     - `activatedUid` (Ascending)

---

## 8. Step 7: Facility Scoping & Seeded Sites

Both clients use facility scoping. The initial seeded facilities currently recognized are:

| Facility ID | Friendly Name |
|---|---|
| `site_1` | Warehouse A |
| `site_2` | Warehouse B |
| `site_3` | Distribution Center |
| `site_4` | Cold Storage |
| `site_5` | Manufacturing Plant |

Users only have access to telemetry/alerts belonging to their assigned `facilityIds`. If `facilityIds` is empty, no station data should be displayed.

---

## 9. Summary Integration Checklist for Web Intern

- [ ] Create Web App in Firebase Console (`bait-guard-6f470`).
- [ ] Copy `apiKey` and `appId` into `src/firebase/config.js`.
- [ ] Use `signInWithEmailAndPassword` and load profile from `users/{uid}`.
- [ ] Restrict features based on `profile.role` (`admin`, `technician`, `viewer`).
- [ ] Filter all operational views by `profile.facilityIds`.
- [ ] Submit access requests to `accessRequests` with `status: 'pending'` and `submittedAt: serverTimestamp()`.
