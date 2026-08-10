/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.monthlySummaryBatch = functions.pubsub
  .schedule("0 3 1 * *") // 毎月1日の朝3時に実行
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    const db = admin.firestore();

    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth(); // 0 = January
    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 1);

    const workersSnap = await db.collection("worker_master").get();

    for (const worker of workersSnap.docs) {
      const workerId = worker.id;

      const snap = await db.collection("demen_data")
        .where("workerId", "==", workerId)
        .where("createdAt", ">=", start)
        .where("createdAt", "<", end)
        .get();

      let days = 0;
      let overtime = 0;
      let expense = 0;

      let genbaDays = {};
      let genbaExpenses = {};

      snap.forEach(doc => {
        const data = doc.data();

        const dayCount = data.dayCount || 1;
        days += dayCount;

        overtime += data.overtime || 0;

        const genba = data.genbaName || "不明";
        genbaDays[genba] = (genbaDays[genba] || 0) + dayCount;

        const expenses = data.expenses || [];
        expenses.forEach(item => {
          const amount = item.amount || 0;
          expense += amount;

          if (!genbaExpenses[genba]) genbaExpenses[genba] = [];
          genbaExpenses[genba].push(item);
        });
      });

      const yyyymm = `${year}${String(month).padStart(2, "0")}`;

      await db.collection("summary_month")
        .doc(workerId)
        .collection("months")
        .doc(yyyymm)
        .set({
          days,
          overtime,
          expense,
          genbaDays,
          genbaExpenses,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    }

    return null;
  });
