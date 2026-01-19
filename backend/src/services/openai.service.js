const OpenAI = require('openai');
const fs = require('fs');
const path = require('path');

const endpoint = process.env.AZURE_OPENAI_ENDPOINT;
const apiKey = process.env.AZURE_OPENAI_KEY;
const deployment = process.env.AZURE_OPENAI_DEPLOYMENT;

if (!endpoint || !apiKey || !deployment) {
  console.warn('AZURE_OPENAI_* env vars are not fully configured. Please set AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_KEY and AZURE_OPENAI_DEPLOYMENT');
}

const client = new OpenAI({
  baseURL: endpoint,
  apiKey: apiKey
});

// Function to read prompt files
function readPromptFile(filename) {
  try {
    const promptPath = path.join(__dirname, '../../../prompts', filename);
    const content = fs.readFileSync(promptPath, 'utf8');
    return content;
  } catch (error) {
    console.error(`Error reading prompt file ${filename}:`, error.message);
    return null;
  }
}

async function callChatCompletion(messages, options = {}) {
  try {
    const completion = await client.chat.completions.create({
      messages,
      model: deployment,
    });

    return completion;
  } catch (error) {
    console.error('OpenAI API Error:', error);
    throw error;
  }
}

function safeParseJson(text) {
  try {
    return JSON.parse(text);
  } catch (e) {
    // try to extract JSON substring
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start !== -1 && end !== -1) {
      try {
        return JSON.parse(text.slice(start, end + 1));
      } catch (e2) {
        return null;
      }
    }
    return null;
  }
}

async function generatePlan({ topic, audience, length, constraints }) {
  const systemPrompt = readPromptFile('revisionplan.prompts.txt');
  
  if (!systemPrompt) {
    throw new Error('Could not load revision plan prompt file');
  }

  const system = {
    role: 'system',
    content: systemPrompt,
  };

  const user = {
    role: 'user',
    content: `Create an adaptive revision plan for the topic: "${topic}". Audience: ${audience}. Length: ${length}. Constraints: ${constraints}. Return JSON with keys: steps (array of {title, description, duration_days, deliverables}), timeline (summary), resources (list), and study_tips. Prioritize spaced repetition and active recall. Keep responses structured and actionable.`,
  };

  const raw = await callChatCompletion([system, user], { maxTokens: 1200, temperature: 0.2 });

  const text = raw?.choices?.[0]?.message?.content || '';
  const parsed = safeParseJson(text);
  if (parsed) return parsed;
  return { text }; // fallback
}

async function explainTopic({ topic, audience, type }) {
  const systemPrompt = readPromptFile('explanation.prompts.txt');
  
  if (!systemPrompt) {
    throw new Error('Could not load explanation prompt file');
  }

  const system = {
    role: 'system',
    content: systemPrompt,
  };
  
  const user = {
    role: 'user',
    content: `Explain the topic "${topic}" for a ${audience} audience. Type: ${type}. Return JSON with keys: summary (string), key_concepts (array), examples (array), techniques (array of study techniques), and quiz (array of Q/A objects). Adapt content based on the type parameter.`,
  };

  const raw = await callChatCompletion([system, user], { maxTokens: 1000, temperature: 0.6 });
  const text = raw?.choices?.[0]?.message?.content || '';
  const parsed = safeParseJson(text);
  if (parsed) return parsed;
  return { text };
}

async function explainTopicWithContext({ topic, audience, contextText, variation = 'different' }) {
  const basePrompt = readPromptFile('explanation.prompts.txt');
  
  if (!basePrompt) {
    throw new Error('Could not load explanation prompt file');
  }

  const system = {
    role: 'system',
    content: `${basePrompt}

ADDITIONAL CONTEXT:
You have been provided with syllabus context. Use this context when relevant to enhance your explanation, but don't force it if not applicable.

VARIATION INSTRUCTION:
${variation} - Vary your explanation style and approach.`,
  };
  
  const user = {
    role: 'user',
    content: `Explain topic "${topic}" for ${audience}. Use the following syllabus context when helpful:\n\n${(contextText || '').slice(0, 3000)}\n\nReturn JSON with summary, key_concepts, examples, techniques, and quiz. Vary approach: ${variation}.`,
  };

  const raw = await callChatCompletion([system, user], { maxTokens: 900, temperature: 0.7 });
  const text = raw?.choices?.[0]?.message?.content || '';
  const parsed = safeParseJson(text);
  if (parsed) return parsed;
  return { text };
}

async function getTodaysFocus({ syllabusText, examDate, date }) {
  const system = { role: 'system', content: 'You are a study coach that creates prioritized daily focus topics based on syllabus and time until exam.' };
  const user = {
    role: 'user',
    content: `Given the syllabus below and the exam date (${examDate}), and today is ${date || new Date().toISOString().slice(0,10)}, recommend a Today's Focus JSON with keys: date, prioritized_topics (array of {topic, reason, estimated_minutes}), suggested_activities (array), and quick_checklist (array). Syllabus:\n\n${(syllabusText || '').slice(0,3000)}`,
  };

  const raw = await callChatCompletion([system, user], { maxTokens: 800, temperature: 0.2 });
  const text = raw?.choices?.[0]?.message?.content || '';
  const parsed = safeParseJson(text);
  if (parsed) return parsed;
  return { text };
}

module.exports = {
  generatePlan,
  explainTopic,
  explainTopicWithContext,
  getTodaysFocus,
  // exported for testing
  safeParseJson,
};
