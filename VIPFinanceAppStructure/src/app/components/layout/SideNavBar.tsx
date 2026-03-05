import { useLocation, useNavigate } from 'react-router';
import { LayoutDashboard, Wallet, ArrowUpDown, Settings, Gem } from 'lucide-react';

const NAV_ITEMS = [
  { path: '/', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/accounts', label: 'Hesaplar', icon: Wallet },
  { path: '/transactions', label: 'İşlemler', icon: ArrowUpDown },
  { path: '/control', label: 'Kontrol Merkezi', icon: Settings },
];

export function SideNavBar() {
  const location = useLocation();
  const navigate = useNavigate();

  return (
    <aside className="hidden md:flex flex-col w-64 min-h-screen glass-sidebar border-r border-white/10 p-6">
      {/* Logo */}
      <div className="flex items-center gap-3 mb-10">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-violet-500 to-indigo-600 flex items-center justify-center shadow-lg">
          <Gem size={20} className="text-white" />
        </div>
        <div>
          <p className="text-white font-bold tracking-wide">VIP Finance</p>
          <p className="text-white/40 text-xs">Kişisel Finans</p>
        </div>
      </div>

      {/* Nav Items */}
      <nav className="flex flex-col gap-1 flex-1">
        {NAV_ITEMS.map(({ path, label, icon: Icon }) => {
          const isActive = location.pathname === path;
          return (
            <button
              key={path}
              onClick={() => navigate(path)}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl text-left transition-all duration-200 ${
                isActive
                  ? 'bg-white/15 text-white shadow-sm border border-white/10'
                  : 'text-white/50 hover:text-white hover:bg-white/8'
              }`}
            >
              <Icon size={18} strokeWidth={isActive ? 2.5 : 1.8} />
              <span className="text-sm font-medium">{label}</span>
              {isActive && (
                <div className="ml-auto w-1.5 h-1.5 rounded-full bg-violet-400" />
              )}
            </button>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="pt-6 border-t border-white/10">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-violet-400 to-pink-400 flex items-center justify-center text-white text-xs font-bold">
            VK
          </div>
          <div>
            <p className="text-white text-sm font-medium">VIP Kullanıcı</p>
            <p className="text-white/40 text-xs">Premium Plan</p>
          </div>
        </div>
      </div>
    </aside>
  );
}
