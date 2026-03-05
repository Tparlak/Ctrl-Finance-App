interface AmountTextProps {
  amount: number;
  type?: 'income' | 'expense' | 'transfer' | 'neutral';
  currency?: string;
  className?: string;
  showSign?: boolean;
}

export function formatCurrency(amount: number, currency = 'TRY'): string {
  return new Intl.NumberFormat('tr-TR', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(Math.abs(amount));
}

export function AmountText({
  amount, type = 'neutral', currency = 'TRY', className = '', showSign = true
}: AmountTextProps) {
  const colorMap = {
    income: 'text-emerald-400',
    expense: 'text-red-400',
    transfer: 'text-blue-400',
    neutral: amount < 0 ? 'text-red-400' : 'text-white',
  };

  const sign = showSign ? (type === 'income' ? '+' : type === 'expense' ? '-' : '') : '';
  const color = colorMap[type];

  return (
    <span className={`${color} ${className}`}>
      {sign}{formatCurrency(amount, currency)}
    </span>
  );
}
