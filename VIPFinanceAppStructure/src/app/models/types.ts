export type AccountType = 'bank' | 'cash' | 'credit' | 'investment' | 'savings';
export type TransactionType = 'income' | 'expense' | 'transfer';
export type ThemeMode = 'dark' | 'light';

export interface Account {
  id: string;
  name: string;
  type: AccountType;
  balance: number;
  currency: string;
  color: string;
  icon: string;
  bankName?: string;
  lastFourDigits?: string;
  createdAt: string;
}

export interface Category {
  id: string;
  name: string;
  icon: string;
  color: string;
  type: TransactionType;
}

export interface Transaction {
  id: string;
  title: string;
  amount: number;
  type: TransactionType;
  categoryId: string;
  accountId: string;
  toAccountId?: string;
  date: string;
  note?: string;
  tags?: string[];
}

export interface Budget {
  id: string;
  categoryId: string;
  amount: number;
  spent: number;
  period: 'monthly' | 'weekly' | 'yearly';
}
