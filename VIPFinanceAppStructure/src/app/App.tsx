import { RouterProvider } from 'react-router';
import { router } from './routes';
import { FinanceProvider } from './store/financeStore';

export default function App() {
  return (
    <FinanceProvider>
      <RouterProvider router={router} />
    </FinanceProvider>
  );
}
