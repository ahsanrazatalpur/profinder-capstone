// web/firebase-messaging-sw.js
// Required by firebase_messaging on web. Must live in /web (site root).
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCYa_FJ35PSIT-nMpJA8B-jObuGB15NJIE',
  appId: '1:299423637189:web:87895f7d9e9a1807931aac',
  messagingSenderId: '299423637189',
  projectId: 'profinder-f3f96',
  authDomain: 'profinder-f3f96.firebaseapp.com',
  storageBucket: 'profinder-f3f96.firebasestorage.app',
});

const messaging = firebase.messaging();

// Shows a notification when a push arrives while the tab is in background.
messaging.onBackgroundMessage((payload) => {
  const n = payload.notification || {};
  self.registration.showNotification(n.title || 'ProFinder', {
    body: n.body || '',
    icon: '/icons/Icon-192.png',
  });
});
