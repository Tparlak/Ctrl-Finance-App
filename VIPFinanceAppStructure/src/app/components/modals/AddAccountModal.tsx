import { useState } from 'react';
import { X, Check } from 'lucide-react';
import { useFinance } from '../../store/financeStore';
import type { AccountType } from '../../models/types';

interface Props { onClose: () => void; }

const ACCOUNT_TYPES: Array<{ key: AccountType; label: string; icon: string }> = [
  { key: 'bank', label: 'Banka', icon: '🏦' },
  { key: 'cash', label: 'Nakit', icon: '💵' },
  { key: 'credit', label: 'Kredi Kartı', icon: '💳' },
  { key: 'investment', label: 'Yatırım', icon: '📈' },
  { key: 'savings', label: 'Birikim', icon: '🐷' },
];

const COLORS = ['#10B981', '#3B82F6', '#8B5CF6', '#F59E0B', '#EF4444', '#06B6D4', '#EC4899', '#F97316'];

export function AddAccountModal({ onClose }: Props) {
  const { addAccount } = useFinance();
  const [name, setName] = useState('');
  const [type, setType] = useState<AccountType>('bank');
  const [balance, setBalance] = useState('');
  const [color, setColor] = useState(COLORS[0]);
  const [bankName, setBankName] = useState('');
  const [lastFour, setLastFour] = useState('');

  const handleSubmit = () => {
    if (!name || isNaN(parseFloat(balance || '0'))) return;
    addAccount({
      id: `a_${Date.now()}`,
      name,
      type,
      balance: parseFloat(balance || '0'),
      currency: 'TRY',
      color,
      icon: type === 'bank' ? 'Building2' : type === 'cash' ? 'Wallet' : type === 'credit' ? 'CreditCard' : type === 'investment' ? 'TrendingUp' : 'PiggyBank',
      bankName: bankName || undefined,
      lastFourDigits: lastFour || undefined,
      createdAt: new Date().toISOString().split('T')[0],
    });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />
      <div className="relative w-full max-w-lg glass-modal rounded-t-3xl md:rounded-3xl p-6 max-h-[90vh] overflow-y-auto">
        <div className="w-10 h-1 bg-white/20 rounded-full mx-auto mb-4 md:hidden" />
        <div className="flex items-center justify-between mb-5">
          <h2 className="text-white font-bold text-lg">Yeni Hesap</h2>
          <button onClick={onClose} className="w-8 h-8 rounded-xl glass-btn flex items-center justify-center text-white/60 hover:text-white">
            <X size={16} />
          </button>
        </div>

        {/* Type */}
        <div className="mb-4">
          <label className="text-white/50 text-xs mb-1.5 block">Hesap Tipi</label>
          <div className="grid grid-cols-5 gap-2">
            {ACCOUNT_TYPES.map(t => (
              <button
                key={t.key}
                onClick={() => setType(t.key)}
                className={`flex flex-col items-center gap-1 p-2.5 rounded-xl transition-all text-center ${
                  type === t.key ? 'bg-violet-600/30 border border-violet-500/50' : 'glass-btn border border-transparent'
                }`}
              >
                <span className="text-lg">{t.icon}</span>
                <span className="text-white/70 text-[10px]">{t.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Name */}
        <div className="mb-4">
          <label className="text-white/50 text-xs mb-1.5 block">Hesap Adı</label>
          <input type="text" value={name} onChange={e => setName(e.target.value)}
            placeholder="Garanti Bankası..." className="w-full input-glass text-white" />
        </div>

        {/* Balance */}
        <div className="mb-4">
          <label className="text-white/50 text-xs mb-1.5 block">Başlangıç Bakiyesi</label>
          <div className="relative">
            <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-white/40 text-sm">₺</span>
            <input type="number" value={balance} onChange={e => setBalance(e.target.value)}
              placeholder="0,00" className="w-full input-glass text-white pl-8" />
          </div>
        </div>

        {/* Bank name */}
        {(type === 'bank' || type === 'credit') && (
          <>
            <div className="mb-4">
              <label className="text-white/50 text-xs mb-1.5 block">Banka Adı</label>
              <input type="text" value={bankName} onChange={e => setBankName(e.target.value)}
                placeholder="Garanti BBVA..." className="w-full input-glass text-white" />
            </div>
            <div className="mb-4">
              <label className="text-white/50 text-xs mb-1.5 block">Son 4 Hane</label>
              <input type="text" value={lastFour} onChange={e => setLastFour(e.target.value.slice(0, 4))}
                placeholder="4521" maxLength={4} className="w-full input-glass text-white" />
            </div>
          </>
        )}

        {/* Color */}
        <div className="mb-6">
          <label className="text-white/50 text-xs mb-1.5 block">Renk</label>
          <div className="flex gap-2 flex-wrap">
            {COLORS.map(c => (
              <button
                key={c}
                onClick={() => setColor(c)}
                className={`w-8 h-8 rounded-xl transition-all ${color === c ? 'ring-2 ring-white/60 ring-offset-2 ring-offset-transparent scale-110' : ''}`}
                style={{ backgroundColor: c }}
              />
            ))}
          </div>
        </div>

        <button
          onClick={handleSubmit}
          disabled={!name}
          className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl bg-violet-600 hover:bg-violet-500 disabled:opacity-40 disabled:cursor-not-allowed text-white font-semibold transition-all shadow-lg shadow-violet-500/30"
        >
          <Check size={18} /> Hesabı Kaydet
        </button>
      </div>
    </div>
  );
}
