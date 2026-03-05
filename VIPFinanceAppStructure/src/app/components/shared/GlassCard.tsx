import React from 'react';

interface GlassCardProps {
  children: React.ReactNode;
  className?: string;
  gradient?: 'violet' | 'green' | 'blue' | 'red' | 'amber' | 'none';
  onClick?: () => void;
  padding?: string;
}

const gradientMap = {
  violet: 'from-violet-600/30 to-indigo-600/20',
  green: 'from-emerald-600/30 to-teal-600/20',
  blue: 'from-blue-600/30 to-cyan-600/20',
  red: 'from-red-600/30 to-rose-600/20',
  amber: 'from-amber-600/30 to-orange-600/20',
  none: '',
};

export function GlassCard({
  children, className = '', gradient = 'none', onClick, padding = 'p-5'
}: GlassCardProps) {
  return (
    <div
      onClick={onClick}
      className={`
        relative overflow-hidden rounded-2xl
        bg-white/8 backdrop-blur-xl
        border border-white/12
        shadow-[0_8px_32px_rgba(0,0,0,0.3)]
        ${gradient !== 'none' ? `bg-gradient-to-br ${gradientMap[gradient]}` : ''}
        ${onClick ? 'cursor-pointer hover:bg-white/12 hover:border-white/20 transition-all duration-200 active:scale-[0.98]' : ''}
        ${padding} ${className}
      `}
    >
      {children}
    </div>
  );
}
