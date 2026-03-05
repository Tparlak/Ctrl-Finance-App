import { useState } from 'react';
import { X, Check } from 'lucide-react';
import { useFinance } from '../../store/financeStore';
import { CategoryIcon } from '../shared/CategoryIcon';
import type { TransactionType } from '../../models/types';

interface Props { onClose: () => void; }

export function AddTransactionModal({ onClose }: Props) {
  const { categories, accounts, addTransaction } = useFinance();
  const [type, setType] = useState<TransactionType>('expense');
  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState('');
  const [categoryId, setCategoryId] = useState(categories[0]?.id || '');
  const [accountId, setAccountId] = useState(accounts[0]?.id || '');
  const [note, setNote] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);

  const filteredCategories = categories.filter(c => c.type === type || c.type === 'transfer');

  const handleSubmit = () => {
    if (!title || !amount || isNaN(parseFloat(amount))) return;
    addTransaction({
      id: `t_${Date.now()}`,
      title,
      amount: parseFloat(amount),
      type,
      categoryId,
      accountId,
      date,
      note: note || undefined,
    });
    onClose();
  };

  const TYPE_OPTS: Array<{ key: TransactionType; label: string; color: string }> = [
    { key: 'expense', label: 'Gider', color: 'text-red-400 bg-red-500/20 border-red-500/40' },
    { key: 'income', label: 'Gelir', color: 'text-emerald-400 bg-emerald-500/20 border-emerald-500/40' },
    { key: 'transfer', label: 'Transfer', color: 'text-blue-400 bg-blue-500/20 border-blue-500/40' },
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />
      <div className="relative w-full max-w-lg glass-modal rounded-t-3xl md:rounded-3xl p-6 max-h-[90vh] overflow-y-auto">
        {/* Handle */}
        <div className="w-10 h-1 bg-white/20 rounded-full mx-auto mb-4 md:hidden" />

        <div className="flex items-center justify-between mb-5">
          <h2 className="text-white font-bold text-lg">Yeni İşlem</h2>
          <button onClick={onClose} className="w-8 h-8 rounded-xl glass-btn flex items-center justify-center text-white/60 hover:text-white">
            <X size={16} />
          </button>
        </div>

        {/* Type selector */}
        <div className="flex gap-2 mb-5">
          {TYPE_OPTS.map(t => (
            <button
              key={t.key}
              onClick={() => { setType(t.key); setCategoryId(categories.find(c => c.type === t.key)?.id || ''); }}
              className={`flex-1 py-2 rounded-xl text-sm font-medium border transition-all ${
                type === t.key ? t.color : 'glass-btn text-white/50 border-white/10 hover:text-white'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        {/* Amount */}
        <div className="mb-4">
          <label className="text-white/50 text-xs mb-1.5 block">Tutar</label>
          <div className="relative">
            <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-white/40 text-sm">₺</span>
            <input
              type="number"
              value={amount}
              onChange={e => setAmount(e.target.value)}
              placeholder="0,00"
              className="w-full input-glass pl-8 text-white text-xl font-bold"
            />
          </div>
        </div>

        {/* Title */}
        <div className="mb-4">
          <label className="text-white/50 text-xs mb-1.5 block">İşlem Adı</label>
          <input
            type="text"
            value={title}
            onChange={e => setTitle(e.target.value)}
            placeholder="Migros Market..."
            className="w-full input-glass text-white"
          />
        </div>

        {/* Categories */}
        <div className="mb-4">
          <label className="text-white/50 text-xs mb-1.5 block">Kategori</label>
          <div className="grid grid-cols-4 gap-2">
            {filteredCategories.map(cat => (
              <button
                key={cat.id}
                onClick={() => setCategoryId(cat.id)}
                className={`flex flex-col items-center gap-1.5 p-2.5 rounded-xl transition-all ${
                  categoryId === cat.id ? 'bg-white/15 border border-white/20' : 'glass-btn border border-transparent'
                }`}
              >
                <CategoryIcon icon={cat.icon} color={cat.color} size={14} className="!w-8 !h-8" />
                <span className="text-white/70 text-[10px] text-center leading-tight">{cat.name}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Account */}
        <div className="mb-4">
          <label className="text-white/50 text-xs mb-1.5 block">Hesap</label>
          <div className="grid grid-cols-2 gap-2">
            {accounts.map(acc => (
              <button
                key={acc.id}
                onClick={() => setAccountId(acc.id)}
                className={`flex items-center gap-2 p-3 rounded-xl transition-all text-left ${
                  accountId === acc.id ? 'bg-white/15 border border-white/20' : 'glass-btn border border-transparent'
                }`}
              >
                <div className="w-6 h-6 rounded-lg flex-shrink-0" style={{ backgroundColor: acc.color + '40' }}>
                  <div className="w-full h-full rounded-lg flex items-center justify-center">
                    <span style={{ color: acc.color }} className="text-[10px] font-bold">{acc.name[0]}</span>
                  </div>
                </div>
                <span className="text-white/80 text-xs truncate">{acc.name}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Date */}
        <div className="mb-4">
          <label className="text-white/50 text-xs mb-1.5 block">Tarih</label>
          <input
            type="date"
            value={date}
            onChange={e => setDate(e.target.value)}
            className="w-full input-glass text-white"
          />
        </div>

        {/* Note */}
        <div className="mb-6">
          <label className="text-white/50 text-xs mb-1.5 block">Not (opsiyonel)</label>
          <textarea
            value={note}
            onChange={e => setNote(e.target.value)}
            placeholder="Notunuzu ekleyin..."
            rows={2}
            className="w-full input-glass text-white resize-none"
          />
        </div>

        {/* Submit */}
        <button
          onClick={handleSubmit}
          disabled={!title || !amount}
          className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl bg-violet-600 hover:bg-violet-500 disabled:opacity-40 disabled:cursor-not-allowed text-white font-semibold transition-all shadow-lg shadow-violet-500/30"
        >
          <Check size={18} /> İşlemi Kaydet
        </button>
      </div>
    </div>
  );
}
