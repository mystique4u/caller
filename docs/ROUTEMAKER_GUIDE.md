# RouteMaker Setup Guide

RouteMaker is a collaborative web application for building and sharing routes on a map. Multiple users can draw routes on ESRI satellite imagery, see each other's routes in real-time, and export them in standard formats (GeoJSON, GPX).

## Features

- 🗺️ **Interactive Mapping**: ESRI satellite imagery with reference labels
- ✏️ **Route Drawing**: Click to add points and build routes directly on the map
- 👥 **Multi-User**: All users see routes in real-time with color-coding per user
- 📱 **Responsive**: Works on desktop and mobile devices
- 📤 **Export**: Download routes as GeoJSON or GPX for use in other applications
- 🔐 **Authentication**: Simple user management via command line

## Access

Once deployed, RouteMaker is available at:

```
https://maker.yourdomain.com
```

## User Management

RouteMaker uses a simplified authentication model where users are created by administrators via the command line. This keeps the application lightweight and focused on route building.

### Creating Users

**On the server:**
```bash
docker exec -it routemaker node manage-users.js create
```

**From your local machine using the helper script:**
```bash
./scripts/routemaker-users.sh create
```

You'll be prompted for:
- Username (minimum 3 characters)
- Password (minimum 6 characters)
- Password confirmation
- Color (choose from a list or get a random color)

### Listing Users

**On the server:**
```bash
docker exec -it routemaker node manage-users.js list
```

**From your local machine:**
```bash
./scripts/routemaker-users.sh list
```

### Deleting Users

**On the server:**
```bash
docker exec -it routemaker node manage-users.js delete
```

**From your local machine:**
```bash
./scripts/routemaker-users.sh delete
```

**Note:** Deleting a user also deletes all their routes.

## Using RouteMaker

### Drawing Routes

1. Sign in with your credentials
2. Click the **"Draw Route"** button in the sidebar
3. Click on the map to add points to your route
4. Continue clicking to add more points
5. Click **"Finish"** when done
6. Enter a name and optional description
7. Click **"Save"**

### Viewing Routes

- All routes from all users are displayed on the map
- Each user's routes have their unique color
- Click on any route to see details
- Routes appear in real-time as other users create them

### Exporting Routes

1. Click on a route or select it from your routes list
2. In the details modal, choose:
   - **Export GeoJSON**: Standard format for GIS applications
   - **Export GPX**: GPS Exchange Format, compatible with most GPS devices and apps

### Working on Mobile

RouteMaker is fully responsive and works on mobile devices:
- Use the hamburger menu (☰) to toggle the sidebar
- Tap on the map to add points
- Pinch to zoom
- All features work the same as on desktop

## Technology Stack

- **Frontend**: Vanilla JavaScript with Leaflet.js for mapping
- **Backend**: Node.js with Express
- **Database**: SQLite for lightweight data storage
- **Real-time**: WebSocket for live route updates
- **Map Tiles**: ESRI World Imagery satellite tiles

## Data Persistence

Route data is stored in `/opt/services/routemaker/data/routemaker.db` on the server. This directory is automatically created and backed up if you have backups configured.

## Troubleshooting

### Users can't log in

Check if the container is running:
```bash
docker ps | grep routemaker
```

View container logs:
```bash
docker logs routemaker
```

### Routes not appearing

Check WebSocket connection in browser console (F12). The app will automatically reconnect if the WebSocket connection drops.

### Export not working

Ensure the user has permission to access the route they're trying to export. Users can only export their own routes.

## API Documentation

For developers who want to integrate with RouteMaker:

### Authentication
- `POST /api/login` - Authenticate user
- `POST /api/logout` - End session
- `GET /api/me` - Get current user information

### Routes
- `GET /api/routes` - Get all routes
- `POST /api/routes` - Create a new route
- `PUT /api/routes/:id` - Update a route (own routes only)
- `DELETE /api/routes/:id` - Delete a route (own routes only)
- `GET /api/routes/:id/export?format=geojson|gpx` - Export route

All API endpoints (except login) require authentication via session cookie.

## Security Notes

- All traffic is encrypted via HTTPS (Traefik with Let's Encrypt)
- Sessions are secured with HTTP-only cookies
- User passwords are hashed with bcrypt
- Only route owners can modify or delete their routes
- All users can view all routes (by design for collaboration)

## Future Enhancements

Potential features that could be added:
- Route categories and tagging
- Search and filter routes
- Route statistics (distance, elevation)
- Waypoint markers with descriptions
- Route sharing via public links
- Import existing GPX/GeoJSON files
- User profile customization
