 # 📱 DM Store — Phone Store App

A full-featured Vietnamese e-commerce mobile application for purchasing smartphones, built with Flutter & Firebase.

Login Screen

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/9e73b2e6-b65a-4172-a917-956e4aa1b319" /><img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/4afd1a99-a598-439d-be1e-2fce89c19706" />


Home Screen  

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/7e5ed246-77a7-44b3-9c58-ff12c191afd5" />


Cart Screen

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/ad784db7-0eae-43dd-abda-a0a329a42065" />


Search Screen

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/4a3ef0e4-4805-4076-993d-acf293bd66fa" />


Chat With Seller Screen
<<<<<<< HEAD
=======

>>>>>>> ee0178e (fix user_provider cart_provide and message_cubit, update README)
<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/78d25a92-ad04-4ba3-9f21-0667d7890c18" />

Notification Screen

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/6bfc9256-68ab-487f-a589-c57460579b24" />


Phone Screen

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/98c99b70-1461-4972-b6a7-1f10c09c4ab2" /><img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/466e4b8c-3cca-47c8-8037-6718004b8de9" />


Account Screen

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/f2df6cd6-b2ad-4658-9fa5-0de2fc17e7f5" />


Order Status

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/d39171f7-23ca-4d76-947a-084f3881a015" />


Feedbacks

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/96a7f519-25ec-453a-9f0d-0c84a8f01e11" />


Hamburger Menu

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/6c7b2b2f-dca1-4424-be01-3339a469a4d2" />


Support Center

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/1b9fa3ec-2266-4fa6-9068-484267fe8753" />


Gemini Chat

<img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/e95b27d1-19c5-47d0-bd3f-6dccd5fc818e" /><img width="180" height="400" alt="Image" src="https://github.com/user-attachments/assets/384ef0f5-b585-4fe3-a03f-58478cf269fc" />


---

## ✨ Features

### 🛍️ User App (DM Store)
- **Authentication** — Email/Password, Google Sign-In, Phone OTP (Firebase Auth)
- **Product Browsing** — Search, filter, view history, product detail pages
- **Smart Recommendations** — Collaborative filtering based on order history, cart, view & search behavior (weighted scoring)
- **Shopping Cart** — Real-time sync with Firestore, atomic batch deletes on purchase
- **Order Management** — Place, track, and cancel orders with live status updates
- **AI Chat Assistant** — Gemini-powered chatbot with streaming text responses and stop functionality
- **Push Notifications** — FCM integration across foreground, background, and killed states with deep linking to order detail

---

## 🏗️ Architecture & Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Backend | Firebase (Firestore, Auth, Cloud Functions, FCM, App Check) |
| State Management | BLoC / Cubit, Provider, GetX |
| AI | Google Gemini API |