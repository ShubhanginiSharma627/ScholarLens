const firestore = require('@google-cloud/firestore');
const db = new firestore.Firestore();

exports.getStats = async (req, res) => {
  try {
    const userId = req.user?.userId || req.query.userId || 'anonymous';
    
    
    const interactionsRef = db.collection('interactions').where('userId', '==', userId);
    const interactionsSnapshot = await interactionsRef.get();
    
   
    const flashcardsRef = db.collection('flashcards').where('userId', '==', userId);
    const flashcardsSnapshot = await flashcardsRef.get();
    

    const studySessionsRef = db.collection('study_sessions').where('userId', '==', userId);
    const studySessionsSnapshot = await studySessionsRef.get();
    
    const interactions = [];
    interactionsSnapshot.forEach(doc => {
      interactions.push(doc.data());
    });
    
    const flashcards = [];
    flashcardsSnapshot.forEach(doc => {
      flashcards.push(doc.data());
    });
    
    const studySessions = [];
    studySessionsSnapshot.forEach(doc => {
      studySessions.push(doc.data());
    });
    
  
    const stats = {
      totalInteractions: interactions.length,
      topics: {},
      quizScores: [],
      streak: calculateStreak(interactions),
      totalFlashcards: flashcards.length,
      masteredFlashcards: flashcards.filter(card => 
        card.studyStats && card.studyStats.timesStudied >= 3
      ).length,
      averageAccuracy: 0,
      studyTimeThisWeek: 0,
      subjectBreakdown: {},
    };
    
   
    interactions.forEach(interaction => {
      if (interaction.type === 'quiz' && interaction.score !== undefined) {
        stats.quizScores.push(interaction.score);
      }
      if (interaction.topic) {
        stats.topics[interaction.topic] = (stats.topics[interaction.topic] || 0) + 1;
      }
    });
    
   
    const now = new Date();
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    let correctSessions = 0;
    let totalSessions = 0;
    let weeklyStudyTime = 0;
    
    studySessions.forEach(session => {
      const sessionDate = new Date(session.timestamp);
      if (sessionDate >= weekAgo) {
        weeklyStudyTime += session.timeSpent || 0;
      }
      
      if (session.correct !== undefined) {
        totalSessions++;
        if (session.correct) {
          correctSessions++;
        }
      }
    });
    
    stats.averageAccuracy = totalSessions > 0 ? (correctSessions / totalSessions) * 100 : 0;
    stats.studyTimeThisWeek = weeklyStudyTime / (1000 * 60 * 60);
    
   
    flashcards.forEach(card => {
      if (card.subject) {
        stats.subjectBreakdown[card.subject] = (stats.subjectBreakdown[card.subject] || 0) + 1;
      }
    });
    
   
    const weakestTopics = Object.entries(stats.topics)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([topic, count]) => ({ topic, count }));
    
    stats.weakestTopics = weakestTopics;
    
    res.status(200).json(stats);
  } catch (error) {
    console.error('Stats error:', error);
    res.status(500).json({ error: 'Error retrieving stats' });
  }
};

function calculateStreak(interactions) {
  if (interactions.length === 0) return 0;
  

  const sortedInteractions = interactions
    .filter(interaction => interaction.timestamp)
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
  
  if (sortedInteractions.length === 0) return 0;
  
  let streak = 0;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
 
  const mostRecentDate = new Date(sortedInteractions[0].timestamp);
  mostRecentDate.setHours(0, 0, 0, 0);
  
  const daysDiff = Math.floor((today - mostRecentDate) / (1000 * 60 * 60 * 24));
  
  if (daysDiff > 1) {
    return 0; 
  }
  
  
  let currentDate = new Date(mostRecentDate);
  const interactionDates = new Set();
  
  sortedInteractions.forEach(interaction => {
    const date = new Date(interaction.timestamp);
    date.setHours(0, 0, 0, 0);
    interactionDates.add(date.getTime());
  });
  
  while (interactionDates.has(currentDate.getTime())) {
    streak++;
    currentDate.setDate(currentDate.getDate() - 1);
  }
  
  return streak;
}