export interface Env {
  DB: D1Database;
}

export interface User {
  id: string;
  email: string;
  name?: string;
  created_at: number;
}

export interface Portfolio {
  id: string;
  user_id: string;
  name: string;
  currency: string;
  description?: string;
  created_at: number;
}

export interface Asset {
  id: string;
  portfolio_id: string;
  symbol: string;
  name: string;
  quantity: number;
  purchase_price: number;
  purchase_date: number;
  broker: string;
}

export interface StockPrice {
  symbol: string;
  price: number;
  currency: string;
  previousClose: number;
  timestamp: number;
}
