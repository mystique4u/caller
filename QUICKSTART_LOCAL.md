# 🚀 Quick Start - Local Testing

Get RouteMaker running locally in 3 simple steps!

## Step 1: Start the Application

```bash
./scripts/routemaker-dev.sh start
```

This will:
- Build the Docker container
- Start the application
- Make it available at http://localhost:3000

## Step 2: Create a User

```bash
./scripts/routemaker-dev.sh user-create
```

Enter:
- Username (e.g., "alice")
- Password (e.g., "test123")
- Choose a color (or press Enter for random)

## Step 3: Test It!

1. Open http://localhost:3000 in your browser
2. Sign in with your credentials
3. Click **"Draw Route"**
4. Click on the map to add waypoints
5. Click **"Finish"** and save your route

## Testing Waypoint Editing

1. Click on your route (or select from sidebar)
2. Click **"Edit Waypoints"**
3. **Drag** the numbered markers to move waypoints
4. **Click** on the map to add new waypoints between existing ones
5. **Right-click** a marker to remove it
6. Click **"Save Changes"**

## Testing Real-World Coordinates

1. Create a route following a real street or path
2. Click on the route → **"Export GeoJSON"**
3. Open the downloaded file in a text editor
4. You'll see actual longitude/latitude coordinates:
   ```json
   "coordinates": [[2.3522, 48.8566], [2.3532, 48.8576]]
   ```
5. These coordinates work in any GIS application!

## Testing Multiple Users (Real-time Sync)

1. Create a second user:
   ```bash
   ./scripts/routemaker-dev.sh user-create
   ```
2. Open a new **incognito/private browser window**
3. Go to http://localhost:3000
4. Sign in as the second user
5. Draw a route - both users see it instantly! 🎉

## Other Helpful Commands

```bash
# View live logs
./scripts/routemaker-dev.sh logs

# Stop the application
./scripts/routemaker-dev.sh stop

# Restart after code changes
./scripts/routemaker-dev.sh restart

# List all users
./scripts/routemaker-dev.sh user-list

# Reset database (start fresh)
./scripts/routemaker-dev.sh reset

# Remove everything
./scripts/routemaker-dev.sh clean
```

## Testing on Your Phone

1. Find your computer's IP address:
   ```bash
   ip addr show | grep "inet " | grep -v 127.0.0.1
   ```
   
2. On your phone, open browser and go to:
   ```
   http://YOUR_IP_ADDRESS:3000
   ```

3. Test mobile features:
   - Tap to add waypoints
   - Pinch to zoom
   - Toggle sidebar with ☰ button

## Troubleshooting

**Port already in use?**
```bash
# Edit docker-compose.local.yml and change 3000 to another port like 3001
```

**Can't create user?**
```bash
# Check if container is running
docker ps | grep routemaker-local

# View logs
./scripts/routemaker-dev.sh logs
```

**Routes not syncing?**
- Open browser console (F12)
- Look for "WebSocket" messages
- Refresh the page

## What to Test

- [ ] Login works
- [ ] Can draw routes with multiple waypoints
- [ ] Waypoints can be dragged to new positions
- [ ] Can add waypoints by clicking map (in edit mode)
- [ ] Can remove waypoints by right-clicking (in edit mode)
- [ ] Exported GeoJSON has correct coordinates
- [ ] Exported GPX works in GPS apps
- [ ] Multiple users see each other's routes instantly
- [ ] Routes stay visible after page refresh
- [ ] Works on mobile device
- [ ] Sidebar toggles on mobile
- [ ] Map tiles load properly
- [ ] Can zoom and pan smoothly

## Next Steps

Once you've tested everything:

```bash
# Stop local testing
./scripts/routemaker-dev.sh stop

# Commit your changes
git add .
git commit -m "Add RouteMaker with waypoint editing"
git push

# Deploy automatically via GitHub Actions
# Access at https://maker.yourdomain.com
```

## Need Help?

Check the detailed guides:
- [Local Testing Guide](LOCAL_TESTING.md) - Comprehensive testing instructions
- [RouteMaker Guide](ROUTEMAKER_GUIDE.md) - Full feature documentation

## Feature Highlights

✅ **Editable Waypoints** - Drag, add, remove points anytime  
✅ **Real-World Coordinates** - Tied to actual lon/lat positions  
✅ **Live Collaboration** - See others' routes in real-time  
✅ **Mobile Friendly** - Full functionality on phones  
✅ **Standard Formats** - Export to GeoJSON & GPX  
✅ **ESRI Satellite** - High-quality imagery background
