import { useState } from 'react';
import { Plus, Wallet, Building2, CreditCard, TrendingUp, PiggyBank, MoreVertical, Trash2, Edit3 } from 'lucide-react';
import { useFinance } from '../store/financeStore';
import { GlassCard } from '../components/shared/GlassCard';
import { CategoryIcon } from '../components/shared/CategoryIcon';
import { AmountText, formatCurrency } from '../components/shared/AmountText';
import { AddAccountModal } from '../components/modals/AddAccountModal';
import type { Account, AccountType } from '../models/types';

const ACCOUNT_TYPE_LABELS: Record<AccountType, string> = {
  bank: 'Banka Hesabı',
  cash: 'Nakit',
  credit: 'Kredi Kartı',
  investment: 'Yatırım',
  savings: 'Birikim',
};

const ACCOUNT_TYPE_ICONS: Record<AccountType, React.ElementType> = {
  bank: Building2, cash: Wallet, credit: CreditCard, investment: TrendingUp, savings: PiggyBank,
};

function AccountCard({ account, onDelete }: { account: Account; onDelete: () => void }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const TypeIcon = ACCOUNT_TYPE_ICONS[account.type];
  const isNegative = account.balance < 0;

  return (
    <GlassCard padding="p-5" className="relative">
      {/* Color accent */}
      <div className="absolute top-0 left-0 w-1 h-full rounded-l-2xl" style={{ backgroundColor: account.color }} />

      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div
            className="w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0"
            style={{ backgroundColor: account.color + '25' }}
          >
            <TypeIcon size={20} style={{ color: account.color }} />
          </div>
          <div>
            <h3 className="text-white font-semibold">{account.name}</h3>
            <p className="text-white/40 text-xs">{ACCOUNT_TYPE_LABELS[account.type]}</p>
          </div>
        </div>
        <div className="relative">
          <button
            onClick={() => setMenuOpen(v => !v)}
            className="w-7 h-7 rounded-lg glass-btn flex items-center justify-center text-white/40 hover:text-white"
          >
            <MoreVertical size={14} />
          </button>
          {menuOpen && (
            <div className="absolute right-0 top-8 z-20 glass-dropdown rounded-xl overflow-hidden min-w-[130px] shadow-xl">
              <button className="flex items-center gap-2 w-full px-4 py-2.5 text-sm text-white/80 hover:bg-white/10">
                <Edit3 size={13} /> Düzenle
              </button>
              <button
                onClick={() => { onDelete(); setMenuOpen(false); }}
                className="flex items-center gap-2 w-full px-4 py-2.5 text-sm text-red-400 hover:bg-white/10"
              >
                <Trash2 size={13} /> Sil
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Balance */}
      <div>
        <p className="text-white/40 text-xs mb-0.5">Bakiye</p>
        <p className={`text-2xl font-bold ${isNegative ? 'text-red-400' : 'text-white'}`}>
          {formatCurrency(account.balance)}
        </p>
      </div>

      {account.lastFourDigits && (
        <p className="text-white/30 text-xs mt-3">•••• {account.lastFourDigits}</p>
      )}
    </GlassCard>
  );
}

export default function Accounts() {
  const { accounts, transactions, deleteAccount, getTotalBalance } = useFinance();
  const [showAddModal, setShowAddModal] = useState(false);
  const [activeFilter, setActiveFilter] = useState<AccountType | 'all'>('all');

  const totalBalance = getTotalBalance();
  const totalAssets = accounts.filter(a => a.balance > 0).reduce((s, a) => s + a.balance, 0);
  const totalDebt = accounts.filter(a => a.balance < 0).reduce((s, a) => s + a.balance, 0);

  const filtered = activeFilter === 'all' ? accounts : accounts.filter(a => a.type === activeFilter);

  const FILTERS: Array<{ key: AccountType | 'all'; label: string }> = [
    { key: 'all', label: 'Tümü' },
    { key: 'bank', label: 'Banka' },
    { key: 'cash', label: 'Nakit' },
    { key: 'credit', label: 'Kredi' },
    { key: 'investment', label: 'Yatırım' },
  ];

  return (
    <div className="min-h-screen px-4 pt-6 pb-6 md:px-8 md:pt-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-white text-xl font-bold">Hesaplarım</h1>
          <p className="text-white/40 text-sm">{accounts.length} hesap bağlı</p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center gap-2 bg-violet-600 hover:bg-violet-500 text-white text-sm font-medium px-4 py-2 rounded-xl transition-colors shadow-lg shadow-violet-500/30"
        >
          <Plus size={15} /> Hesap Ekle
        </button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        <GlassCard padding="p-4" gradient="violet">
          <p className="text-white/50 text-xs mb-1">Net Varlık</p>
          <p className="text-white font-bold text-base">{formatCurrency(totalBalance)}</p>
        </GlassCard>
        <GlassCard padding="p-4" gradient="green">
          <p className="text-white/50 text-xs mb-1">Aktif</p>
          <p className="text-emerald-400 font-bold text-base">{formatCurrency(totalAssets)}</p>
        </GlassCard>
        <GlassCard padding="p-4" gradient="red">
          <p className="text-white/50 text-xs mb-1">Borç</p>
          <p className="text-red-400 font-bold text-base">{formatCurrency(Math.abs(totalDebt))}</p>
        </GlassCard>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-2 overflow-x-auto pb-2 mb-5 no-scrollbar">
        {FILTERS.map(f => (
          <button
            key={f.key}
            onClick={() => setActiveFilter(f.key)}
            className={`px-4 py-1.5 rounded-xl text-sm font-medium flex-shrink-0 transition-all ${
              activeFilter === f.key
                ? 'bg-violet-600 text-white shadow-lg shadow-violet-500/30'
                : 'glass-btn text-white/60 hover:text-white'
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Account Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
        {filtered.map(account => (
          <AccountCard
            key={account.id}
            account={account}
            onDelete={() => deleteAccount(account.id)}
          />
        ))}
      </div>

      {/* Recent Account Activity */}
      <GlassCard padding="p-5">
        <h3 className="text-white font-semibold mb-4">Hesap Aktivitesi</h3>
        <div className="space-y-3">
          {accounts.map(acc => {
            const accTxs = transactions.filter(t => t.accountId === acc.id);
            const txCount = accTxs.length;
            const TypeIcon = ACCOUNT_TYPE_ICONS[acc.type];
            return (
              <div key={acc.id} className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                  style={{ backgroundColor: acc.color + '25' }}>
                  <TypeIcon size={16} style={{ color: acc.color }} />
                </div>
                <div className="flex-1">
                  <p className="text-white text-sm font-medium">{acc.name}</p>
                  <p className="text-white/40 text-xs">{txCount} işlem</p>
                </div>
                <div className="h-1.5 w-20 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full"
                    style={{ width: `${Math.min(100, (txCount / 10) * 100)}%`, backgroundColor: acc.color }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </GlassCard>

      {showAddModal && <AddAccountModal onClose={() => setShowAddModal(false)} />}
    </div>
  );
}
