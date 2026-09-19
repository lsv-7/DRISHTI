import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyByVgLXcUYV6As5ktzOsk7Y-CTqNhwByF4",
  authDomain: "projectk-2898.firebaseapp.com",
  projectId: "projectk-2898",
  storageBucket: "projectk-2898.firebasestorage.app",
  messagingSenderId: "872045293825",
  appId: "1:872045293825:web:3a2268662aa433651d2b00",
  measurementId: "G-R2RB7YT2BY"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export default app;
