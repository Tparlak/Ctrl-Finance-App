import { useState } from 'react';
import {
  Moon, Sun, Bell, Shield, ChevronRight, Palette, Globe,
  Download, Trash2, HelpCircle, Star, Info, Database,
  TrendingUp, PiggyBank
} from 'lucide-react';
import { useFinance } from '../store/financeStore';
import { GlassCard } from '../components/shared/GlassCard';
import { CategoryIcon } from '../components/shared/CategoryIcon';
import { formatCurrency } from '../components/shared/AmountText';

function ToggleSwitch({ checked, onChange }: { checked: boolean; onChange: () => void }) {
  return (
    <button
      onClick={onChange}
      className={`relative w-11 h-6 rounded-full transition-all duration-300 ${checked ? 'bg-violet-600' : 'bg-white/20'}`}
    >
      <span className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow-sm transition-all duration-300 ${checked ? 'left-[22px]' : 'left-0.5'}`} />
    </button>
  );
}

function SettingRow({ icon: Icon, label, sub, action, color = '#8B5CF6' }: {
  icon: React.ElementType; label: string; sub?: string; action: React.ReactNode; color?: string;
}) {
  return (
    <div className="flex items-center gap-3 py-3.5 border-b border-white/5 last:border-0">
      <div className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0" style={{ backgroundColor: color + '25' }}>
        <Icon size={15} style={{ color }} />
      </div>
      <div className="flex-1">
        <p className="text-white text-sm font-medium">{label}</p>
        {sub && <p className="text-white/40 text-xs">{sub}</p>}
      </div>
      {action}
    </div>
  );
}

export default function ControlCenter() {
  const { themeMode, toggleTheme, transactions, accounts, categories, budgets } = useFinance();
  const [notifications, setNotifications] = useState(true);
  const [biometric, setBiometric] = useState(false);
  const [currency, setCurrency] = useState('TRY');

  const totalTxCount = transactions.length;
  const totalBalance = accounts.reduce((s, a) => s + a.balance, 0);

  return (
    <div className="min-h-screen px-4 pt-6 pb-6 md:px-8 md:pt-8">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-white text-xl font-bold">Kontrol Merkezi</h1>
        <p className="text-white/40 text-sm">Uygulama ayarları ve tercihleri</p>
      </div>

      {/* Profile Card */}
      <GlassCard gradient="violet" className="mb-5" padding="p-5">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-violet-400 to-pink-400 flex items-center justify-center text-white text-xl font-bold shadow-lg">
            VK
          </div>
          <div className="flex-1">
            <h2 className="text-white font-bold text-lg">VIP Kullanıcı</h2>
            <p className="text-white/50 text-sm">vip@finans.com</p>
            <div className="flex items-center gap-1.5 mt-1">
              <Star size={12} className="text-amber-400 fill-amber-400" />
              <span className="text-amber-400 text-xs font-medium">Premium Plan</span>
            </div>
          </div>
          <button className="glass-btn px-3 py-1.5 rounded-xl text-white/70 text-sm hover:text-white">
            Düzenle
          </button>
        </div>
      </GlassCard>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3 mb-5">
        <GlassCard padding="p-3" className="text-center">
          <p className="text-white font-bold text-lg">{accounts.length}</p>
          <p className="text-white/40 text-xs">Hesap</p>
        </GlassCard>
        <GlassCard padding="p-3" className="text-center">
          <p className="text-white font-bold text-lg">{totalTxCount}</p>
          <p className="text-white/40 text-xs">İşlem</p>
        </GlassCard>
        <GlassCard padding="p-3" className="text-center">
          <p className="text-white font-bold text-lg">{categories.length}</p>
          <p className="text-white/40 text-xs">Kategori</p>
        </GlassCard>
      </div>

      {/* Appearance */}
      <GlassCard className="mb-4" padding="px-5 py-4">
        <p className="text-white/50 text-xs font-semibold uppercase tracking-widest mb-3">Görünüm</p>
        <SettingRow
          icon={themeMode === 'dark' ? Moon : Sun}
          label="Karanlık Mod"
          sub={themeMode === 'dark' ? 'Aktif' : 'Pasif'}
          color={themeMode === 'dark' ? '#8B5CF6' : '#F59E0B'}
          action={<ToggleSwitch checked={themeMode === 'dark'} onChange={toggleTheme} />}
        />
        <SettingRow
          icon={Palette}
          label="Tema Rengi"
          sub="Mor (Varsayılan)"
          color="#8B5CF6"
          action={
            <div className="flex gap-1.5">
              {['#8B5CF6', '#3B82F6', '#10B981', '#F59E0B', '#EF4444'].map(c => (
                <div key={c} className={`w-4 h-4 rounded-full cursor-pointer ${c === '#8B5CF6' ? 'ring-2 ring-white/60 ring-offset-1 ring-offset-transparent' : ''}`} style={{ backgroundColor: c }} />
              ))}
            </div>
          }
        />
        <SettingRow
          icon={Globe}
          label="Para Birimi"
          sub="Türk Lirası"
          color="#3B82F6"
          action={
            <button className="flex items-center gap-1 text-white/50 text-sm">
              TRY <ChevronRight size={14} />
            </button>
          }
        />
      </GlassCard>

      {/* Notifications */}
      <GlassCard className="mb-4" padding="px-5 py-4">
        <p className="text-white/50 text-xs font-semibold uppercase tracking-widest mb-3">Bildirimler & Güvenlik</p>
        <SettingRow
          icon={Bell}
          label="Bildirimler"
          sub="İşlem uyarıları"
          color="#F59E0B"
          action={<ToggleSwitch checked={notifications} onChange={() => setNotifications(v => !v)} />}
        />
        <SettingRow
          icon={Shield}
          label="Biyometrik Kilit"
          sub="Parmak izi / Yüz tanıma"
          color="#10B981"
          action={<ToggleSwitch checked={biometric} onChange={() => setBiometric(v => !v)} />}
        />
      </GlassCard>

      {/* Budgets Section */}
      <GlassCard className="mb-4" padding="p-5">
        <div className="flex items-center justify-between mb-4">
          <p className="text-white font-semibold">Bütçe Takibi</p>
          <TrendingUp size={16} className="text-violet-400" />
        </div>
        <div className="space-y-3">
          {budgets.map(b => {
            const cat = categories.find(c => c.id === b.categoryId);
            const pct = Math.min(100, (b.spent / b.amount) * 100);
            const over = b.spent > b.amount;
            return (
              <div key={b.id}>
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-2">
                    <CategoryIcon icon={cat?.icon || 'HelpCircle'} color={cat?.color || '#888'} size={12} className="!w-6 !h-6" />
                    <span className="text-white text-xs">{cat?.name}</span>
                  </div>
                  <span className={`text-xs font-semibold ${over ? 'text-red-400' : 'text-white/60'}`}>
                    {formatCurrency(b.spent)} / {formatCurrency(b.amount)}
                  </span>
                </div>
                <div className="h-1.5 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${over ? 'bg-red-500' : 'bg-violet-500'}`}
                    style={{ width: `${pct}%` }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </GlassCard>

      {/* Data */}
      <GlassCard className="mb-4" padding="px-5 py-4">
        <p className="text-white/50 text-xs font-semibold uppercase tracking-widest mb-3">Veri ve Yedekleme</p>
        <SettingRow
          icon={Download}
          label="Veriyi Dışa Aktar"
          sub="CSV / PDF formatında"
          color="#06B6D4"
          action={<ChevronRight size={16} className="text-white/30" />}
        />
        <SettingRow
          icon={Database}
          label="Yedekleme"
          sub="Buluta yedekle"
          color="#8B5CF6"
          action={<ChevronRight size={16} className="text-white/30" />}
        />
        <SettingRow
          icon={Trash2}
          label="Tüm Verileri Sil"
          sub="Bu işlem geri alınamaz"
          color="#EF4444"
          action={<ChevronRight size={16} className="text-white/30" />}
        />
      </GlassCard>

      {/* About */}
      <GlassCard padding="px-5 py-4">
        <p className="text-white/50 text-xs font-semibold uppercase tracking-widest mb-3">Hakkında</p>
        <SettingRow
          icon={HelpCircle}
          label="Yardım & Destek"
          sub="SSS ve iletişim"
          color="#6B7280"
          action={<ChevronRight size={16} className="text-white/30" />}
        />
        <SettingRow
          icon={Star}
          label="Uygulamayı Oyla"
          sub="Görüşlerinizi paylaşın"
          color="#F59E0B"
          action={<ChevronRight size={16} className="text-white/30" />}
        />
        <SettingRow
          icon={Info}
          label="Sürüm"
          sub="VIP Finance v2.0.0"
          color="#4B5563"
          action={<span className="text-white/30 text-xs">Güncel</span>}
        />
      </GlassCard>
    </div>
  );
}