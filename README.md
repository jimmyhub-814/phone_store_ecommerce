 # 📱 DM Store — Phone Store App

A full-featured Vietnamese e-commerce mobile application for purchasing smartphones, built with Flutter & Firebase.

<p align="center">
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/9e73b2e6-b65a-4172-a917-956e4aa1b319" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/4afd1a99-a598-439d-be1e-2fce89c19706" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/7e5ed246-77a7-44b3-9c58-ff12c191afd5" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/4a3ef0e4-4805-4076-993d-acf293bd66fa" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/98c99b70-1461-4972-b6a7-1f10c09c4ab2" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/466e4b8c-3cca-47c8-8037-6718004b8de9" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/ad784db7-0eae-43dd-abda-a0a329a42065" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/78d25a92-ad04-4ba3-9f21-0667d7890c18" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/6c7b2b2f-dca1-4424-be01-3339a469a4d2" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/f2df6cd6-b2ad-4658-9fa5-0de2fc17e7f5" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/6bfc9256-68ab-487f-a589-c57460579b24" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/d39171f7-23ca-4d76-947a-084f3881a015" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/96a7f519-25ec-453a-9f0d-0c84a8f01e11" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/6bd0a224-8074-42f3-afcd-d9020e79009f" />
 <img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/aed433db-25e3-402e-a328-70a3cc07c777" />
</p>

---

## ✨ Features

### 🛍️ User App (DM Store)
- **Authentication** — Google Sign-In, Phone OTP (Firebase Auth)
- **Product Browsing** — Search, filter, view history, product detail pages
- **Smart Recommendations** — Collaborative filtering based on order history, cart, view & search behavior (weighted scoring)
- **Shopping Cart** — Real-time sync with Firestore, atomic batch deletes on purchase
- **Order Management** — Place, track, and cancel orders with live status updates
- **AI Chat Assistant** — Gemini-powered chatbot with streaming text responses and stop functionality
- **Push Notifications** — FCM integration across foreground, background, and killed states with deep linking to order detail

---

## ✨ Development

0. To run this Project first you need to [Setup Flutter](https://docs.flutter.dev/install)
1. Install packages
```bash
flutter pub get
```
2. Run the Project
```bash
flutter run
```

---

## 🏗️ Architecture & Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Backend | Firebase (Firestore, Auth, Cloud Functions, FCM, App Check) |
| State Management | BLoC / Cubit, Provider, GetX |
| AI | Google Gemini API |
