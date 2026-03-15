# Local Development Guide for RouteMaker

This guide will help you run RouteMaker locally for testing before deploying to production.

## Prerequisites

- Docker and Docker Compose installed
- Node.js 18+ (optional, for development without Docker)

## Quick Start with Docker

### 1. Build and Start the Application

```bash
# From the repository root
docker-compose -f docker-compose.local.yml up --build
```

The application will be available at: **http://localhost:3000**

### 2. Create Your First User

In a new terminal window:

```bash
docker exec -it routemaker-local node manage-users.js create
```

Follow the prompts to create a user with:
- Username (min 3 characters)
- Password (min 6 characters)
- Choose a color for your routes

### 3. Test the Application

1. Open http://localhost:3000 in your browser
2. Sign in with the credentials you just created
3. Try the following features:

#### Drawing a New Route
- Click "Draw Route" button
- Click on the map to add waypoints
- Each click adds a point to your route path
- Click "Finish" when done
- Give it a name and save

#### Editing Waypoints
- Click on any of your routes (or select from sidebar)
- Click "Edit Waypoints" in the details modal
- **Drag** waypoint markers to adjust positions
- **Click** on the map to add new waypoints (inserted at closest position)
- **Right-click** waypoint markers to remove them
- Click "Save Changes" when done

#### Testing Multiple Users
- Create another user (see step 2)
- Open a new incognito/private window
- Sign in as the new user
- Draw routes - both users should see each other's routes in real-time!

#### Exporting Routes
- Open route details
- Click "Export GeoJSON" or "Export GPX"
- The file will download with real-world coordinates (longitude, latitude)

### 4. Stop the Application

```bash
# Stop and remove containers
docker-compose -f docker-compose.local.yml down

# Stop and remove containers + volumes (clears database)
docker-compose -f docker-compose.local.yml down -v
```

## Running Without Docker (Development Mode)

### 1. Install Dependencies

```bash
cd routemaker
npm install
```

### 2. Start the Server

```bash
npm start
# or for auto-reload on changes:
npm run dev  # requires: npm install -g nodemon
```

### 3. Create Users

```bash
node manage-users.js create
```

### 4. Access the Application

Open http://localhost:3000 in your browser

## Testing Real-World Coordinates

Routes are stored with real longitude/latitude coordinates:

1. Create a route on the map
2. Export as GeoJSON
3. Open the file - you'll see coordinates like:
   ```json
   {
     "type": "Feature",
     "geometry": {
       "type": "LineString",
       "coordinates": [
         [2.3522, 48.8566],  // [longitude, latitude]
         [2.3532, 48.8576]
       ]
     }
   }
   ```
4. Import this into any GIS tool (QGIS, ArcGIS, Google Earth, etc.)

## Testing on Mobile

### Option 1: Local Network Access

1. Find your computer's local IP:
   ```bash
   # Linux/Mac
   ip addr show | grep inet
   # or
   ifconfig | grep inet
   ```

2. Access from mobile browser:
   ```
   http://YOUR_LOCAL_IP:3000
   ```

### Option 2: Using ngrok (for external access)

```bash
# Install ngrok: https://ngrok.com/download
ngrok http 3000
```

Access the https URL provided by ngrok from any device.

## User Management Commands

```bash
# Create a user
docker exec -it routemaker-local node manage-users.js create

# List all users
docker exec -it routemaker-local node manage-users.js list

# Delete a user
docker exec -it routemaker-local node manage-users.js delete
```

## Database Location

The SQLite database is stored at:
```
./routemaker/data/routemaker.db
```

To reset everything:
```bash
rm -rf ./routemaker/data/*.db
docker-compose -f docker-compose.local.yml restart
```

## Troubleshooting

### Port 3000 already in use
```bash
# Change port in docker-compose.local.yml:
ports:
  - "3001:3000"  # Use port 3001 instead
```

### Container won't start
```bash
# Check logs
docker-compose -f docker-compose.local.yml logs -f

# Rebuild from scratch
docker-compose -f docker-compose.local.yml down
docker-compose -f docker-compose.local.yml build --no-cache
docker-compose -f docker-compose.local.yml up
```

### Routes not syncing between users
- Check browser console (F12) for WebSocket errors
- Ensure both users are signed in
- WebSocket connects automatically on login

### Map tiles not loading
- Check internet connection (ESRI tiles require internet)
- Check browser console for CORS errors
- Wait a moment - tiles load progressively

## Development Tips

### Hot Reload for Frontend Changes

Frontend files are mounted as volumes. Changes to files in `routemaker/public/` will be reflected after refreshing the browser.

For backend changes, restart the container:
```bash
docker-compose -f docker-compose.local.yml restart
```

### Debugging

View real-time logs:
```bash
docker-compose -f docker-compose.local.yml logs -f routemaker
```

Access container shell:
```bash
docker exec -it routemaker-local sh
```

### Testing WebSocket

Open browser console and check for:
```
WebSocket connected
```

## Next Steps

Once testing is complete:

1. Commit your changes to the repository
2. Push to trigger the deployment workflow
3. The application will be deployed to your server automatically
4. Access at `https://maker.yourdomain.com`

## Feature Checklist

Test these features before deploying:

- [ ] User authentication
- [ ] Drawing new routes
- [ ] Editing waypoints (drag, add, remove)
- [ ] Real-time updates between users
- [ ] Export to GeoJSON
- [ ] Export to GPX
- [ ] Route deletion
- [ ] Mobile responsiveness
- [ ] Sidebar toggle
- [ ] Map navigation (zoom, pan)
- [ ] Waypoint coordinates match map location
