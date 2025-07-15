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
