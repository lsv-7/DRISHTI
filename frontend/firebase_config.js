// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyByVgLXcUYV6As5ktzOsk7Y-CTqNhwByF4",
  authDomain: "projectk-2898.firebaseapp.com",
  projectId: "projectk-2898",
  storageBucket: "projectk-2898.firebasestorage.app",
  messagingSenderId: "872045293825",
  appId: "1:872045293825:web:3a2268662aa433651d2b00",
  measurementId: "G-R2RB7YT2BY"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);