const firestore = require('@google-cloud/firestore');
const db = new firestore.Firestore();
exports.getStats = async (req, res) => {
  try {
    const userId = req.query.userId || 'anonymous';
    const interactionsRef = db.collection('interactions').where('userId', '==', userId);
    const snapshot = await interactionsRef.get();
    const interactions = [];
    snapshot.forEach(doc => {
      interactions.push(doc.data());
    });
    const stats = {
      totalInteractions: interactions.length,
      topics: {},
      quizScores: [],
      streak: 0, // Placeholder, implement streak logic
    };
    interactions.forEach(interaction => {
      if (interaction.type === 'quiz') {
        stats.quizScores.push(interaction.score);
      }
      if (interaction.topic) {
        stats.topics[interaction.topic] = (stats.topics[interaction.topic] || 0) + 1;
      }
    });
    const weakestTopics = Object.entries(stats.topics)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([topic, count]) => ({ topic, count }));
    stats.weakestTopics = weakestTopics;
    res.status(200).json(stats);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error retrieving stats' });
  }
};