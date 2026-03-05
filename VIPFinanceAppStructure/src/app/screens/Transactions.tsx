import { useState, useMemo } from 'react';
import { Search, Filter, Plus, Trash2, X, ChevronDown } from 'lucide-react';
import { useFinance } from '../store/financeStore';
import { GlassCard } from '../components/shared/GlassCard';
import { CategoryIcon } from '../components/shared/CategoryIcon';
import { AmountText, formatCurrency } from '../components/shared/AmountText';
import { AddTransactionModal } from '../components/modals/AddTransactionModal';
import type { TransactionType } from '../models/types';

type FilterType = TransactionType | 'all';

export default function Transactions() {
  const { transactions, getCategoryById, getAccountById, deleteTransaction } = useFinance();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<FilterType>('all');
  const [showAdd, setShowAdd] = useState(false);
  const [showFilter, setShowFilter] = useState(false);
  const [selectedAccount, setSelectedAccount] = useState('all');
  const { accounts } = useFinance();

  const filtered = useMemo(() => {
    return transactions.filter(tx => {
      const matchSearch = tx.title.toLowerCase().includes(search.toLowerCase());
      const matchType = typeFilter === 'all' || tx.type === typeFilter;
      const matchAccount = selectedAccount === 'all' || tx.accountId === selectedAccount;
      return matchSearch && matchType && matchAccount;
    });
  }, [transactions, search, typeFilter, selectedAccount]);

  // Group by date
  const grouped = useMemo(() => {
    const groups: Record<string, typeof filtered> = {};
    filtered.forEach(tx => {
      if (!groups[tx.date]) groups[tx.date] = [];
      groups[tx.date].push(tx);
    });
    return Object.entries(groups).sort(([a], [b]) => b.localeCompare(a));
  }, [filtered]);

  const totalIncome = filtered.filter(t => t.type === 'income').reduce((s, t) => s + t.amount, 0);
  const totalExpense = filtered.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);

  const formatDate = (dateStr: string) => {
    const d = new Date(dateStr);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);
    if (d.toDateString() === today.toDateString()) return 'Bugün';
    if (d.toDateString() === yesterday.toDateString()) return 'Dün';
    return d.toLocaleDateString('tr-TR', { weekday: 'long', day: 'numeric', month: 'long' });
  };

  const TYPE_FILTERS: Array<{ key: FilterType; label: string }> = [
    { key: 'all', label: 'Tümü' },
    { key: 'income', label: 'Gelir' },
    { key: 'expense', label: 'Gider' },
    { key: 'transfer', label: 'Transfer' },
  ];

  return (
    <div className="min-h-screen px-4 pt-6 pb-6 md:px-8 md:pt-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-white text-xl font-bold">İşlemler</h1>
          <p className="text-white/40 text-sm">{filtered.length} işlem listeleniyor</p>
        </div>
        <button
          onClick={() => setShowAdd(true)}
          className="flex items-center gap-2 bg-violet-600 hover:bg-violet-500 text-white text-sm font-medium px-4 py-2 rounded-xl transition-colors shadow-lg shadow-violet-500/30"
        >
          <Plus size={15} /> Ekle
        </button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-2 gap-3 mb-5">
        <GlassCard padding="p-4" gradient="green">
          <p className="text-white/50 text-xs mb-1">Toplam Gelir</p>
          <AmountText amount={totalIncome} type="income" className="font-bold" showSign={false} />
        </GlassCard>
        <GlassCard padding="p-4" gradient="red">
          <p className="text-white/50 text-xs mb-1">Toplam Gider</p>
          <AmountText amount={totalExpense} type="expense" className="font-bold" showSign={false} />
        </GlassCard>
      </div>

      {/* Search */}
      <div className="flex gap-2 mb-4">
        <div className="flex-1 relative">
          <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-white/30" />
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="İşlem ara..."
            className="w-full bg-white/8 border border-white/10 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-white/30 outline-none focus:border-violet-500/50 focus:bg-white/12 transition-all"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-white/30">
              <X size={14} />
            </button>
          )}
        </div>
        <button
          onClick={() => setShowFilter(v => !v)}
          className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 transition-all ${
            showFilter ? 'bg-violet-600 text-white' : 'glass-btn text-white/60 hover:text-white'
          }`}
        >
          <Filter size={16} />
        </button>
      </div>

      {/* Filter Panel */}
      {showFilter && (
        <GlassCard className="mb-4" padding="p-4">
          <div className="mb-3">
            <p className="text-white/60 text-xs mb-2">İşlem Tipi</p>
            <div className="flex gap-2 flex-wrap">
              {TYPE_FILTERS.map(f => (
                <button
                  key={f.key}
                  onClick={() => setTypeFilter(f.key)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                    typeFilter === f.key ? 'bg-violet-600 text-white' : 'glass-btn text-white/60 hover:text-white'
                  }`}
                >
                  {f.label}
                </button>
              ))}
            </div>
          </div>
          <div>
            <p className="text-white/60 text-xs mb-2">Hesap</p>
            <div className="flex gap-2 flex-wrap">
              <button
                onClick={() => setSelectedAccount('all')}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                  selectedAccount === 'all' ? 'bg-violet-600 text-white' : 'glass-btn text-white/60 hover:text-white'
                }`}
              >
                Tümü
              </button>
              {accounts.map(acc => (
                <button
                  key={acc.id}
                  onClick={() => setSelectedAccount(acc.id)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                    selectedAccount === acc.id ? 'bg-violet-600 text-white' : 'glass-btn text-white/60 hover:text-white'
                  }`}
                >
                  {acc.name}
                </button>
              ))}
            </div>
          </div>
        </GlassCard>
      )}

      {/* Type Filter tabs */}
      <div className="flex gap-2 overflow-x-auto pb-2 mb-5 no-scrollbar">
        {TYPE_FILTERS.map(f => (
          <button
            key={f.key}
            onClick={() => setTypeFilter(f.key)}
            className={`px-4 py-1.5 rounded-xl text-sm font-medium flex-shrink-0 transition-all ${
              typeFilter === f.key
                ? 'bg-violet-600 text-white shadow-lg shadow-violet-500/30'
                : 'glass-btn text-white/60 hover:text-white'
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Transaction Groups */}
      <div className="space-y-5">
        {grouped.length === 0 && (
          <div className="text-center py-16 text-white/30">
            <Search size={40} className="mx-auto mb-3 opacity-30" />
            <p>İşlem bulunamadı</p>
          </div>
        )}
        {grouped.map(([date, txs]) => {
          const dayTotal = txs.reduce((s, t) => {
            if (t.type === 'income') return s + t.amount;
            if (t.type === 'expense') return s - t.amount;
            return s;
          }, 0);

          return (
            <div key={date}>
              <div className="flex items-center justify-between mb-2 px-1">
                <p className="text-white/60 text-xs font-medium">{formatDate(date)}</p>
                <span className={`text-xs font-semibold ${dayTotal >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>
                  {dayTotal >= 0 ? '+' : ''}{formatCurrency(dayTotal)}
                </span>
              </div>
              <GlassCard padding="p-0" className="overflow-hidden">
                {txs.map((tx, i) => {
                  const cat = getCategoryById(tx.categoryId);
                  const acc = getAccountById(tx.accountId);
                  return (
                    <div
                      key={tx.id}
                      className={`flex items-center gap-3 px-4 py-3.5 ${
                        i < txs.length - 1 ? 'border-b border-white/5' : ''
                      } hover:bg-white/5 transition-colors group`}
                    >
                      <CategoryIcon icon={cat?.icon || 'HelpCircle'} color={cat?.color || '#888'} size={16} />
                      <div className="flex-1 min-w-0">
                        <p className="text-white text-sm font-medium truncate">{tx.title}</p>
                        <p className="text-white/40 text-xs">{cat?.name} · {acc?.name}</p>
                        {tx.note && <p className="text-white/30 text-xs truncate">{tx.note}</p>}
                      </div>
                      <AmountText amount={tx.amount} type={tx.type} className="text-sm font-semibold flex-shrink-0" />
                      <button
                        onClick={() => deleteTransaction(tx.id)}
                        className="opacity-0 group-hover:opacity-100 w-7 h-7 rounded-lg flex items-center justify-center text-red-400 hover:bg-red-500/20 transition-all"
                      >
                        <Trash2 size={13} />
                      </button>
                    </div>
                  );
                })}
              </GlassCard>
            </div>
          );
        })}
      </div>

      {showAdd && <AddTransactionModal onClose={() => setShowAdd(false)} />}
    </div>
  );
}
