-- Drop tables if they exist to allow clean re-runs
DROP TABLE IF EXISTS asset_prices;
DROP TABLE IF EXISTS assets;
DROP TABLE IF EXISTS portfolios;
DROP TABLE IF EXISTS users;

-- 1. Users Table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    password_hash TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

-- 2. Portfolios Table
CREATE TABLE portfolios (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    currency TEXT NOT NULL DEFAULT 'USD',
    created_at INTEGER NOT NULL,
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. Assets Table (Holdings)
CREATE TABLE assets (
    id TEXT PRIMARY KEY,
    portfolio_id TEXT NOT NULL,
    symbol TEXT NOT NULL,
    name TEXT NOT NULL,
    quantity REAL NOT NULL,
    purchase_price REAL NOT NULL,
    purchase_date INTEGER NOT NULL,
    broker TEXT NOT NULL DEFAULT 'Other',
    FOREIGN KEY(portfolio_id) REFERENCES portfolios(id) ON DELETE CASCADE
);

-- 4. Historical Asset Prices Table
CREATE TABLE asset_prices (
    symbol TEXT NOT NULL,
    price_date TEXT NOT NULL,
    price REAL NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    created_at INTEGER NOT NULL,
    PRIMARY KEY (symbol, price_date)
);

-- Seed Initial Data for Demo/Development
INSERT INTO users (id, email, name, password_hash, created_at)
VALUES ('demo-user-123', 'demo@assetmaster.app', 'Chien', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 1716030000000);

INSERT INTO portfolios (id, user_id, name, description, currency, created_at)
VALUES ('demo-portfolio-abc', 'demo-user-123', 'My Primary Portfolio', 'Core stocks and crypto assets', 'USD', 1716030500000);

INSERT INTO assets (id, portfolio_id, symbol, name, quantity, purchase_price, purchase_date, broker)
VALUES ('asset-1', 'demo-portfolio-abc', 'AAPL', 'Apple Inc.', 15.0, 165.50, 1714030000000, 'Interactive Brokers');

INSERT INTO assets (id, portfolio_id, symbol, name, quantity, purchase_price, purchase_date, broker)
VALUES ('asset-2', 'demo-portfolio-abc', 'TSLA', 'Tesla Inc.', 8.0, 175.20, 1715030000000, 'Fidelity');

INSERT INTO assets (id, portfolio_id, symbol, name, quantity, purchase_price, purchase_date, broker)
VALUES ('asset-3', 'demo-portfolio-abc', 'BTC-USD', 'Bitcoin USD', 0.25, 62450.00, 1715530000000, 'Robinhood');

INSERT INTO assets (id, portfolio_id, symbol, name, quantity, purchase_price, purchase_date, broker)
VALUES ('asset-4', 'demo-portfolio-abc', 'AAPL', 'Apple Inc.', 5.0, 170.00, 1714530000000, 'Robinhood');
