export interface User {
  id: string
  email: string
  name?: string
  password_hash?: string
  created_at: number
}

export interface Portfolio {
  id: string
  user_id: string
  name: string
  currency: string
  description?: string
  created_at: number
}

export interface Asset {
  id: string
  portfolio_id: string
  symbol: string
  name: string
  quantity: number
  purchase_price: number
  purchase_date: number
  broker: string
}

export interface StockPrice {
  symbol: string
  price: number
  currency: string
  previousClose: number
  timestamp: number
}

export interface HoldingValuation {
  id: string
  symbol: string
  name: string
  quantity: number
  purchaseDate: number
  purchasePrice: number
  convertedPurchasePrice: number
  currentPrice: number
  convertedCurrentPrice: number
  costBasis: number
  currentValue: number
  profitLoss: number
  profitLossPercentage: number
  currency: string
  previousClose: number
  convertedPreviousClose: number
  weightPercentage: number
  broker: string
}

export interface PortfolioValuation {
  portfolioId: string
  currency: string
  totalCostBasis: number
  totalCurrentValue: number
  totalProfitLoss: number
  totalProfitLossPercentage: number
  holdings: HoldingValuation[]
}

export interface TrendDataPoint {
  date: string
  value: number
}
