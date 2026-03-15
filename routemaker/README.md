# RouteMaker

A collaborative web application for building and sharing routes on a map.

## Features

- 🗺️ Interactive map with ESRI satellite imagery
- ✏️ Draw routes directly on the map
- 👥 Multi-user support with real-time updates
- 🎨 Color-coded routes per user
- 📤 Export routes to GeoJSON and GPX formats
- 📱 Responsive design for desktop and mobile
- 🔐 Simple authentication system

## User Management

Users must be created by an administrator using the command-line tool:

### Create a new user

```bash
docker exec -it routemaker node manage-users.js create
```

### List all users

```bash
docker exec -it routemaker node manage-users.js list
```

### Delete a user

```bash
docker exec -it routemaker node manage-users.js delete
```

## API Endpoints

### Authentication
- `POST /api/login` - User login
- `POST /api/logout` - User logout
- `GET /api/me` - Get current user info

### Routes
- `GET /api/routes` - Get all routes
- `POST /api/routes` - Create a new route
- `PUT /api/routes/:id` - Update a route
- `DELETE /api/routes/:id` - Delete a route
- `GET /api/routes/:id/export?format=geojson|gpx` - Export a route

## Technology Stack

- **Backend**: Node.js with Express
- **Database**: SQLite (better-sqlite3)
- **Frontend**: Vanilla JavaScript with Leaflet.js
- **Real-time**: WebSocket for live updates
- **Map Tiles**: ESRI World Imagery

## Environment Variables

- `PORT` - Port to run the server on (default: 3000)
- `SESSION_SECRET` - Secret for session encryption (auto-generated if not set)
- `NODE_ENV` - Environment (production/development)

## Data Persistence

The application stores data in `/app/data/routemaker.db`. Make sure to mount this directory as a volume for data persistence.

## License

MIT
