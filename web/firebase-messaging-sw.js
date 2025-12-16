importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyAVGuI_f9EFavvm3t8fHe_TLW6Riy_UmBw",
  authDomain: "klicktake-29b82.firebaseapp.com",
  databaseURL: "https://klicktake-29b82-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "klicktake-29b82",
  storageBucket: "klicktake-29b82.firebasestorage.app",
  messagingSenderId: "457186597740",
  appId: "1:457186597740:web:f33a8e82867038d198f149",
  measurementId: "G-DRC7RQE3HY"
});

const messaging = firebase.messaging();

messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            const title = payload.notification.title;
            const options = {
                body: payload.notification.score
              };
            return registration.showNotification(title, options);
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});