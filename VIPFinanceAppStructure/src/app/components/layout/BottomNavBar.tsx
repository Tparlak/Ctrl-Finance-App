import { useLocation, useNavigate } from 'react-router';
import { LayoutDashboard, Wallet, ArrowUpDown, Settings } from 'lucide-react';

const NAV_ITEMS = [
  { path: '/', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/accounts', label: 'Hesaplar', icon: Wallet },
  { path: '/transactions', label: 'İşlemler', icon: ArrowUpDown },
  { path: '/control', label: 'Kontrol', icon: Settings },
];

export function BottomNavBar() {
  const location = useLocation();
  const navigate = useNavigate();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 safe-bottom md:hidden">
      <div className="glass-nav mx-3 mb-3 rounded-2xl px-2 py-2">
        <div className="flex items-center justify-around">
          {NAV_ITEMS.map(({ path, label, icon: Icon }) => {
            const isActive = location.pathname === path;
            return (
              <button
                key={path}
                onClick={() => navigate(path)}
                className={`flex flex-col items-center gap-1 px-4 py-2 rounded-xl transition-all duration-200 ${
                  isActive
                    ? 'bg-white/20 text-white'
                    : 'text-white/50 hover:text-white/80'
                }`}
              >
                <Icon size={20} strokeWidth={isActive ? 2.5 : 1.8} />
                <span className="text-[10px] font-medium tracking-wide">{label}</span>
              </button>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
