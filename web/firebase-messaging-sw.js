/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBHHaMQbuZ6rS9rJXuJCoC3kWsrAAJhlrA',
  authDomain: 'forrageira-963b0.firebaseapp.com',
  projectId: 'forrageira-963b0',
  storageBucket: 'forrageira-963b0.firebasestorage.app',
  messagingSenderId: '1055602958265',
  appId: '1:1055602958265:web:e0e1413107c1b5f13aa068',
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  const n = payload?.notification || {};
  const d = payload?.data || {};
  const title = n.title || d.title || 'Nova notificação';
  const body = n.body || d.body || '';
  const options = {
    body,
    data: d,
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
