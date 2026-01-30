const fs = require('fs');
const path = require('path');

exports.socraticTutorPrompt = (question, context = '') => {
  return `You are a Socratic Tutor. Your role is to guide students to discover answers through questioning, not by providing direct answers. Always ask guiding questions that encourage critical thinking.
Question: ${question}
Context: ${context}
Response guidelines:
- Never give the direct answer.
- Ask questions that probe understanding.
- Encourage the student to think step-by-step.
- Use phrases like "What do you think happens if...", "Can you explain why...", "Let's consider the definition of...".
- If they are close, say "That's close! But consider..." and guide them.
Provide a guiding response:`;
};

exports.syllabusAnalysisPrompt = (userRequest = '') => {
  try {
    const promptPath = path.join(__dirname, '../../prompts/syllabus_analysis.prompts.txt');
    const basePrompt = fs.readFileSync(promptPath, 'utf8');
    
    const userContext = userRequest ? `\n\nUser's specific request: ${userRequest}` : '';
    
    return basePrompt + userContext;
  } catch (error) {
    console.error('Error loading syllabus analysis prompt:', error);
    return `Analyze this document and provide structured information about its content.
    
Please extract:
1. SUBJECT: What is the main subject or topic?
2. CHAPTERS/SECTIONS: List the main chapters, sections, or units
3. KEY TOPICS: What are the main topics, concepts, or themes covered?
4. PAGES: How many pages does this document have?

${userRequest ? `User's specific request: ${userRequest}` : ''}

Return the information in a clear, structured format.`;
  }
};