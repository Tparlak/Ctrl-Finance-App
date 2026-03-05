import {
  Utensils, Car, ShoppingBag, Receipt, Heart, Gamepad2,
  BookOpen, Briefcase, Laptop, TrendingUp, Home,
  ArrowLeftRight, Wallet, Building2, CreditCard, HelpCircle
} from 'lucide-react';

const ICON_MAP: Record<string, React.ElementType> = {
  Utensils, Car, ShoppingBag, Receipt, Heart, Gamepad2,
  BookOpen, Briefcase, Laptop, TrendingUp, Home,
  ArrowLeftRight, Wallet, Building2, CreditCard,
};

interface CategoryIconProps {
  icon: string;
  color: string;
  size?: number;
  className?: string;
}

export function CategoryIcon({ icon, color, size = 18, className = '' }: CategoryIconProps) {
  const IconComponent = ICON_MAP[icon] || HelpCircle;
  return (
    <div
      className={`rounded-xl flex items-center justify-center flex-shrink-0 ${className}`}
      style={{
        backgroundColor: color + '25',
        width: size * 2,
        height: size * 2,
      }}
    >
      <IconComponent size={size} style={{ color }} strokeWidth={2} />
    </div>
  );
}
