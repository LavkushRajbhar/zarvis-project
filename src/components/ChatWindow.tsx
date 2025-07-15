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
