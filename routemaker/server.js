const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const path = require('path');
const http = require('http');
const WebSocket = require('ws');
const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { create } = require('xmlbuilder2');

const app = express();
app.set('trust proxy', true); // Trust Traefik reverse proxy
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;
const SESSION_SECRET = process.env.SESSION_SECRET || 'change-me-in-production-' + Math.random().toString(36);

// Database initialization
const db = new Database('./data/routemaker.db');
db.pragma('journal_mode = WAL');

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    color TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS routes (
    id TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    geojson TEXT NOT NULL,
    color TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
  );

  CREATE INDEX IF NOT EXISTS idx_routes_user_id ON routes(user_id);
  CREATE INDEX IF NOT EXISTS idx_routes_created_at ON routes(created_at);

  CREATE TABLE IF NOT EXISTS warnings (
    id TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    type TEXT NOT NULL,
    description TEXT NOT NULL,
    lat REAL NOT NULL,
    lng REAL NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
  );

  CREATE INDEX IF NOT EXISTS idx_warnings_user_id ON warnings(user_id);
  CREATE INDEX IF NOT EXISTS idx_warnings_created_at ON warnings(created_at);
`);

// Middleware
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(session({
  secret: SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    sameSite: 'lax',
    maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
  }
}));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Authentication middleware
function requireAuth(req, res, next) {
  console.log('requireAuth check:', {
    sessionID: req.sessionID,
    userId: req.session.userId,
    path: req.path,
    hasCookie: !!req.headers.cookie
  });
  
  if (req.session.userId) {
    next();
  } else {
    console.log('Auth failed - no userId in session');
    res.status(401).json({ error: 'Unauthorized' });
  }
}

// Helper functions
function generateUserColor() {
  const colors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', '#98D8C8',
    '#F7DC6F', '#BB8FCE', '#85C1E2', '#F8B739', '#52B788'
  ];
  return colors[Math.floor(Math.random() * colors.length)];
}

function convertGeoJSONtoGPX(geojson, routeName, description) {
  const root = create({ version: '1.0', encoding: 'UTF-8' })
    .ele('gpx', {
      version: '1.1',
      creator: 'RouteMaker',
      xmlns: 'http://www.topografix.com/GPX/1/1'
    });

  const trk = root.ele('trk');
  trk.ele('name').txt(routeName || 'Route');
  if (description) {
    trk.ele('desc').txt(description);
  }

  const trkseg = trk.ele('trkseg');

  if (geojson.type === 'Feature' && geojson.geometry) {
    const coords = geojson.geometry.coordinates;
    coords.forEach(coord => {
      trkseg.ele('trkpt', { lat: coord[1], lon: coord[0] });
    });
  } else if (geojson.type === 'FeatureCollection') {
    geojson.features.forEach(feature => {
      if (feature.geometry && feature.geometry.coordinates) {
        feature.geometry.coordinates.forEach(coord => {
          trkseg.ele('trkpt', { lat: coord[1], lon: coord[0] });
        });
      }
    });
  }

  return root.end({ prettyPrint: true });
}

// API Routes
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  
  console.log('Login attempt:', username);
  
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' });
  }

  try {
    const user = db.prepare('SELECT * FROM users WHERE username = ?').get(username);
    
    if (!user) {
      console.log('User not found:', username);
      return res.status(401).json({ error: 'Invalid username or password' });
    }
    
    const passwordMatch = bcrypt.compareSync(password, user.password);
    console.log('Password match:', passwordMatch);
    
    if (!passwordMatch) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    req.session.userId = user.id;
    req.session.username = user.username;
    req.session.userColor = user.color;
    
    console.log('Session set:', {
      userId: req.session.userId,
      sessionID: req.sessionID,
      cookie: req.session.cookie
    });
    
    console.log('Login successful:', username);
    
    res.json({ 
      success: true, 
      user: { 
        id: user.id, 
        username: user.username, 
        color: user.color 
      } 
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
});

app.post('/api/logout', (req, res) => {
  req.session.destroy();
  res.json({ success: true });
});

app.get('/api/me', requireAuth, (req, res) => {
  const user = db.prepare('SELECT id, username, color FROM users WHERE id = ?').get(req.session.userId);
  res.json({ user });
});

app.get('/api/routes', requireAuth, (req, res) => {
  const routes = db.prepare(`
    SELECT r.*, u.username, u.color as user_color 
    FROM routes r 
    JOIN users u ON r.user_id = u.id 
    ORDER BY r.updated_at DESC
  `).all();
  
  const parsed = routes.map(r => ({
    ...r,
    geojson: JSON.parse(r.geojson)
  }));
  
  res.json({ routes: parsed });
});

app.post('/api/routes', requireAuth, (req, res) => {
  const { name, description, geojson } = req.body;
  
  if (!name || !geojson) {
    return res.status(400).json({ error: 'Name and geojson required' });
  }

  const id = uuidv4();
  const user = db.prepare('SELECT color FROM users WHERE id = ?').get(req.session.userId);
  
  db.prepare(`
    INSERT INTO routes (id, user_id, name, description, geojson, color)
    VALUES (?, ?, ?, ?, ?, ?)
  `).run(id, req.session.userId, name, description || '', JSON.stringify(geojson), user.color);

  // Fetch the complete route with created_at
  const dbRoute = db.prepare('SELECT * FROM routes WHERE id = ?').get(id);
  
  const route = {
    id: dbRoute.id,
    user_id: dbRoute.user_id,
    name: dbRoute.name,
    description: dbRoute.description,
    geojson: JSON.parse(dbRoute.geojson),
    color: dbRoute.color,
    created_at: dbRoute.created_at,
    updated_at: dbRoute.updated_at,
    username: req.session.username
  };

  // Broadcast to all connected clients
  broadcastRouteUpdate({ type: 'new', route });

  res.json({ success: true, route });
});

app.put('/api/routes/:id', requireAuth, (req, res) => {
  const { id } = req.params;
  const { name, description, geojson } = req.body;
  
  const route = db.prepare('SELECT * FROM routes WHERE id = ?').get(id);
  
  if (!route) {
    return res.status(404).json({ error: 'Route not found' });
  }
  
  if (route.user_id !== req.session.userId) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  db.prepare(`
    UPDATE routes 
    SET name = ?, description = ?, geojson = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `).run(name, description || '', JSON.stringify(geojson), id);

  const updatedRoute = {
    id,
    user_id: req.session.userId,
    name,
    description: description || '',
    geojson,
    color: route.color,
    username: req.session.username
  };

  broadcastRouteUpdate({ type: 'update', route: updatedRoute });

  res.json({ success: true, route: updatedRoute });
});

app.delete('/api/routes/:id', requireAuth, (req, res) => {
  const { id } = req.params;
  
  const route = db.prepare('SELECT * FROM routes WHERE id = ?').get(id);
  
  if (!route) {
    return res.status(404).json({ error: 'Route not found' });
  }
  
  if (route.user_id !== req.session.userId) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  db.prepare('DELETE FROM routes WHERE id = ?').run(id);

  broadcastRouteUpdate({ type: 'delete', routeId: id });

  res.json({ success: true });
});

app.get('/api/routes/:id/export', requireAuth, (req, res) => {
  const { id } = req.params;
  const format = req.query.format || 'geojson';
  
  const route = db.prepare('SELECT * FROM routes WHERE id = ?').get(id);
  
  if (!route) {
    return res.status(404).json({ error: 'Route not found' });
  }

  const geojson = JSON.parse(route.geojson);

  if (format === 'gpx') {
    const gpx = convertGeoJSONtoGPX(geojson, route.name, route.description);
    res.setHeader('Content-Type', 'application/gpx+xml');
    res.setHeader('Content-Disposition', `attachment; filename="${route.name}.gpx"`);
    res.send(gpx);
  } else {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="${route.name}.geojson"`);
    res.json(geojson);
  }
});

// Warning Points API
app.get('/api/warnings', requireAuth, (req, res) => {
  const warnings = db.prepare(`
    SELECT w.*, u.username, u.color as user_color
    FROM warnings w
    JOIN users u ON w.user_id = u.id
    ORDER BY w.created_at DESC
  `).all();
  
  warnings.forEach(w => {
    w.user_id = parseInt(w.user_id);
  });
  
  res.json({ warnings });
});

app.post('/api/warnings', requireAuth, (req, res) => {
  try {
    const { type, description, lat, lng } = req.body;
    
    console.log('POST /api/warnings - Request body:', JSON.stringify(req.body));
    console.log('User ID from session:', req.session.userId);
    
    if (!type || lat === undefined || lng === undefined) {
      console.log('Validation failed - missing required fields');
      return res.status(400).json({ error: 'Type and coordinates required' });
    }

    // Allow empty description, default to empty string
    const desc = description || '';

    const id = uuidv4();
    const user = db.prepare('SELECT username, color FROM users WHERE id = ?').get(req.session.userId);
    
    if (!user) {
      console.log('User not found in database for ID:', req.session.userId);
      return res.status(404).json({ error: 'User not found' });
    }
    
    console.log('Inserting warning:', { id, user_id: req.session.userId, type, description: desc, lat, lng });
    
    db.prepare(`
      INSERT INTO warnings (id, user_id, type, description, lat, lng)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(id, req.session.userId, type, desc, lat, lng);

    const warning = {
      id,
      user_id: req.session.userId,
      type,
      description: desc,
      lat,
      lng,
      username: user.username,
      user_color: user.color,
      created_at: new Date().toISOString()
    };

    // Broadcast to all connected clients
    broadcastRouteUpdate({ type: 'warning_new', warning });

    console.log('Warning saved successfully:', id);
    res.json({ success: true, warning });
  } catch (error) {
    console.error('Error saving warning:', error.message);
    console.error('Stack trace:', error.stack);
    res.status(500).json({ error: 'Failed to save warning: ' + error.message });
  }
});

app.delete('/api/warnings/:id', requireAuth, (req, res) => {
  const { id } = req.params;
  
  const warning = db.prepare('SELECT * FROM warnings WHERE id = ?').get(id);
  
  if (!warning) {
    return res.status(404).json({ error: 'Warning not found' });
  }
  
  if (parseInt(warning.user_id) !== req.session.userId) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  db.prepare('DELETE FROM warnings WHERE id = ?').run(id);

  broadcastRouteUpdate({ type: 'warning_delete', warningId: id });

  res.json({ success: true });
});

// WebSocket for real-time updates
const clients = new Set();

wss.on('connection', (ws, req) => {
  // Simple auth check via cookie
  const cookies = req.headers.cookie?.split(';').reduce((acc, cookie) => {
    const [key, value] = cookie.trim().split('=');
    acc[key] = value;
    return acc;
  }, {});

  clients.add(ws);

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      
      // Broadcast location updates and location stop messages to all clients
      if (data.type === 'location' || data.type === 'location_stop') {
        broadcastRouteUpdate(data);
      }
    } catch (error) {
      console.error('WebSocket message error:', error);
    }
  });

  ws.on('close', () => {
    clients.delete(ws);
  });

  ws.on('error', () => {
    clients.delete(ws);
  });
});

function broadcastRouteUpdate(data) {
  const message = JSON.stringify(data);
  clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// Serve index.html for all other routes (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server
server.listen(PORT, () => {
  console.log(`RouteMaker server running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...');
  server.close(() => {
    db.close();
    process.exit(0);
  });
});
