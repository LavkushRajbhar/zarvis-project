import { useState, useCallback, useEffect, useRef } from 'react';
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
