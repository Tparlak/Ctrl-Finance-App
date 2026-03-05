import { useState } from 'react';
import { useNavigate } from 'react-router';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts';
import {
  TrendingUp, TrendingDown, ArrowUpRight, Bell, Eye, EyeOff,
  ChevronLeft, ChevronRight, Plus
} from 'lucide-react';
import { useFinance } from '../store/financeStore';
import { GlassCard } from '../components/shared/GlassCard';
import { CategoryIcon } from '../components/shared/CategoryIcon';
import { AmountText, formatCurrency } from '../components/shared/AmountText';
import { AddTransactionModal } from '../components/modals/AddTransactionModal';

const MONTHS = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
];

// Gelir/gider grafiği için mock aylık data
const CHART_DATA = [
  { month: 'Eyl', gelir: 18500, gider: 12000 },
  { month: 'Eki', gelir: 18500, gider: 14500 },
  { month: 'Kas', gelir: 23500, gider: 13200 },
  { month: 'Ara', gelir: 18500, gider: 18000 },
  { month: 'Oca', gelir: 18500, gider: 15600 },
  { month: 'Şub', gelir: 25800, gider: 13700 },
  { month: 'Mar', gelir: 18500, gider: 11274 },
];

export default function Dashboard() {
  const navigate = useNavigate();
  const { transactions, accounts, categories, selectedMonth, setSelectedMonth,
    getTotalBalance, getMonthlyIncome, getMonthlyExpense, getCategoryById } = useFinance();
  const [balanceHidden, setBalanceHidden] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);

  const totalBalance = getTotalBalance();
  const [year, month] = selectedMonth.split('-').map(Number);
  const monthName = MONTHS[month - 1];

  const income = getMonthlyIncome(selectedMonth);
  const expense = getMonthlyExpense(selectedMonth);
  const netSavings = income - expense;

  const navigateMonth = (dir: number) => {
    const d = new Date(year, month - 1 + dir, 1);
    setSelectedMonth(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`);
  };

  // Recent transactions
  const recentTxs = transactions.slice(0, 6);

  // Category breakdown for pie chart
  const expenseByCategory = transactions
    .filter(t => t.date.startsWith(selectedMonth) && t.type === 'expense')
    .reduce<Record<string, number>>((acc, t) => {
      acc[t.categoryId] = (acc[t.categoryId] || 0) + t.amount;
      return acc;
    }, {});

  const pieData = Object.entries(expenseByCategory).map(([catId, amount]) => {
    const cat = getCategoryById(catId);
    return { name: cat?.name || catId, value: amount, color: cat?.color || '#888' };
  }).sort((a, b) => b.value - a.value).slice(0, 5);

  return (
    <div className="min-h-screen px-4 pt-6 pb-6 md:px-8 md:pt-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <p className="text-white/50 text-sm">Merhaba 👋</p>
          <h1 className="text-white text-xl font-bold">VIP Kullanıcı</h1>
        </div>
        <div className="flex items-center gap-2">
          <button className="w-10 h-10 rounded-xl glass-btn flex items-center justify-center relative">
            <Bell size={18} className="text-white/70" />
            <span className="absolute top-2 right-2 w-2 h-2 bg-violet-500 rounded-full" />
          </button>
          <button
            onClick={() => setShowAddModal(true)}
            className="w-10 h-10 rounded-xl bg-violet-600 flex items-center justify-center shadow-lg shadow-violet-500/30"
          >
            <Plus size={18} className="text-white" />
          </button>
        </div>
      </div>

      {/* Total Balance Card */}
      <GlassCard gradient="violet" className="mb-5" padding="p-6">
        <div className="flex items-start justify-between mb-4">
          <div>
            <p className="text-white/60 text-sm mb-1">Toplam Varlık</p>
            <div className="flex items-center gap-2">
              <h2 className="text-white text-3xl font-bold tracking-tight">
                {balanceHidden ? '••••••' : formatCurrency(totalBalance)}
              </h2>
              <button onClick={() => setBalanceHidden(v => !v)} className="text-white/40 hover:text-white/70 transition-colors">
                {balanceHidden ? <Eye size={16} /> : <EyeOff size={16} />}
              </button>
            </div>
          </div>
          {/* Month selector */}
          <div className="flex items-center gap-1 bg-white/10 rounded-xl px-2 py-1">
            <button onClick={() => navigateMonth(-1)} className="text-white/60 hover:text-white p-1">
              <ChevronLeft size={14} />
            </button>
            <span className="text-white/80 text-xs font-medium px-1">{monthName} {year}</span>
            <button onClick={() => navigateMonth(1)} className="text-white/60 hover:text-white p-1">
              <ChevronRight size={14} />
            </button>
          </div>
        </div>

        {/* Income / Expense row */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white/10 rounded-xl p-3">
            <div className="flex items-center gap-2 mb-1">
              <div className="w-6 h-6 rounded-lg bg-emerald-500/30 flex items-center justify-center">
                <TrendingUp size={12} className="text-emerald-400" />
              </div>
              <span className="text-white/60 text-xs">Gelir</span>
            </div>
            <AmountText amount={income} type="income" className="text-base font-bold" showSign={false} />
          </div>
          <div className="bg-white/10 rounded-xl p-3">
            <div className="flex items-center gap-2 mb-1">
              <div className="w-6 h-6 rounded-lg bg-red-500/30 flex items-center justify-center">
                <TrendingDown size={12} className="text-red-400" />
              </div>
              <span className="text-white/60 text-xs">Gider</span>
            </div>
            <AmountText amount={expense} type="expense" className="text-base font-bold" showSign={false} />
          </div>
        </div>
      </GlassCard>

      {/* Area Chart */}
      <GlassCard className="mb-5" padding="p-5">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-white font-semibold">Gelir / Gider Grafiği</h3>
          <span className="text-white/40 text-xs">Son 7 Ay</span>
        </div>
        <ResponsiveContainer width="100%" height={180}>
          <AreaChart data={CHART_DATA} margin={{ top: 5, right: 5, bottom: 0, left: 0 }}>
            <defs>
              <linearGradient id="incomeGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#10B981" stopOpacity={0.4} />
                <stop offset="95%" stopColor="#10B981" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="expenseGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#EF4444" stopOpacity={0.4} />
                <stop offset="95%" stopColor="#EF4444" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
            <XAxis dataKey="month" tick={{ fill: 'rgba(255,255,255,0.4)', fontSize: 11 }} axisLine={false} tickLine={false} />
            <YAxis hide />
            <Tooltip
              contentStyle={{ background: 'rgba(15,15,30,0.9)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 12, fontSize: 12 }}
              labelStyle={{ color: 'rgba(255,255,255,0.8)' }}
              formatter={(val: number) => [formatCurrency(val), '']}
            />
            <Area type="monotone" dataKey="gelir" stroke="#10B981" strokeWidth={2} fill="url(#incomeGrad)" name="Gelir" />
            <Area type="monotone" dataKey="gider" stroke="#EF4444" strokeWidth={2} fill="url(#expenseGrad)" name="Gider" />
          </AreaChart>
        </ResponsiveContainer>
      </GlassCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-5">
        {/* Pie Chart */}
        <GlassCard padding="p-5">
          <h3 className="text-white font-semibold mb-4">Gider Dağılımı</h3>
          {pieData.length > 0 ? (
            <ResponsiveContainer width="100%" height={200}>
              <PieChart>
                <Pie data={pieData} cx="50%" cy="50%" innerRadius={50} outerRadius={80} dataKey="value" paddingAngle={3}>
                  {pieData.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ background: 'rgba(15,15,30,0.9)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 12, fontSize: 12 }}
                  formatter={(val: number) => [formatCurrency(val), '']}
                />
                <Legend
                  formatter={(value) => <span style={{ color: 'rgba(255,255,255,0.6)', fontSize: 11 }}>{value}</span>}
                  iconType="circle" iconSize={8}
                />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-48 flex items-center justify-center text-white/30 text-sm">Bu ay için gider yok</div>
          )}
        </GlassCard>

        {/* Net Tasarruf */}
        <GlassCard padding="p-5" gradient={netSavings >= 0 ? 'green' : 'red'}>
          <h3 className="text-white font-semibold mb-3">Aylık Özet</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-white/60 text-sm">Toplam Gelir</span>
              <AmountText amount={income} type="income" className="text-sm font-semibold" showSign={false} />
            </div>
            <div className="flex justify-between items-center">
              <span className="text-white/60 text-sm">Toplam Gider</span>
              <AmountText amount={expense} type="expense" className="text-sm font-semibold" showSign={false} />
            </div>
            <div className="h-px bg-white/10" />
            <div className="flex justify-between items-center">
              <span className="text-white/80 text-sm font-semibold">Net Tasarruf</span>
              <span className={`text-base font-bold ${netSavings >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>
                {netSavings >= 0 ? '+' : ''}{formatCurrency(netSavings)}
              </span>
            </div>
            {/* Savings rate */}
            {income > 0 && (
              <div className="pt-2">
                <div className="flex justify-between text-xs text-white/40 mb-1">
                  <span>Tasarruf Oranı</span>
                  <span>{Math.round((netSavings / income) * 100)}%</span>
                </div>
                <div className="h-2 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${netSavings >= 0 ? 'bg-emerald-500' : 'bg-red-500'}`}
                    style={{ width: `${Math.max(0, Math.min(100, (netSavings / income) * 100))}%` }}
                  />
                </div>
              </div>
            )}
          </div>
        </GlassCard>
      </div>

      {/* Recent Transactions */}
      <GlassCard padding="p-5">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-white font-semibold">Son İşlemler</h3>
          <button
            onClick={() => navigate('/transactions')}
            className="flex items-center gap-1 text-violet-400 text-sm hover:text-violet-300"
          >
            Tümü <ArrowUpRight size={14} />
          </button>
        </div>
        <div className="space-y-3">
          {recentTxs.map(tx => {
            const cat = getCategoryById(tx.categoryId);
            return (
              <div key={tx.id} className="flex items-center gap-3">
                <CategoryIcon icon={cat?.icon || 'HelpCircle'} color={cat?.color || '#888'} size={16} />
                <div className="flex-1 min-w-0">
                  <p className="text-white text-sm font-medium truncate">{tx.title}</p>
                  <p className="text-white/40 text-xs">{cat?.name} · {new Date(tx.date).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' })}</p>
                </div>
                <AmountText
                  amount={tx.amount}
                  type={tx.type}
                  className="text-sm font-semibold flex-shrink-0"
                />
              </div>
            );
          })}
        </div>
      </GlassCard>

      {showAddModal && <AddTransactionModal onClose={() => setShowAddModal(false)} />}
    </div>
  );
}
