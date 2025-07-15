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
