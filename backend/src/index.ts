import { Env, Asset, Portfolio } from './types';
import { fetchStockPrices, getHistoricalPrices } from './stocks';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
};

// Helper for sending structured JSON responses
function jsonResponse(data: any, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

// Handler for CORS preflight options
function handleOptions(): Response {
  return new Response(null, {
    status: 204,
    headers: corsHeaders,
  });
}

// Extract authenticated user_id from Bearer token
function getUserId(request: Request): string {
  const authHeader = request.headers.get('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return authHeader.substring(7);
  }
  return 'demo-user-123'; // Default fallback
}

// Secure standard Edge-native password hashing via Web Crypto API
async function hashPassword(password: string): Promise<string> {
  const msgBuffer = new TextEncoder().encode(password);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const { pathname, searchParams } = url;
    const method = request.method;

    // 1. Handle CORS Preflight Requests
    if (method === 'OPTIONS') {
      return handleOptions();
    }

    try {
      // ----------------------------------------------------
      // ROUTE: POST /api/auth/register
      // ----------------------------------------------------
      if (pathname === '/api/auth/register' && method === 'POST') {
        const body: any = await request.json().catch(() => ({}));
        const { email, name, password } = body;

        if (!email || !name || !password) {
          return jsonResponse({ error: 'Missing required fields: email, name, password' }, 400);
        }

        const emailLower = email.toLowerCase().trim();

        // Check if user already exists
        const existingUser = await env.DB.prepare(
          'SELECT * FROM users WHERE email = ?'
        ).bind(emailLower).first();

        if (existingUser) {
          return jsonResponse({ error: 'Email is already registered' }, 400);
        }

        const userId = crypto.randomUUID();
        const passwordHash = await hashPassword(password);
        const createdAt = Date.now();

        // Insert new user
        await env.DB.prepare(
          'INSERT INTO users (id, email, name, password_hash, created_at) VALUES (?, ?, ?, ?, ?)'
        ).bind(userId, emailLower, name.trim(), passwordHash, createdAt).run();

        // Auto-create a starting default portfolio for visual completeness
        const portfolioId = crypto.randomUUID();
        await env.DB.prepare(
          'INSERT INTO portfolios (id, user_id, name, description, currency, created_at) VALUES (?, ?, ?, ?, ?, ?)'
        ).bind(portfolioId, userId, 'My Wealth', 'Core stock and crypto ledger', 'USD', createdAt).run();

        return jsonResponse({
          success: true,
          token: userId,
          user: { id: userId, email: emailLower, name: name.trim() }
        }, 201);
      }

      // ----------------------------------------------------
      // ROUTE: POST /api/auth/login
      // ----------------------------------------------------
      if (pathname === '/api/auth/login' && method === 'POST') {
        const body: any = await request.json().catch(() => ({}));
        const { email, password } = body;

        if (!email || !password) {
          return jsonResponse({ error: 'Missing email or password' }, 400);
        }

        const emailLower = email.toLowerCase().trim();
        const user: any = await env.DB.prepare(
          'SELECT * FROM users WHERE email = ?'
        ).bind(emailLower).first();

        if (!user) {
          return jsonResponse({ error: 'Invalid email or password' }, 401);
        }

        const inputHash = await hashPassword(password);
        console.log("[Login] Email: ", email, "Hashed Password: ", inputHash);
        console.log("[Login] User Password: ", user.password_hash);
        if (user.password_hash !== inputHash) {
          return jsonResponse({ error: 'Invalid email or password' }, 401);
        }

        return jsonResponse({
          success: true,
          token: user.id,
          user: { id: user.id, email: user.email, name: user.name }
        });
      }

      // ----------------------------------------------------
      // ROUTE: GET /api/stocks/search
      // Search stock/crypto tickers from Yahoo Autocomplete
      // ----------------------------------------------------
      if (pathname === '/api/stocks/search' && method === 'GET') {
        const query = searchParams.get('q');
        if (!query) {
          return jsonResponse({ error: 'Missing required query parameter "q"' }, 400);
        }

        const yahooUrl = `https://query2.finance.yahoo.com/v1/finance/search?q=${encodeURIComponent(query)}&quotesCount=8`;
        try {
          const res = await fetch(yahooUrl, {
            headers: {
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
              'Accept': 'application/json'
            }
          });

          if (!res.ok) {
            throw new Error(`Yahoo Search HTTP Error: ${res.status}`);
          }

          const data: any = await res.json();
          const quotes = (data?.quotes || []).map((q: any) => ({
            symbol: q.symbol,
            name: q.shortname || q.longname || q.name || q.symbol,
            exchange: q.exchange,
            type: q.typeDisp || q.quoteType || 'Unknown'
          }));

          return jsonResponse({ success: true, results: quotes });
        } catch (e: any) {
          console.error('[Yahoo Search Error]:', e);
          return jsonResponse({ error: 'Failed to search asset from Yahoo', details: e.message }, 502);
        }
      }

      // ----------------------------------------------------
      // ROUTE: GET /api/stocks
      // Fetch edge-cached stock/crypto prices from Yahoo
      // ----------------------------------------------------
      if (pathname === '/api/stocks' && method === 'GET') {
        const symbolsParam = searchParams.get('symbols');
        if (!symbolsParam) {
          return jsonResponse({ error: 'Missing required query parameter "symbols"' }, 400);
        }
        const symbols = symbolsParam.split(',').map(s => s.trim()).filter(Boolean);
        if (symbols.length === 0) {
          return jsonResponse({ error: 'Invalid or empty symbols parameter' }, 400);
        }

        const prices = await fetchStockPrices(symbols, ctx);
        return jsonResponse({ success: true, prices });
      }

      // ----------------------------------------------------
      // ROUTE: GET /api/portfolios
      // Fetch portfolios for the logged-in user
      // ----------------------------------------------------
      if (pathname === '/api/portfolios' && method === 'GET') {
        const userId = getUserId(request);

        const { results } = await env.DB.prepare(
          'SELECT * FROM portfolios WHERE user_id = ? ORDER BY name ASC'
        ).bind(userId).all<Portfolio>();

        return jsonResponse({ success: true, portfolios: results });
      }

      // ----------------------------------------------------
      // ROUTE: POST /api/portfolios
      // Create a new portfolio
      // ----------------------------------------------------
      if (pathname === '/api/portfolios' && method === 'POST') {
        const body: any = await request.json().catch(() => ({}));
        const { name, description, currency } = body;

        if (!name) {
          return jsonResponse({ error: 'Portfolio name is required' }, 400);
        }

        const userId = getUserId(request);
        const id = crypto.randomUUID();
        const createdAt = Date.now();
        const portCurrency = currency || 'USD';

        await env.DB.prepare(
          'INSERT INTO portfolios (id, user_id, name, description, currency, created_at) VALUES (?, ?, ?, ?, ?, ?)'
        ).bind(id, userId, name, description || '', portCurrency, createdAt).run();

        return jsonResponse({
          success: true,
          portfolio: { id, user_id: userId, name, description, currency: portCurrency, created_at: createdAt }
        }, 201);
      }

      // ----------------------------------------------------
      // ROUTE: PUT /api/portfolios/:id
      // Update portfolio details (specifically base currency)
      // ----------------------------------------------------
      const portfolioUpdateMatch = pathname.match(/^\/api\/portfolios\/([a-zA-Z0-9-]+)$/);
      if (portfolioUpdateMatch && method === 'PUT') {
        const portfolioId = portfolioUpdateMatch[1];
        const body: any = await request.json().catch(() => ({}));
        const { name, description, currency } = body;

        const userId = getUserId(request);

        // Verify the portfolio exists and belongs to the user
        const existing = await env.DB.prepare(
          'SELECT * FROM portfolios WHERE id = ? AND user_id = ?'
        ).bind(portfolioId, userId).first<Portfolio>();

        if (!existing) {
          return jsonResponse({ error: 'Portfolio not found or unauthorized' }, 404);
        }

        const newName = name || existing.name;
        const newDesc = description !== undefined ? description : existing.description;
        const newCurrency = currency || existing.currency;

        await env.DB.prepare(
          'UPDATE portfolios SET name = ?, description = ?, currency = ? WHERE id = ?'
        ).bind(newName, newDesc, newCurrency.toUpperCase(), portfolioId).run();

        return jsonResponse({
          success: true,
          portfolio: {
            id: portfolioId,
            user_id: userId,
            name: newName,
            description: newDesc,
            currency: newCurrency.toUpperCase(),
            created_at: existing.created_at
          }
        });
      }

      // ----------------------------------------------------
      // ROUTE: GET /api/portfolios/:id/assets
      // Get all assets/holdings in a portfolio (newest first)
      // ----------------------------------------------------
      const assetListMatch = pathname.match(/^\/api\/portfolios\/([a-zA-Z0-9-]+)\/assets$/);
      if (assetListMatch && method === 'GET') {
        const portfolioId = assetListMatch[1];
        const brokerParam = searchParams.get('broker');

        let queryStr = 'SELECT * FROM assets WHERE portfolio_id = ?';
        const queryParams: any[] = [portfolioId];

        if (brokerParam && brokerParam !== 'All') {
          queryStr += ' AND broker = ?';
          queryParams.push(brokerParam);
        }

        queryStr += ' ORDER BY purchase_date DESC';

        const { results } = await env.DB.prepare(queryStr)
          .bind(...queryParams)
          .all<Asset>();

        return jsonResponse({ success: true, assets: results });
      }

      // ----------------------------------------------------
      // ROUTE: POST /api/assets
      // Add a holding to a portfolio
      // ----------------------------------------------------
      if (pathname === '/api/assets' && method === 'POST') {
        const body: any = await request.json().catch(() => ({}));
        const { portfolio_id, symbol, name, quantity, purchase_price, purchase_date, broker } = body;

        if (!portfolio_id || !symbol || !name || quantity === undefined || purchase_price === undefined) {
          return jsonResponse({ error: 'Missing required body fields: portfolio_id, symbol, name, quantity, purchase_price' }, 400);
        }

        const id = crypto.randomUUID();
        const date = purchase_date || Date.now();
        const brokerVal = broker || 'Other';

        await env.DB.prepare(
          `INSERT INTO assets (id, portfolio_id, symbol, name, quantity, purchase_price, purchase_date, broker) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
        ).bind(id, portfolio_id, symbol.toUpperCase(), name, Number(quantity), Number(purchase_price), date, brokerVal).run();

        return jsonResponse({
          success: true,
          asset: { id, portfolio_id, symbol: symbol.toUpperCase(), name, quantity, purchase_price, purchase_date: date, broker: brokerVal }
        }, 201);
      }

      // ----------------------------------------------------
      // ROUTE: DELETE /api/assets/:id
      // Remove an asset holding
      // ----------------------------------------------------
      const assetDeleteMatch = pathname.match(/^\/api\/assets\/([a-zA-Z0-9-]+)$/);
      if (assetDeleteMatch && method === 'DELETE') {
        const assetId = assetDeleteMatch[1];

        const result = await env.DB.prepare(
          'DELETE FROM assets WHERE id = ?'
        ).bind(assetId).run();

        if (result.meta.changes === 0) {
          return jsonResponse({ error: 'Asset holding not found' }, 404);
        }

        return jsonResponse({ success: true, message: 'Asset successfully deleted' });
      }

      // ----------------------------------------------------
      // ROUTE: PUT /api/assets/:id
      // Update an asset holding
      // ----------------------------------------------------
      const assetUpdateMatch = pathname.match(/^\/api\/assets\/([a-zA-Z0-9-]+)$/);
      if (assetUpdateMatch && method === 'PUT') {
        const assetId = assetUpdateMatch[1];
        const body: any = await request.json().catch(() => ({}));
        const { symbol, name, quantity, purchase_price, purchase_date, broker } = body;

        if (!symbol || !name || quantity === undefined || purchase_price === undefined) {
          return jsonResponse({ error: 'Missing required body fields: symbol, name, quantity, purchase_price' }, 400);
        }

        const date = purchase_date || Date.now();
        const brokerVal = broker || 'Other';

        const result = await env.DB.prepare(
          `UPDATE assets SET symbol = ?, name = ?, quantity = ?, purchase_price = ?, purchase_date = ?, broker = ? 
           WHERE id = ?`
        ).bind(symbol.toUpperCase(), name, Number(quantity), Number(purchase_price), date, brokerVal, assetId).run();

        if (result.meta.changes === 0) {
          return jsonResponse({ error: 'Asset holding not found' }, 404);
        }

        return jsonResponse({
          success: true,
          asset: { id: assetId, portfolio_id: body.portfolio_id, symbol: symbol.toUpperCase(), name, quantity, purchase_price, purchase_date: date, broker: brokerVal }
        });
      }

      // ----------------------------------------------------
      // ROUTE: GET /api/portfolios/:id/valuation
      // Calculates real-time valuation aggregating holdings + live prices
      // ----------------------------------------------------
      const valuationMatch = pathname.match(/^\/api\/portfolios\/([a-zA-Z0-9-]+)\/valuation$/);
      if (valuationMatch && method === 'GET') {
        const portfolioId = valuationMatch[1];
        const brokerParam = searchParams.get('broker');

        // 1. Fetch portfolio to get base currency
        const portfolio = await env.DB.prepare(
          'SELECT * FROM portfolios WHERE id = ?'
        ).bind(portfolioId).first<Portfolio>();
        const baseCurrency = portfolio?.currency || 'USD';

        // 2. Fetch assets in portfolio
        let queryStr = 'SELECT * FROM assets WHERE portfolio_id = ?';
        const queryParams: any[] = [portfolioId];

        if (brokerParam && brokerParam !== 'All') {
          queryStr += ' AND broker = ?';
          queryParams.push(brokerParam);
        }

        const { results: assets } = await env.DB.prepare(queryStr)
          .bind(...queryParams)
          .all<Asset>();

        if (assets.length === 0) {
          return jsonResponse({
            success: true,
            valuation: {
              portfolioId,
              currency: baseCurrency,
              totalCostBasis: 0,
              totalCurrentValue: 0,
              totalProfitLoss: 0,
              totalProfitLossPercentage: 0,
              holdings: []
            }
          });
        }

        // 3. Fetch live stock prices for all distinct tickers
        const distinctSymbols = Array.from(new Set(assets.map(a => a.symbol)));
        const stockPrices = await fetchStockPrices(distinctSymbols, ctx);

        // Check if any asset requires currency conversion
        const conversionPairs: string[] = [];
        for (const asset of assets) {
          const liveData = stockPrices[asset.symbol];
          const assetCurrency = liveData?.currency || 'USD';
          if (assetCurrency !== baseCurrency) {
            conversionPairs.push(`${assetCurrency}${baseCurrency}=X`.toUpperCase());
          }
        }

        // Fetch currency conversion FX rates in parallel
        if (conversionPairs.length > 0) {
          const distinctPairs = Array.from(new Set(conversionPairs));
          const fxRates = await fetchStockPrices(distinctPairs, ctx);
          Object.assign(stockPrices, fxRates);
        }

        // 4. Compute dynamic valuations grouped by broker and symbol
        let totalCostBasis = 0;
        let totalCurrentValue = 0;

        const groupedMap = new Map<string, {
          broker: string;
          symbol: string;
          name: string;
          quantity: number;
          totalCostBasisInBase: number;
          totalCostBasisInLocal: number;
          latestPurchaseDate: number;
        }>();

        for (const asset of assets) {
          const livePriceData = stockPrices[asset.symbol];
          const assetCurrency = livePriceData?.currency || 'USD';

          let rate = 1.0;
          if (assetCurrency !== baseCurrency) {
            const pair = `${assetCurrency}${baseCurrency}=X`.toUpperCase();
            rate = stockPrices[pair]?.price || 1.0;
          }

          const localPurchasePrice = asset.purchase_price;
          const convertedPurchasePrice = localPurchasePrice * rate;
          const costBasisInBase = asset.quantity * convertedPurchasePrice;

          const key = `${asset.broker}_${asset.symbol}`;

          if (!groupedMap.has(key)) {
            groupedMap.set(key, {
              broker: asset.broker,
              symbol: asset.symbol,
              name: asset.name,
              quantity: asset.quantity,
              totalCostBasisInBase: costBasisInBase,
              totalCostBasisInLocal: asset.quantity * localPurchasePrice,
              latestPurchaseDate: asset.purchase_date,
            });
          } else {
            const existing = groupedMap.get(key)!;
            existing.quantity += asset.quantity;
            existing.totalCostBasisInBase += costBasisInBase;
            existing.totalCostBasisInLocal += asset.quantity * localPurchasePrice;
            if (asset.purchase_date > existing.latestPurchaseDate) {
              existing.latestPurchaseDate = asset.purchase_date;
            }
          }
        }

        const holdingsList = Array.from(groupedMap.values()).map((group) => {
          const livePriceData = stockPrices[group.symbol];
          const assetCurrency = livePriceData?.currency || 'USD';

          let rate = 1.0;
          if (assetCurrency !== baseCurrency) {
            const pair = `${assetCurrency}${baseCurrency}=X`.toUpperCase();
            rate = stockPrices[pair]?.price || 1.0;
          }

          const localCurrentPrice = livePriceData ? livePriceData.price : (group.quantity > 0 ? (group.totalCostBasisInLocal / group.quantity) : 0);
          const localPreviousClose = livePriceData?.previousClose || localCurrentPrice;

          const convertedCurrentPrice = localCurrentPrice * rate;
          const convertedPreviousClose = localPreviousClose * rate;

          const costBasis = group.totalCostBasisInBase;
          const currentValue = group.quantity * convertedCurrentPrice;
          const profitLoss = currentValue - costBasis;
          const profitLossPercentage = costBasis > 0 ? (profitLoss / costBasis) * 100 : 0;

          // Average purchase price in local currency
          const localAveragePurchasePrice = group.quantity > 0 ? (group.totalCostBasisInLocal / group.quantity) : 0;
          const convertedPurchasePrice = localAveragePurchasePrice * rate;

          totalCostBasis += costBasis;
          totalCurrentValue += currentValue;

          return {
            id: `${group.broker}_${group.symbol}`,
            symbol: group.symbol,
            name: group.name,
            quantity: group.quantity,
            purchaseDate: group.latestPurchaseDate,
            purchasePrice: localAveragePurchasePrice,
            convertedPurchasePrice,
            currentPrice: localCurrentPrice,
            convertedCurrentPrice,
            costBasis,
            currentValue,
            profitLoss,
            profitLossPercentage,
            currency: assetCurrency,
            previousClose: localPreviousClose,
            convertedPreviousClose,
            weightPercentage: 0,
            broker: group.broker
          };
        });

        // 5. Calculate total metrics and weights
        const totalProfitLoss = totalCurrentValue - totalCostBasis;
        const totalProfitLossPercentage = totalCostBasis > 0 ? (totalProfitLoss / totalCostBasis) * 100 : 0;

        const holdingsWithWeights = holdingsList.map(h => ({
          ...h,
          weightPercentage: totalCurrentValue > 0 ? (h.currentValue / totalCurrentValue) * 100 : 0
        }));

        return jsonResponse({
          success: true,
          valuation: {
            portfolioId,
            currency: baseCurrency,
            totalCostBasis,
            totalCurrentValue,
            totalProfitLoss,
            totalProfitLossPercentage,
            holdings: holdingsWithWeights
          }
        });
      }

      // ----------------------------------------------------
      // ROUTE: GET /api/portfolios/:id/trend
      // Calculates historical portfolio valuation trend for the last 30 days
      // ----------------------------------------------------
      const trendMatch = pathname.match(/^\/api\/portfolios\/([a-zA-Z0-9-]+)\/trend$/);
      if (trendMatch && method === 'GET') {
        const portfolioId = trendMatch[1];
        const userId = getUserId(request);

        // 1. Verify portfolio exists and belongs to user
        const portfolio = await env.DB.prepare(
          'SELECT * FROM portfolios WHERE id = ? AND user_id = ?'
        ).bind(portfolioId, userId).first<Portfolio>();

        if (!portfolio) {
          return jsonResponse({ error: 'Portfolio not found or unauthorized' }, 404);
        }

        const baseCurrency = portfolio.currency || 'USD';

        // 2. Generate date range for the last 30 days
        const days = 30;
        const dates: string[] = [];
        const now = new Date();
        for (let i = days - 1; i >= 0; i--) {
          const d = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
          dates.push(d.toISOString().split('T')[0]);
        }

        // 3. Fetch all assets inside the portfolio (filtered by broker if requested)
        const brokerParam = searchParams.get('broker');
        let queryStr = 'SELECT * FROM assets WHERE portfolio_id = ?';
        const queryParams: any[] = [portfolioId];

        if (brokerParam && brokerParam !== 'All') {
          queryStr += ' AND broker = ?';
          queryParams.push(brokerParam);
        }

        queryStr += ' ORDER BY purchase_date ASC';

        const { results: assets } = await env.DB.prepare(queryStr)
          .bind(...queryParams)
          .all<Asset>();

        if (assets.length === 0) {
          // Empty portfolio: return trend with 0 values
          const trend = dates.map(d => ({ date: d, value: 0 }));
          return jsonResponse({ success: true, trend });
        }

        // 4. Fetch real-time stock prices to get their currencies
        const distinctSymbols = Array.from(new Set(assets.map(a => a.symbol)));
        const stockPrices = await fetchStockPrices(distinctSymbols, ctx);

        // Find required FX conversion pairs
        const conversionPairs: string[] = [];
        const symbolCurrencyMap: Record<string, string> = {};

        for (const symbol of distinctSymbols) {
          const liveData = stockPrices[symbol];
          const assetCurrency = liveData?.currency || 'USD';
          symbolCurrencyMap[symbol] = assetCurrency;
          if (assetCurrency !== baseCurrency) {
            conversionPairs.push(`${assetCurrency}${baseCurrency}=X`.toUpperCase());
          }
        }

        // 5. Fetch historical prices for assets and FX conversion pairs in parallel
        const symbolPricesMap: Record<string, Record<string, number>> = {};
        const allQuerySymbols = [...distinctSymbols, ...Array.from(new Set(conversionPairs))];

        const promises = allQuerySymbols.map(async (symbol) => {
          const prices = await getHistoricalPrices(symbol, dates, env, ctx);
          symbolPricesMap[symbol] = prices;
        });
        await Promise.all(promises);

        // 6. Aggregate valuation for each date
        const trend = dates.map((dateStr) => {
          const endOfDayTimestamp = new Date(dateStr + 'T23:59:59.999Z').getTime();
          let dailyValuation = 0;
          const isToday = dateStr === dates[dates.length - 1];

          for (const asset of assets) {
            // Count asset only if it was purchased on or before this day
            if (asset.purchase_date <= endOfDayTimestamp) {
              const symbolPrices = symbolPricesMap[asset.symbol] || {};

              // If it's today, prioritize the live/real-time stock price from fetchStockPrices
              let price = symbolPrices[dateStr];
              if (isToday) {
                const liveData = stockPrices[asset.symbol];
                if (liveData?.price !== undefined) {
                  price = liveData.price;
                }
              }
              if (price === undefined || price === null) {
                price = asset.purchase_price;
              }

              // Convert price to portfolio base currency if necessary
              const assetCurrency = symbolCurrencyMap[asset.symbol] || 'USD';
              let priceInBase = price;
              if (assetCurrency !== baseCurrency) {
                const pair = `${assetCurrency}${baseCurrency}=X`.toUpperCase();

                // If it's today, prioritize the live exchange rate
                let rate = symbolPricesMap[pair]?.[dateStr];
                if (isToday) {
                  const liveRateData = stockPrices[pair];
                  if (liveRateData?.price !== undefined) {
                    rate = liveRateData.price;
                  }
                }
                if (rate === undefined || rate === null) {
                  rate = 1.0;
                }

                priceInBase = price * rate;
              }

              dailyValuation += asset.quantity * priceInBase;
            }
          }

          return {
            date: dateStr,
            value: Number(dailyValuation.toFixed(2))
          };
        });

        return jsonResponse({ success: true, trend });
      }

      // 404 Not Found fallback
      return jsonResponse({ error: 'Endpoint or method not supported' }, 404);

    } catch (err: any) {
      console.error('[Worker Request Error]:', err);
      return jsonResponse({
        error: 'Internal Server Error',
        details: err.message || String(err)
      }, 500);
    }
  },
};
