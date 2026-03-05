import { createBrowserRouter } from 'react-router';
import { Layout } from './components/layout/Layout';
import Dashboard from './screens/Dashboard';
import Accounts from './screens/Accounts';
import Transactions from './screens/Transactions';
import ControlCenter from './screens/ControlCenter';

export const router = createBrowserRouter([
  {
    path: '/',
    Component: Layout,
    children: [
      { index: true, Component: Dashboard },
      { path: 'accounts', Component: Accounts },
      { path: 'transactions', Component: Transactions },
      { path: 'control', Component: ControlCenter },
    ],
  },
]);
