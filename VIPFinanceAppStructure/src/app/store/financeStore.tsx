import React, { createContext, useContext, useState, useCallback } from 'react';
import type { Account, Transaction, Category, Budget, ThemeMode } from '../models/types';

// ─── Mock Data ───────────────────────────────────────────────────────────────

const INITIAL_CATEGORIES: Category[] = [
  { id: 'c1', name: 'Yemek', icon: 'Utensils', color: '#FF6B6B', type: 'expense' },
  { id: 'c2', name: 'Ulaşım', icon: 'Car', color: '#4ECDC4', type: 'expense' },
  { id: 'c3', name: 'Alışveriş', icon: 'ShoppingBag', color: '#A855F7', type: 'expense' },
  { id: 'c4', name: 'Fatura', icon: 'Receipt', color: '#F59E0B', type: 'expense' },
  { id: 'c5', name: 'Sağlık', icon: 'Heart', color: '#EF4444', type: 'expense' },
  { id: 'c6', name: 'Eğlence', icon: 'Gamepad2', color: '#8B5CF6', type: 'expense' },
  { id: 'c7', name: 'Eğitim', icon: 'BookOpen', color: '#3B82F6', type: 'expense' },
  { id: 'c8', name: 'Maaş', icon: 'Briefcase', color: '#10B981', type: 'income' },
  { id: 'c9', name: 'Freelance', icon: 'Laptop', color: '#06B6D4', type: 'income' },
  { id: 'c10', name: 'Yatırım', icon: 'TrendingUp', color: '#22C55E', type: 'income' },
  { id: 'c11', name: 'Kira', icon: 'Home', color: '#F97316', type: 'expense' },
  { id: 'c12', name: 'Transfer', icon: 'ArrowLeftRight', color: '#94A3B8', type: 'transfer' },
];

const INITIAL_ACCOUNTS: Account[] = [
  {
    id: 'a1', name: 'Garanti Bankası', type: 'bank', balance: 24750.50,
    currency: 'TRY', color: '#10B981', icon: 'Building2',
    bankName: 'Garanti BBVA', lastFourDigits: '4521', createdAt: '2024-01-01',
  },
  {
    id: 'a2', name: 'Ziraat Bankası', type: 'bank', balance: 8320.00,
    currency: 'TRY', color: '#3B82F6', icon: 'Building2',
    bankName: 'Ziraat Bankası', lastFourDigits: '7890', createdAt: '2024-01-01',
  },
  {
    id: 'a3', name: 'Nakit', type: 'cash', balance: 1200.00,
    currency: 'TRY', color: '#F59E0B', icon: 'Wallet', createdAt: '2024-01-01',
  },
  {
    id: 'a4', name: 'Kredi Kartı', type: 'credit', balance: -3450.75,
    currency: 'TRY', color: '#EF4444', icon: 'CreditCard',
    bankName: 'Akbank', lastFourDigits: '1234', createdAt: '2024-01-01',
  },
  {
    id: 'a5', name: 'Yatırım Hesabı', type: 'investment', balance: 45600.00,
    currency: 'TRY', color: '#8B5CF6', icon: 'TrendingUp',
    bankName: 'İş Yatırım', createdAt: '2024-01-01',
  },
];

const INITIAL_TRANSACTIONS: Transaction[] = [
  { id: 't1', title: 'Migros Market', amount: 450.30, type: 'expense', categoryId: 'c1', accountId: 'a1', date: '2026-03-05', note: 'Haftalık alışveriş' },
  { id: 't2', title: 'Şubat Maaşı', amount: 18500, type: 'income', categoryId: 'c8', accountId: 'a1', date: '2026-03-01' },
  { id: 't3', title: 'Metro Kartı', amount: 200, type: 'expense', categoryId: 'c2', accountId: 'a1', date: '2026-03-04' },
  { id: 't4', title: 'Netflix', amount: 149.99, type: 'expense', categoryId: 'c6', accountId: 'a4', date: '2026-03-03' },
  { id: 't5', title: 'Elektrik Faturası', amount: 380, type: 'expense', categoryId: 'c4', accountId: 'a1', date: '2026-03-02' },
  { id: 't6', title: 'Freelance Proje', amount: 5000, type: 'income', categoryId: 'c9', accountId: 'a1', date: '2026-02-28' },
  { id: 't7', title: 'Trendyol', amount: 1250.60, type: 'expense', categoryId: 'c3', accountId: 'a4', date: '2026-02-27' },
  { id: 't8', title: 'Eczane', amount: 95, type: 'expense', categoryId: 'c5', accountId: 'a3', date: '2026-02-26' },
  { id: 't9', title: 'Udemy Kursu', amount: 450, type: 'expense', categoryId: 'c7', accountId: 'a1', date: '2026-02-25' },
  { id: 't10', title: 'Kira', amount: 8000, type: 'expense', categoryId: 'c11', accountId: 'a1', date: '2026-02-25' },
  { id: 't11', title: 'Borsa Temettü', amount: 2300, type: 'income', categoryId: 'c10', accountId: 'a5', date: '2026-02-24' },
  { id: 't12', title: 'Restoran', amount: 780, type: 'expense', categoryId: 'c1', accountId: 'a4', date: '2026-02-23' },
  { id: 't13', title: 'Transfer', amount: 2000, type: 'transfer', categoryId: 'c12', accountId: 'a1', toAccountId: 'a3', date: '2026-02-22' },
  { id: 't14', title: 'Su Faturası', amount: 95, type: 'expense', categoryId: 'c4', accountId: 'a1', date: '2026-02-21' },
  { id: 't15', title: 'Benzin', amount: 600, type: 'expense', categoryId: 'c2', accountId: 'a3', date: '2026-02-20' },
  { id: 't16', title: 'Ocak Maaşı', amount: 18500, type: 'income', categoryId: 'c8', accountId: 'a1', date: '2026-02-01' },
  { id: 't17', title: 'AVM Alışveriş', amount: 2100, type: 'expense', categoryId: 'c3', accountId: 'a4', date: '2026-01-28' },
  { id: 't18', title: 'Spotify', amount: 39.99, type: 'expense', categoryId: 'c6', accountId: 'a4', date: '2026-01-15' },
];

const INITIAL_BUDGETS: Budget[] = [
  { id: 'b1', categoryId: 'c1', amount: 2000, spent: 1230.30, period: 'monthly' },
  { id: 'b2', categoryId: 'c2', amount: 1000, spent: 800, period: 'monthly' },
  { id: 'b3', categoryId: 'c3', amount: 3000, spent: 3350.60, period: 'monthly' },
  { id: 'b4', categoryId: 'c4', amount: 1500, spent: 475, period: 'monthly' },
  { id: 'b5', categoryId: 'c6', amount: 500, spent: 188.99, period: 'monthly' },
];

// ─── Context ──────────────────────────────────────────────────────────────────

interface FinanceState {
  accounts: Account[];
  transactions: Transaction[];
  categories: Category[];
  budgets: Budget[];
  themeMode: ThemeMode;
  selectedMonth: string; // 'YYYY-MM'
}

interface FinanceActions {
  addAccount: (account: Account) => void;
  updateAccount: (account: Account) => void;
  deleteAccount: (id: string) => void;
  addTransaction: (tx: Transaction) => void;
  deleteTransaction: (id: string) => void;
  addCategory: (cat: Category) => void;
  toggleTheme: () => void;
  setSelectedMonth: (month: string) => void;
  getTotalBalance: () => number;
  getMonthlyIncome: (month: string) => number;
  getMonthlyExpense: (month: string) => number;
  getCategoryById: (id: string) => Category | undefined;
  getAccountById: (id: string) => Account | undefined;
}

type FinanceContextType = FinanceState & FinanceActions;

const FinanceContext = createContext<FinanceContextType | null>(null);

export function FinanceProvider({ children }: { children: React.ReactNode }) {
  const [accounts, setAccounts] = useState<Account[]>(INITIAL_ACCOUNTS);
  const [transactions, setTransactions] = useState<Transaction[]>(INITIAL_TRANSACTIONS);
  const [categories] = useState<Category[]>(INITIAL_CATEGORIES);
  const [budgets] = useState<Budget[]>(INITIAL_BUDGETS);
  const [themeMode, setThemeMode] = useState<ThemeMode>('dark');
  const [selectedMonth, setSelectedMonth] = useState<string>('2026-03');

  const addAccount = useCallback((account: Account) => {
    setAccounts(prev => [...prev, account]);
  }, []);

  const updateAccount = useCallback((account: Account) => {
    setAccounts(prev => prev.map(a => a.id === account.id ? account : a));
  }, []);

  const deleteAccount = useCallback((id: string) => {
    setAccounts(prev => prev.filter(a => a.id !== id));
  }, []);

  const addTransaction = useCallback((tx: Transaction) => {
    setTransactions(prev => [tx, ...prev]);
    // Update account balance
    setAccounts(prev => prev.map(a => {
      if (a.id === tx.accountId) {
        const delta = tx.type === 'income' ? tx.amount : -tx.amount;
        return { ...a, balance: a.balance + delta };
      }
      if (tx.toAccountId && a.id === tx.toAccountId) {
        return { ...a, balance: a.balance + tx.amount };
      }
      return a;
    }));
  }, []);

  const deleteTransaction = useCallback((id: string) => {
    setTransactions(prev => prev.filter(t => t.id !== id));
  }, []);

  const addCategory = useCallback((cat: Category) => {
    // categories is not updatable in this mock, but in real app it would be
  }, []);

  const toggleTheme = useCallback(() => {
    setThemeMode(prev => prev === 'dark' ? 'light' : 'dark');
  }, []);

  const getTotalBalance = useCallback(() => {
    return accounts.reduce((sum, a) => sum + a.balance, 0);
  }, [accounts]);

  const getMonthlyIncome = useCallback((month: string) => {
    return transactions
      .filter(t => t.date.startsWith(month) && t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
  }, [transactions]);

  const getMonthlyExpense = useCallback((month: string) => {
    return transactions
      .filter(t => t.date.startsWith(month) && t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
  }, [transactions]);

  const getCategoryById = useCallback((id: string) => {
    return categories.find(c => c.id === id);
  }, [categories]);

  const getAccountById = useCallback((id: string) => {
    return accounts.find(a => a.id === id);
  }, [accounts]);

  return (
    <FinanceContext.Provider value={{
      accounts, transactions, categories, budgets, themeMode, selectedMonth,
      addAccount, updateAccount, deleteAccount,
      addTransaction, deleteTransaction, addCategory,
      toggleTheme, setSelectedMonth,
      getTotalBalance, getMonthlyIncome, getMonthlyExpense,
      getCategoryById, getAccountById,
    }}>
      {children}
    </FinanceContext.Provider>
  );
}

export function useFinance() {
  const ctx = useContext(FinanceContext);
  if (!ctx) throw new Error('useFinance must be used within FinanceProvider');
  return ctx;
}
