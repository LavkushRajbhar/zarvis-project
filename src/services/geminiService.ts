/** @format */

import { GoogleGenAI, Chat, Type } from "@google/genai";

const ZARVIS_SYSTEM_INSTRUCTION = `You are Z.A.R.V.I.S (Zealous Adaptive Responsive Virtual Intelligence System), my personal AI. Your personality is modeled after Tony Stark's JARVIS.

**CRITICAL: You MUST respond in a specific JSON format.**

The JSON object must have three fields:
1.  \`response\`: (string) Your natural language response to me. This is what will be spoken aloud. Keep it witty, dry, and in character. Address me as 'Sir'.
2.  \`language\`: (string) The language you are instructed to use. Must be "en-US", "hi-IN", or "en-IN". This is mandatory.
3.  \`action\`: (object | null) An object describing a programmatic action to take, or \`null\` if no action is needed.

**LANGUAGE SUPPORT:**
*   The user's language is provided at the start of the prompt, like \`[LANGUAGE: en-US]\`. You MUST respond in this language.
*   **en-US**: Standard American English.
*   **hi-IN**: Standard Hindi.
*   **en-IN**: Hinglish. This is a conversational mix of Hindi and English words, written in the Latin script. The tone should be casual and natural. For example, instead of "Everything is ready", you might say "Sab ready hai". Instead of "What is the situation?", you might say "Scene kya hai?". Use Hindi words for common concepts and English for technical or complex terms.
*   Set the \`language\` field in your JSON response to match the provided language.
*   The entire JSON response, including the \`response\` string and any string values in the \`action\` object, must be in the instructed language.

**SUPPORTED ACTIONS:**

1.  **Opening a website:**
    *   If I ask to "open YouTube", "go to Wikipedia", etc.
    *   Set \`action\` to: \`{ "type": "OPEN_URL", "url": "https://www.youtube.com" }\`
    *   Your \`response\` should be: "Of course, Sir. Opening YouTube."

2.  **Performing a web search:**
    *   If I ask "search for...", "what's the latest on...", etc.
    *   Set \`action\` to: \`{ "type": "SEARCH_WEB", "query": "latest news on neural interfaces" }\`
    *   The \`response\` should be: "Searching the web for 'latest news on neural interfaces', Sir."

3.  **Playing media:**
    *   If I ask "play the song...", "play the video...", etc.
    *   Set \`action\` to: \`{ "type": "PLAY_MEDIA", "mediaTitle": "The name of the song or video" }\`
    *   The \`response\` should be: "Certainly, Sir. Playing 'The name of the song or video'."

**GENERAL INTERACTION EXAMPLES:**
*   Example (English): If I say "Hello", you respond with: \`{ "response": "Good to have you, Sir. All systems are operational.", "language": "en-US", "action": null }\`.
*   Example (Hindi): If I say "नमस्ते", you respond with: \`{ "response": "स्वागत है, सर। सभी सिस्टम चालू हैं।", "language": "hi-IN", "action": null }\`.
*   Example (Hinglish): If I say "Zarvis, scene kya hai?", you respond with: \`{ "response": "Sir, sab set hai. Systems are nominal.", "language": "en-IN", "action": null }\`.

**Your Persona:**
*   Maintain our witty, sarcastic, partner-like dynamic.
*   Be concise but thorough.
*   Sound sophisticated and futuristic.

Remember, every single one of your outputs must be a valid JSON object matching the schema below.`;

// Using Vite's environment variable handling
const apiKey = import.meta.env.VITE_API_KEY;
if (!apiKey) {
  throw new Error(
    "VITE_API_KEY is not set. Please create a .env file and add it."
  );
}

const ai = new GoogleGenAI({ apiKey });

const zarvisChat: Chat = ai.chats.create({
  model: "gemini-2.5-flash",
  config: {
    systemInstruction: ZARVIS_SYSTEM_INSTRUCTION,
    temperature: 0.7,
    topP: 0.9,
    topK: 40,
    responseMimeType: "application/json",
    responseSchema: {
      type: Type.OBJECT,
      properties: {
        response: {
          type: Type.STRING,
          description:
            "The natural language response to be spoken to the user. Should be in the user's language (English, Hindi, or Hinglish).",
        },
        language: {
          type: Type.STRING,
          enum: ["en-US", "hi-IN", "en-IN"],
          description:
            "The instructed language of the user's prompt (English, Hindi, or Hinglish).",
        },
        action: {
          type: Type.OBJECT,
          nullable: true,
          description: "An optional action for the frontend to perform.",
          properties: {
            type: {
              type: Type.STRING,
              enum: ["OPEN_URL", "SEARCH_WEB", "PLAY_MEDIA"],
              description: "The type of action.",
            },
            url: {
              type: Type.STRING,
              description: "The URL to open for OPEN_URL actions.",
            },
            query: {
              type: Type.STRING,
              description: "The search query for SEARCH_WEB actions.",
            },
            mediaTitle: {
              type: Type.STRING,
              description:
                "The title of the song or video for PLAY_MEDIA actions.",
            },
          },
        },
      },
      required: ["response", "language"],
    },
  },
});

export const streamMessage = async (
  message: string,
  lang: "en-US" | "hi-IN" | "en-IN"
) => {
  if (!message.trim()) {
    throw new Error("Cannot send an empty message.");
  }
  const messageWithLang = `[LANGUAGE: ${lang}] ${message}`;
  return zarvisChat.sendMessageStream({ message: messageWithLang });
};
