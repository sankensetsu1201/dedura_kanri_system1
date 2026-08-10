// scripts/migrate-admins.js
const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON path');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();

async function migrateAdmins() {
  const snapshot = await db.collection('users').where('role', '==', 'admin').get();
  console.log('found', snapshot.size, 'admin users');
  const batchSize = 500;
  let batch = db.batch();
  let count = 0;
  for (const doc of snapshot.docs) {
    batch.set(doc.ref, { isAdmin: true }, { merge: true });
    count++;
    if (count % batchSize === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  if (count % batchSize !== 0) await batch.commit();
  console.log('isAdmin set for', count, 'users');
}

migrateAdmins().catch(err => {
  console.error(err);
  process.exit(1);
});
