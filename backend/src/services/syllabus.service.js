const fs = require('fs-extra');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const dataDir = path.join(__dirname, '..', '..', 'data', 'syllabi');
fs.ensureDirSync(dataDir);

async function saveSyllabus({ title = 'untitled', text, examDate }) {
  const id = uuidv4();
  const filePath = path.join(dataDir, `${id}.json`);
  const payload = { id, title, text, examDate, createdAt: new Date().toISOString() };
  await fs.writeJson(filePath, payload, { spaces: 2 });
  return payload;
}

async function getSyllabus(id) {
  const filePath = path.join(dataDir, `${id}.json`);
  if (!(await fs.pathExists(filePath))) return null;
  return fs.readJson(filePath);
}

async function listSyllabi() {
  const files = await fs.readdir(dataDir);
  const items = [];
  for (const f of files) {
    if (f.endsWith('.json')) {
      const p = path.join(dataDir, f);
      const data = await fs.readJson(p);
      items.push({ id: data.id, title: data.title, examDate: data.examDate, createdAt: data.createdAt });
    }
  }
  return items;
}

module.exports = { saveSyllabus, getSyllabus, listSyllabi };
