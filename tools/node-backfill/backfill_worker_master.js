const admin = require('firebase-admin');
const path = require('path');

async function main() {
  const keyPath = path.join(__dirname, '..', '..', 'service-account.json'); // プロジェクトルートに置く想定
  admin.initializeApp({
    credential: admin.credential.cert(require(keyPath)),
  });

  const db = admin.firestore();
  console.log('Starting backfill: users -> worker_master');

  const usersSnap = await db.collection('users').get();
  console.log(`Found ${usersSnap.size} users`);

  let created = 0;
  let skipped = 0;
  let noWorkerId = 0;

  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const workerId = (data.workerId || '').toString().trim();
    const displayName = (data.displayName || data.name || '').toString();
    const email = (data.email || '').toString();

    if (!workerId) {
      console.log(`Skipping user ${doc.id}: no workerId`);
      noWorkerId++;
      continue;
    }

    const wmRef = db.collection('worker_master').doc(workerId);
    const wmDoc = await wmRef.get();
    if (wmDoc.exists) {
      console.log(`worker_master exists for ${workerId}, skipping`);
      skipped++;
      continue;
    }

    try {
      await wmRef.set({
        workerId: workerId,
        displayName: displayName,
        email: email,
        createdFromUser: doc.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Created worker_master for ${workerId}`);
      created++;
    } catch (e) {
      console.error(`Failed to create worker_master for ${workerId}:`, e);
    }

    await new Promise((r) => setTimeout(r, 200));
  }

  console.log(`Backfill finished. created=${created} skipped=${skipped} noWorkerId=${noWorkerId}`);
  process.exit(0);
}

main().catch((e) => {
  console.error('Fatal error:', e);
  process.exit(1);
});
