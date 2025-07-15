# Create necessary directories
mkdir -p src/components
mkdir -p src/services

# Create index.tsx
cat <<'EOF' > src/index.tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App';

const rootElement = document.getElementById('root');
if (!rootElement) {
  throw new Error("Could not find root element to mount to");
}

const root = createRoot(rootElement);
root.render(
  <StrictMode>
    <App />
  </StrictMode>
);
EOF

# Create metadata.json
cat <<'EOF' > metadata.json
{
  "requestFramePermissions": [
    "microphone"
  ]
}
EOF

# Create index.html
cat <<'EOF' > index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Z.A.R.V.I.S.</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700&family=Rajdhani:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
      body {
        font-family: 'Rajdhani', sans-serif;
        background-color: #020617; /* slate-950 */
      }
      .font-orbitron {
        font-family: 'Orbitron', sans-serif;
      }
      .glow-cyan {
        text-shadow: 0 0 5px rgba(34, 211, 238, 0.4), 0 0 10px rgba(34, 211, 238, 0.4);
      }
      .glow-border-cyan {
        box-shadow: 0 0 8px rgba(34, 211, 238, 0.5), inset 0 0 8px rgba(34, 211, 238, 0.3);
      }
      /* Custom scrollbar for a futuristic look */
      ::-webkit-scrollbar {
        width: 8px;
      }
      ::-webkit-scrollbar-track {
        background: #0f172a; /* slate-900 */
      }
      ::-webkit-scrollbar-thumb {
        background: #06b6d4; /* cyan-500 */
        border-radius: 4px;
      }
      ::-webkit-scrollbar-thumb:hover {
        background: #22d3ee; /* cyan-400 */
      }
    </style>
  <script type="importmap">
{
  "imports": {
    "react": "https://esm.sh/react@^19.1.0",
    "react-dom/": "https://esm.sh/react-dom@^19.1.0/",
    "react/": "https://esm.sh/react@^19.1.0/",
    "@google/genai": "https://esm.sh/@google/genai@^1.9.0"
  }
}
</script>
</head>
  <body class="bg-slate-950 text-slate-200">
    <div id="root"></div>
    <script type="module" src="/src/index.tsx"></script>
  </body>
</html>
EOF

# Create types.ts
cat <<'EOF' > src/types.ts
export interface Message {
  id: string;
  text: string;
  sender: 'user' | 'zarvis';
}
EOF

# Create services/geminiService.ts
cat <<'EOF' > src/services/geminiService.ts
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


const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });

const zarvisChat: Chat = ai.chats.create({
  model: 'gemini-2.5-flash',
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
            description: "The natural language response to be spoken to the user. Should be in the user's language (English, Hindi, or Hinglish)."
          },
          language: {
            type: Type.STRING,
            enum: ["en-US", "hi-IN", "en-IN"],
            description: "The instructed language of the user's prompt (English, Hindi, or Hinglish)."
          },
          action: {
            type: Type.OBJECT,
            nullable: true,
            description: "An optional action for the frontend to perform.",
            properties: {
              type: {
                type: Type.STRING,
                enum: ["OPEN_URL", "SEARCH_WEB", "PLAY_MEDIA"],
                description: "The type of action."
              },
              url: {
                type: Type.STRING,
                description: "The URL to open for OPEN_URL actions."
              },
              query: {
                type: Type.STRING,
                description: "The search query for SEARCH_WEB actions."
              },
              mediaTitle: {
                type: Type.STRING,
                description: "The title of the song or video for PLAY_MEDIA actions."
              }
            }
          }
        },
        required: ["response", "language"]
      }
  },
});

export const streamMessage = async (message: string, lang: 'en-US' | 'hi-IN' | 'en-IN') => {
    if (!message.trim()) {
        throw new Error("Cannot send an empty message.");
    }
    const messageWithLang = `[LANGUAGE: ${lang}] ${message}`;
    return zarvisChat.sendMessageStream({ message: messageWithLang });
};
EOF

# Create App.tsx
cat <<'EOF' > src/App.tsx
import React, { useState, useCallback, useEffect, useRef } from 'react';
import type { Message } from './types';
import { streamMessage } from './services/geminiService';
import Header from './components/Header';
import ChatWindow from './components/ChatWindow';
import UserInput from './components/UserInput';

// Type definitions for the Web Speech API are retained for clarity,
// as they are not included in standard TypeScript DOM library files.
interface SpeechRecognitionEvent extends Event {
    readonly resultIndex: number;
    readonly results: SpeechRecognitionResultList;
}
interface SpeechRecognitionResultList {
    readonly length: number;
    item(index: number): SpeechRecognitionResult;
    [index: number]: SpeechRecognitionResult;
}
interface SpeechRecognitionResult {
    readonly isFinal: boolean;
    readonly length: number;
    item(index: number): SpeechRecognitionAlternative;
    [index: number]: SpeechRecognitionAlternative;
}
interface SpeechRecognitionAlternative {
    readonly transcript: string;
}
interface SpeechRecognitionErrorEvent extends Event {
    readonly error: string;
}
interface SpeechRecognition extends EventTarget {
    continuous: boolean;
    interimResults: boolean;
    lang: string;
    onresult: (event: SpeechRecognitionEvent) => void;
    onend: () => void;
    onerror: (event: SpeechRecognitionErrorEvent) => void;
    start(): void;
    stop(): void;
    abort(): void;
}
interface SpeechRecognitionStatic { new(): SpeechRecognition; }
// Redefining SpeechSynthesisErrorEvent for better type safety
interface SpeechSynthesisErrorEvent extends Event {
    readonly error: string;
    readonly charIndex: number;
    readonly elapsedTime: number;
    readonly name: string;
}

declare global {
    interface Window {
        SpeechRecognition: SpeechRecognitionStatic;
        webkitSpeechRecognition: SpeechRecognitionStatic;
    }
}

interface Action {
    type: 'OPEN_URL' | 'SEARCH_WEB' | 'PLAY_MEDIA';
    url?: string;
    query?: string;
    mediaTitle?: string;
}

type Language = 'en-US' | 'hi-IN' | 'en-IN';

export const App = () => {
    const [messages, setMessages] = useState<Message[]>([]);
    const [isLoading, setIsLoading] = useState<boolean>(false);
    const [error, setError] = useState<string | null>(null);
    const [isTtsEnabled, setIsTtsEnabled] = useState<boolean>(true);
    const [textInput, setTextInput] = useState('');
    const [currentLanguage, setCurrentLanguage] = useState<Language>('en-US');
    
    // State machine for conversation flow
    const [isSpeechSupported, setIsSpeechSupported] = useState(false);
    const [isConversationModeActive, setIsConversationModeActive] = useState(false);
    const [isListening, setIsListening] = useState(false);
    const [isZarvisSpeaking, setIsZarvisSpeaking] = useState(false);
    
    const recognitionRef = useRef<SpeechRecognition | null>(null);
    const audioPrimerRef = useRef<HTMLAudioElement | null>(null);

    // Effect to initialize the audio primer for output device selection
    useEffect(() => {
        const audio = new Audio("data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA");
        audio.volume = 0;
        audioPrimerRef.current = audio;

        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        setIsSpeechSupported(!!SpeechRecognition);
    }, []);

    // Effect to set the initial message silently
    useEffect(() => {
        const initialMessage = { id: 'init-1', sender: 'zarvis' as const, text: "Good day, Sir. Z.A.R.V.I.S. online and ready." };
        setMessages([initialMessage]);
    }, []);

    // Cleanup effect
    useEffect(() => {
        return () => {
            speechSynthesis.cancel();
            if (recognitionRef.current) {
                recognitionRef.current.abort();
            }
        };
    }, []);

    const speak = useCallback((text: string, lang: string, onEndCallback: () => void) => {
        if (!isTtsEnabled || !text) {
            onEndCallback();
            return;
        }

        if (audioPrimerRef.current) {
            audioPrimerRef.current.play().catch(e => {
                if (e.name !== 'NotAllowedError') {
                     console.warn("Audio primer playback failed:", e);
                }
            });
        }

        speechSynthesis.cancel();
        setIsZarvisSpeaking(true);
        const cleanText = text.replace(/\*\*|\*|#+\s|`|\[(.*?)\]\(.*?\)/g, '$1');
        const utterance = new SpeechSynthesisUtterance(cleanText);
        utterance.lang = lang;
        const voices = speechSynthesis.getVoices();
        let selectedVoice;

        if (lang === 'hi-IN') {
            const hindiVoicePreferences = [ 'Google हिन्दी', 'Rishi', 'Hemant' ];
            for (const name of hindiVoicePreferences) {
                selectedVoice = voices.find(v => v.name === name && v.lang === 'hi-IN');
                if (selectedVoice) break;
            }
            if (!selectedVoice) selectedVoice = voices.find(v => v.lang === 'hi-IN' && v.name.includes('Google'));
            if (!selectedVoice) selectedVoice = voices.find(v => v.lang === 'hi-IN');
        } else if (lang === 'en-IN') {
            const indianEnglishVoicePreferences = [ 'Rishi', 'Veena' ];
            // 1. Look for preferred voices with exact lang match
            for (const name of indianEnglishVoicePreferences) {
                selectedVoice = voices.find(v => v.name === name && v.lang === 'en-IN');
                if (selectedVoice) break;
            }
            // 2. Look for any Google voice with the right lang
            if (!selectedVoice) {
                selectedVoice = voices.find(v => v.lang === 'en-IN' && v.name.includes('Google'));
            }
            // 3. Look for any voice with the right lang as a fallback
            if (!selectedVoice) {
                selectedVoice = voices.find(v => v.lang === 'en-IN');
            }
        }
        
        // Fallback for any English variant if no specific voice was found
        if (!selectedVoice && lang.startsWith('en-')) {
             const englishVoicePreferences = [ 'Google UK English Male', 'Daniel' ];
            for (const name of englishVoicePreferences) {
                selectedVoice = voices.find(v => v.name === name);
                if (selectedVoice) break;
            }
            if (!selectedVoice) selectedVoice = voices.find(v => v.lang === 'en-GB' && v.name.includes('Male'));
            if (!selectedVoice) selectedVoice = voices.find(v => v.lang.startsWith('en-') && v.name.includes('Male'));
            if (!selectedVoice) selectedVoice = voices.find(v => v.lang.startsWith('en-'));
        }

        if (selectedVoice) utterance.voice = selectedVoice;
        utterance.pitch = 0.9;
        utterance.rate = 1.1;
        utterance.onend = () => {
             setIsZarvisSpeaking(false);
             onEndCallback();
        };
        utterance.onerror = (e) => {
            const errorEvent = e as SpeechSynthesisErrorEvent;
            const errorMessage = `Speech Synthesis Error: ${errorEvent.error}`;
            console.error(errorMessage, e);
            setError(errorMessage);
            setIsZarvisSpeaking(false);
            onEndCallback();
        };
        speechSynthesis.speak(utterance);
    }, [isTtsEnabled]);

    const handleAction = useCallback((action: Action | null) => {
        if (!action) return;
        switch (action.type) {
            case 'OPEN_URL':
                if (action.url) window.open(action.url, '_blank');
                break;
            case 'SEARCH_WEB':
                if (action.query) window.open(`https://www.google.com/search?q=${encodeURIComponent(action.query)}`, '_blank');
                break;
            case 'PLAY_MEDIA':
                if (action.mediaTitle) window.open(`https://www.youtube.com/results?search_query=${encodeURIComponent(action.mediaTitle)}`, '_blank');
                break;
            default:
                console.warn("Unknown action type:", (action as any).type);
        }
    }, []);

    const handleSendMessage = useCallback(async (text: string) => {
        if (isLoading || !text.trim()) return;
        
        setIsLoading(true);
        speechSynthesis.cancel();
        setError(null);
        
        const userMessage: Message = { id: `user-${Date.now()}`, text, sender: 'user' };
        setMessages(prev => [...prev, userMessage]);
        setTextInput('');

        const zarvisResponseId = `zarvis-${Date.now()}`;
        setMessages(prev => [...prev, { id: zarvisResponseId, text: '', sender: 'zarvis' }]);
        
        let fullResponseJson = "";
        try {
            const stream = await streamMessage(text, currentLanguage);
            for await (const chunk of stream) {
                fullResponseJson += chunk.text;
            }
            
            // More robust JSON extraction to handle potential extra text from the LLM.
            const jsonMatch = fullResponseJson.match(/\{[\s\S]*\}/);
            if (!jsonMatch) {
                throw new Error("No valid JSON object found in the AI response.");
            }
            const jsonContent = jsonMatch[0];
            const parsedResponse = JSON.parse(jsonContent);

            const responseText = parsedResponse.response || "I seem to be at a loss for words, Sir.";
            const action = parsedResponse.action || null;
            const language = parsedResponse.language || 'en-US';
            
            setMessages(prev => prev.map(msg => msg.id === zarvisResponseId ? { ...msg, text: responseText } : msg));
            
            // Execute action immediately to avoid popup blockers, then speak.
            handleAction(action);
            speak(responseText, language, () => {});

        } catch (e: any) {
            console.error("Z.A.R.V.I.S. communication error:", e);
            const errorMessage = "Apologies Sir, I seem to be experiencing a system malfunction. Please check the console.";
            setError(errorMessage);
            setMessages(prev => prev.map(msg => msg.id === zarvisResponseId ? { ...msg, text: errorMessage } : msg));
            speak(errorMessage, 'en-US', () => {});
        } finally {
            setIsLoading(false);
        }
    }, [isLoading, speak, handleAction, currentLanguage]);

    const startListening = useCallback(() => {
        if (!isSpeechSupported || isListening) return;

        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        const recognition = new SpeechRecognition();
        recognitionRef.current = recognition;

        recognition.continuous = false; // Process single utterances.
        recognition.interimResults = true;
        recognition.lang = currentLanguage;

        let finalTranscript = '';

        recognition.onresult = (event: SpeechRecognitionEvent) => {
            let interimTranscript = '';
            // Loop through results to build the full transcript
            for (let i = event.resultIndex; i < event.results.length; ++i) {
                const transcript = event.results[i][0].transcript;
                if (event.results[i].isFinal) {
                    finalTranscript += transcript;
                } else {
                    interimTranscript += transcript;
                }
            }
            setTextInput(finalTranscript + interimTranscript);
        };

        recognition.onerror = (event: SpeechRecognitionErrorEvent) => {
            // 'aborted' and 'no-speech' are common and not critical errors.
            if (event.error !== 'aborted' && event.error !== 'no-speech') {
                console.error("Speech recognition error:", event.error);
                setError(`Speech Error: ${event.error}`);
            }
        };

        recognition.onend = () => {
            setIsListening(false);
            recognitionRef.current = null;
            
            const fullUtterance = finalTranscript.trim();
            if (fullUtterance) {
                handleSendMessage(fullUtterance);
            } else {
                 // Clear input if no speech was detected
                setTextInput('');
            }
        };

        setTextInput('');
        recognition.start();
        setIsListening(true);
    }, [isSpeechSupported, isListening, currentLanguage, handleSendMessage, setError]);

    useEffect(() => {
        const canStartListening = isConversationModeActive && !isListening && !isZarvisSpeaking && !isLoading;
        if (canStartListening) {
            startListening();
        }
    }, [isConversationModeActive, isListening, isZarvisSpeaking, isLoading, startListening]);

    const handleToggleConversationMode = useCallback(() => {
        const nextState = !isConversationModeActive;
        setIsConversationModeActive(nextState);
        if (!nextState && recognitionRef.current) {
            // Abort listening if conversation mode is turned off.
            recognitionRef.current.abort();
            setIsListening(false);
        }
    }, [isConversationModeActive]);
    
    const handleSendFromInput = () => {
        if (textInput.trim() && !isLoading) {
            // Sending a typed message should turn off conversation mode.
            setIsConversationModeActive(false);
            handleSendMessage(textInput);
        }
    };

    return (
        <div className="flex flex-col h-screen bg-slate-950 bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(0,242,255,0.1),rgba(255,255,255,0))]">
            <Header 
                isTtsEnabled={isTtsEnabled} 
                onToggleTts={() => setIsTtsEnabled(p => !p)}
                currentLanguage={currentLanguage}
                onSetLanguage={setCurrentLanguage}
            />
            {error && (
                 <div className="absolute top-24 left-1/2 -translate-x-1/2 bg-red-800/50 border border-red-500 text-red-300 px-4 py-2 rounded-lg glow-border-red z-10">
                    <button onClick={() => setError(null)} className="absolute -top-2 -right-2 text-white bg-red-600 rounded-full w-5 h-5 flex items-center justify-center text-xs">×</button>
                    <p>{error}</p>
                </div>
            )}
            <div className="flex-1 flex flex-col min-h-0">
                 <ChatWindow messages={messages} isLoading={isLoading} />
            </div>
            <div className="p-4 bg-slate-950/50 backdrop-blur-sm border-t border-cyan-500/20">
                <UserInput
                    text={textInput}
                    onTextChange={setTextInput}
                    onSendMessage={handleSendFromInput}
                    isLoading={isLoading}
                    isSpeechSupported={isSpeechSupported}
                    isListening={isListening}
                    isConversationModeActive={isConversationModeActive}
                    onToggleConversationMode={handleToggleConversationMode}
                />
            </div>
        </div>
    );
};
EOF

# Create components/Header.tsx
cat <<'EOF' > src/components/Header.tsx
import React from 'react';
import { SpeakerOnIcon, SpeakerOffIcon, GlobeIcon } from './Icons';

type Language = 'en-US' | 'hi-IN' | 'en-IN';

interface HeaderProps {
    isTtsEnabled: boolean;
    onToggleTts: () => void;
    currentLanguage: Language;
    onSetLanguage: (lang: Language) => void;
}

const Header = ({ isTtsEnabled, onToggleTts, currentLanguage, onSetLanguage }: HeaderProps) => {
    
    const toggleLanguage = () => {
        if (currentLanguage === 'en-US') {
            onSetLanguage('hi-IN');
        } else if (currentLanguage === 'hi-IN') {
            onSetLanguage('en-IN');
        } else { // 'en-IN'
            onSetLanguage('en-US');
        }
    };

    const getLanguageIndicator = () => {
        switch(currentLanguage) {
            case 'en-US': return 'EN';
            case 'hi-IN': return 'HI';
            case 'en-IN': return 'HIN';
            default: return 'EN';
        }
    };

    return (
        <header className="relative text-center p-4 border-b border-cyan-500/20 bg-slate-950/50 backdrop-blur-sm flex justify-between items-center">
            <div className="flex items-center gap-2">
                <button
                    onClick={toggleLanguage}
                    className="relative p-2 rounded-full text-cyan-400 hover:bg-cyan-500/20 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-400"
                    aria-label={`Switch language (current: ${currentLanguage})`}
                >
                    <GlobeIcon />
                    <span className="absolute bottom-1 right-1 text-xs font-bold text-slate-900 bg-cyan-400 rounded-full w-5 h-5 flex items-center justify-center">
                        {getLanguageIndicator()}
                    </span>
                </button>
            </div>
            
            <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
                <h1 className="text-3xl md:text-4xl font-orbitron font-bold text-cyan-400 glow-cyan tracking-widest">
                    Z.A.R.V.I.S.
                </h1>
                <p className="text-sm text-cyan-500/80 tracking-wider">
                    Zealous Adaptive Responsive Virtual Intelligence System
                </p>
            </div>

            <button
                onClick={onToggleTts}
                className="p-2 rounded-full text-cyan-400 hover:bg-cyan-500/20 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-400"
                aria-label={isTtsEnabled ? "Disable voice output" : "Enable voice output"}
            >
                {isTtsEnabled ? <SpeakerOnIcon /> : <SpeakerOffIcon />}
            </button>
        </header>
    );
};

export default Header;
EOF

# Create components/ChatWindow.tsx
cat <<'EOF' > src/components/ChatWindow.tsx
import React, { useEffect, useRef } from 'react';
import type { Message } from '../types';
import LoadingSpinner from './LoadingSpinner';

interface ChatWindowProps {
    messages: Message[];
    isLoading: boolean;
}

const ChatWindow: React.FC<ChatWindowProps> = ({ messages, isLoading }) => {
    const messagesEndRef = useRef<HTMLDivElement>(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(() => {
        scrollToBottom();
    }, [messages]);
    
    // Quick and dirty markdown-to-html for bold and lists
    const formatMessage = (text: string) => {
        let html = text
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>') // Bold
            .replace(/\*(.*?)\*/g, '<em>$1</em>'); // Italic

        // Basic unordered list
        if (html.includes('\n- ')) {
            html = html.replace(/(\n- (.*))+/g, (match) => {
                const items = match.trim().split('\n- ').slice(1);
                const listItems = items.map(item => `<li class="ml-4">${item}</li>`).join('');
                return `<ul class="list-disc list-inside my-2">${listItems}</ul>`;
            });
        }
        
        return { __html: html };
    };


    return (
        <div className="flex-1 overflow-y-auto p-4 md:p-6 space-y-6">
            {messages.map((msg, index) => (
                <div key={msg.id} className={`flex items-end gap-3 ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
                   {msg.sender === 'zarvis' && (
                       <div className="w-8 h-8 rounded-full bg-cyan-500/20 border border-cyan-400 flex items-center justify-center flex-shrink-0">
                           <div className="w-4 h-4 rounded-full bg-cyan-400 glow-cyan"></div>
                       </div>
                   )}
                    <div className={`max-w-xl px-4 py-3 rounded-xl ${
                        msg.sender === 'user'
                            ? 'bg-slate-700 text-white rounded-br-none'
                            : 'bg-transparent border border-cyan-500/50 text-cyan-200 rounded-bl-none'
                    }`}>
                        {msg.sender === 'zarvis' && msg.text === '' && isLoading ? (
                            <LoadingSpinner />
                        ) : (
                            <p className="whitespace-pre-wrap" dangerouslySetInnerHTML={formatMessage(msg.text)}></p>
                        )}
                    </div>
                </div>
            ))}
            <div ref={messagesEndRef} />
        </div>
    );
};

export default ChatWindow;
EOF

# Create components/UserInput.tsx
cat <<'EOF' > src/components/UserInput.tsx
import React, { useRef, useEffect } from 'react';
import { SendIcon, MicrophoneIcon } from './Icons';

interface UserInputProps {
    text: string;
    onTextChange: (text: string) => void;
    onSendMessage: () => void;
    isLoading: boolean;
    isSpeechSupported: boolean;
    isListening: boolean;
    isConversationModeActive: boolean;
    onToggleConversationMode: () => void;
}

const UserInput: React.FC<UserInputProps> = ({
    text,
    onTextChange,
    onSendMessage,
    isLoading,
    isSpeechSupported,
    isListening,
    isConversationModeActive,
    onToggleConversationMode,
}) => {
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    useEffect(() => {
        if (textareaRef.current) {
            textareaRef.current.style.height = 'auto';
            textareaRef.current.style.height = `${textareaRef.current.scrollHeight}px`;
        }
    }, [text]);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSendMessage();
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSubmit(e as unknown as React.FormEvent);
        }
    };

    return (
        <form onSubmit={handleSubmit} className="flex items-end gap-3 bg-slate-900 border border-slate-700 rounded-xl p-2 glow-border-cyan transition-shadow duration-300 focus-within:shadow-[0_0_15px_rgba(0,242,255,0.5)]">
            <textarea
                ref={textareaRef}
                value={text}
                onChange={(e) => onTextChange(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder={isListening ? "Listening..." : "Message Z.A.R.V.I.S...."}
                rows={1}
                className="flex-1 bg-transparent text-slate-200 placeholder-slate-500 focus:outline-none resize-none max-h-40"
                disabled={isLoading}
            />
            {isSpeechSupported && (
                <button
                    type="button"
                    onClick={onToggleConversationMode}
                    disabled={isLoading}
                    className={`w-10 h-10 flex items-center justify-center rounded-full transition-all duration-200 flex-shrink-0 ${
                        isConversationModeActive
                            ? 'bg-cyan-500 text-white shadow-lg shadow-cyan-400/50'
                            : 'text-slate-400 hover:bg-slate-700 hover:text-cyan-400'
                    } ${isListening ? 'animate-pulse' : ''}`}
                    aria-label={isConversationModeActive ? "Stop conversation mode" : "Start conversation mode"}
                >
                    <MicrophoneIcon />
                </button>
            )}
            <button
                type="submit"
                disabled={isLoading || !text.trim()}
                className="w-10 h-10 flex items-center justify-center rounded-full bg-cyan-500 text-slate-900 transition-all duration-200 enabled:hover:bg-cyan-400 enabled:hover:scale-110 disabled:bg-slate-600 disabled:cursor-not-allowed flex-shrink-0"
                aria-label="Send message"
            >
                {isLoading ? (
                   <div className="w-5 h-5 border-2 border-slate-900 border-t-cyan-300 rounded-full animate-spin"></div>
                ) : (
                    <SendIcon />
                )}
            </button>
        </form>
    );
};

export default UserInput;
EOF

# Create components/LoadingSpinner.tsx
cat <<'EOF' > src/components/LoadingSpinner.tsx
import React from 'react';

const LoadingSpinner: React.FC = () => {
    return (
        <div className="flex items-center justify-center space-x-2">
            <div className="w-2 h-2 bg-cyan-400 rounded-full animate-pulse [animation-delay:-0.3s]"></div>
            <div className="w-2 h-2 bg-cyan-400 rounded-full animate-pulse [animation-delay:-0.15s]"></div>
            <div className="w-2 h-2 bg-cyan-400 rounded-full animate-pulse"></div>
        </div>
    );
};

export default LoadingSpinner;
EOF

# Create components/Icons.tsx
cat <<'EOF' > src/components/Icons.tsx
import React from 'react';

export const SendIcon = () => (
    <svg
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="w-5 h-5"
        aria-hidden="true"
    >
        <path d="M22 2 11 13" />
        <path d="m22 2-7 20-4-9-9-4 20-7z" />
    </svg>
);

export const SpeakerOnIcon = () => (
    <svg 
        xmlns="http://www.w3.org/2000/svg" 
        width="24" 
        height="24" 
        viewBox="0 0 24 24" 
        fill="none" 
        stroke="currentColor" 
        strokeWidth="2" 
        strokeLinecap="round" 
        strokeLinejoin="round"
        className="w-6 h-6"
        aria-hidden="true"
    >
        <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"></polygon>
        <path d="M15.54 8.46a5 5 0 0 1 0 7.07"></path>
        <path d="M19.07 4.93a10 10 0 0 1 0 14.14"></path>
    </svg>
);

export const SpeakerOffIcon = () => (
    <svg 
        xmlns="http://www.w3.org/2000/svg" 
        width="24" 
        height="24" 
        viewBox="0 0 24 24" 
        fill="none" 
        stroke="currentColor" 
        strokeWidth="2" 
        strokeLinecap="round" 
        strokeLinejoin="round"
        className="w-6 h-6"
        aria-hidden="true"
    >
        <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"></polygon>
        <line x1="23" y1="9" x2="17" y2="15"></line>
        <line x1="17" y1="9" x2="23" y2="15"></line>
    </svg>
);

export const MicrophoneIcon = () => (
    <svg
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="w-5 h-5"
        aria-hidden="true"
    >
        <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"></path>
        <path d="M19 10v2a7 7 0 0 1-14 0v-2"></path>
        <line x1="12" y1="19" x2="12" y2="23"></line>
        <line x1="8" y1="23" x2="16" y2="23"></line>
    </svg>
);

export const GlobeIcon = () => (
    <svg
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="w-6 h-6"
        aria-hidden="true"
    >
        <circle cx="12" cy="12" r="10"></circle>
        <line x1="2" y1="12" x2="22" y2="12"></line>
        <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
    </svg>
);
EOF

echo "All Z.A.R.V.I.S. files have been created successfully."