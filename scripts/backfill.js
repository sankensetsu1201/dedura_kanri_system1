// scripts/backfill.js
const admin = require('firebase-admin');

admin.initializeApp(); // GOOGLE_APPLICATION_CREDENTIALS を使う

const db = admin.firestore();

async function main() {
  console.log('Starting BACKFILL: users -> worker_master');

  // 全ユーザーを取得（本番）
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

    // Firestore 負荷軽減（本番でも必須）
    await new Promise((r) => setTimeout(r, 200));
  }

  console.log(`BACKFILL FINISHED. created=${created} skipped=${skipped} noWorkerId=${noWorkerId}`);
  process.exit(0);
}

main().catch((e) => {
  console.error('Fatal error:', e);
  process.exit(1);
});
