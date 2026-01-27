const { generateText, selectOptimalModel } = require('./vertexai.service');
const { socraticTutorPrompt } = require('../utils/promptUtils');
const firestore = require('@google-cloud/firestore');

const db = new firestore.Firestore();

// Generate flashcards using Gemma 7B
async function generateFlashcards(topic, count = 10, userId) {
  try {
    const model = selectOptimalModel('flashcard_generation', 'medium');
    const prompt = socraticTutorPrompt(
      `Generate ${count} flashcards for "${topic}". Format each as:
      Q: [question]
      A: [answer]
      Difficulty: [easy/medium/hard]`,
      'Flashcard generation'
    );

    const response = await generateText(prompt, model);
    const flashcards = parseFlashcards(response);

    // Save to Firestore
    const batch = db.batch();
    flashcards.forEach(card => {
      const ref = db.collection('users').doc(userId).collection('flashcards').doc();
      batch.set(ref, {
        ...card,
        createdAt: new Date(),
        nextReview: new Date(),
        repetitions: 0,
        interval: 1,
        easeFactor: 2.5
      });
    });

    await batch.commit();
    return flashcards;
  } catch (error) {
    throw error;
  }
}

// Create quiz questions using Gemma 7B/27B
async function createQuizQuestions(topic, count = 5, difficulty = 'medium', userId) {
  try {
    const model = selectOptimalModel('quiz_creation', difficulty);
    const prompt = socraticTutorPrompt(
      `Create ${count} multiple-choice quiz questions about "${topic}" with ${difficulty} difficulty.
      Format each as:
      Q: [question]
      A) [option1]
      B) [option2]
      C) [option3]
      D) [option4]
      Answer: [correct letter]
      Explanation: [why this is correct]`,
      'Quiz creation'
    );

    const response = await generateText(prompt, model);
    const questions = parseQuizQuestions(response);

    // Save to Firestore
    const quizRef = db.collection('users').doc(userId).collection('quizzes').doc();
    await quizRef.set({
      topic,
      difficulty,
      questions,
      createdAt: new Date(),
      completed: false,
      score: null
    });

    return { quizId: quizRef.id, questions };
  } catch (error) {
    throw error;
  }
}

// Fast concept explanation using Gemma 2B
async function explainConcept(concept, userId) {
  try {
    const model = selectOptimalModel('quick_explanation', 'simple');
    const prompt = socraticTutorPrompt(
      `Explain the concept of "${concept}" in 2-3 sentences for a student.`,
      'Concept explanation'
    );

    const explanation = await generateText(prompt, model);

    // Log interaction
    await db.collection('interactions').add({
      type: 'concept_explanation',
      userId,
      concept,
      timestamp: new Date()
    });

    return explanation;
  } catch (error) {
    throw error;
  }
}

// Generate personalized study plan using Gemma 27B
async function generateStudyPlan(subject, examDate, currentKnowledge, userId) {
  try {
    const model = selectOptimalModel('quiz_creation', 'complex');
    const daysUntilExam = Math.ceil((new Date(examDate) - new Date()) / (1000 * 60 * 60 * 24));

    const prompt = socraticTutorPrompt(
      `Create a detailed ${daysUntilExam}-day study plan for "${subject}".
      Current knowledge level: ${currentKnowledge}/10
      Exam date: ${examDate}
      
      Include:
      - Daily topics to study
      - Time allocation for each topic
      - Recommended resources
      - Mock test dates
      - Review schedule`,
      'Study plan generation'
    );

    const plan = await generateText(prompt, model);

    // Save to Firestore
    const planRef = db.collection('users').doc(userId).collection('studyPlans').doc();
    await planRef.set({
      subject,
      examDate,
      content: plan,
      createdAt: new Date(),
      daysSinceCreated: 0
    });

    return { planId: planRef.id, plan };
  } catch (error) {
    throw error;
  }
}

// Helper function to parse flashcards from response
function parseFlashcards(response) {
  const flashcards = [];
  const blocks = response.split('\n\n');

  blocks.forEach(block => {
    const qMatch = block.match(/Q:\s*(.+)/);
    const aMatch = block.match(/A:\s*(.+)/);
    const diffMatch = block.match(/Difficulty:\s*(.+)/);

    if (qMatch && aMatch) {
      flashcards.push({
        question: qMatch[1].trim(),
        answer: aMatch[1].trim(),
        difficulty: diffMatch ? diffMatch[1].trim() : 'medium'
      });
    }
  });

  return flashcards;
}

// Helper function to parse quiz questions from response
function parseQuizQuestions(response) {
  const questions = [];
  const blocks = response.split('\n\n');

  blocks.forEach(block => {
    const qMatch = block.match(/Q:\s*(.+)/);
    const optionsMatch = block.match(/A\)\s*(.+)\nB\)\s*(.+)\nC\)\s*(.+)\nD\)\s*(.+)/);
    const answerMatch = block.match(/Answer:\s*(.)/);
    const explanationMatch = block.match(/Explanation:\s*(.+)/);

    if (qMatch && optionsMatch && answerMatch) {
      questions.push({
        question: qMatch[1].trim(),
        options: [optionsMatch[1].trim(), optionsMatch[2].trim(), optionsMatch[3].trim(), optionsMatch[4].trim()],
        correctAnswer: answerMatch[1].trim(),
        explanation: explanationMatch ? explanationMatch[1].trim() : ''
      });
    }
  });

  return questions;
}

module.exports = {
  generateFlashcards,
  createQuizQuestions,
  explainConcept,
  generateStudyPlan
};