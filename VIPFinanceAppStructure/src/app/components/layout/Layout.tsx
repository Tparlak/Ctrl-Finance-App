import { Outlet } from 'react-router';
import { SideNavBar } from './SideNavBar';
import { BottomNavBar } from './BottomNavBar';
import { useFinance } from '../../store/financeStore';

export function Layout() {
  const { themeMode } = useFinance();

  return (
    <div className={`app-root ${themeMode}`}>
      <div className="flex min-h-screen">
        <SideNavBar />
        <main className="flex-1 overflow-y-auto pb-24 md:pb-0">
          <Outlet />
        </main>
      </div>
      <BottomNavBar />
    </div>
  );
}
