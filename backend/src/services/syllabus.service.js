const firestore = require('@google-cloud/firestore');
const { v4: uuidv4 } = require('uuid');
const db = new firestore.Firestore();
async function saveSyllabus({ title = 'untitled', text, examDate }) {
  const id = uuidv4();
  const payload = { id, title, text, examDate, createdAt: new Date().toISOString() };
  await db.collection('syllabi').doc(id).set(payload);
  return payload;
}
async function getSyllabus(id) {
  const doc = await db.collection('syllabi').doc(id).get();
  if (!doc.exists) return null;
  return doc.data();
}
async function listSyllabi() {
  const snapshot = await db.collection('syllabi').get();
  const items = [];
  snapshot.forEach(doc => {
    const data = doc.data();
    items.push({ id: data.id, title: data.title, examDate: data.examDate, createdAt: data.createdAt });
  });
  return items;
}
module.exports = { saveSyllabus, getSyllabus, listSyllabi };
