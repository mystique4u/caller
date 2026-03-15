// RouteMaker Frontend Application
class RouteMaker {
    constructor() {
        this.map = null;
        this.currentUser = null;
        this.routes = [];
        this.routeLayers = new Map();
        this.ws = null;
        this.isDrawing = false;
        this.currentPolyline = null;
        this.currentPoints = [];
        this.selectedRoute = null;
        this.isEditingRoute = false;
        this.editingRouteId = null;
        this.editMarkers = [];
        this.userLocationMarker = null;
        this.userLocationCircle = null;
        this.locationWatchId = null;
        this.isTrackingLocation = false;
        this.lastHeading = 0;
        this.isRecordingRoute = false;
        this.recordedPoints = [];
        this.recordingStartTime = null;
        this.liveUserMarkers = new Map(); // Track other users' live locations
        this.warningMarkers = new Map(); // Track warning points
        this.isPlacingWarning = false;
        this.currentGPSLocation = null; // Store current GPS location for instant warning
        
        this.init();
    }

    async init() {
        // Check if already logged in
        try {
            const response = await fetch('/api/me');
            if (response.ok) {
                const data = await response.json();
                this.currentUser = data.user;
                this.showApp();
            } else {
                this.showLogin();
            }
        } catch (error) {
            this.showLogin();
        }

        this.setupEventListeners();
    }

    setupEventListeners() {
        // Login
        document.getElementById('login-form')?.addEventListener('submit', (e) => this.handleLogin(e));
        
        // Logout
        document.getElementById('logout-btn')?.addEventListener('click', () => this.handleLogout());
        
        // Drawing tools
        document.getElementById('draw-route-btn')?.addEventListener('click', () => this.startDrawing());
        document.getElementById('stop-drawing-btn')?.addEventListener('click', () => this.finishDrawing());
        document.getElementById('cancel-drawing-btn')?.addEventListener('click', () => this.cancelDrawing());
        document.getElementById('record-route-btn')?.addEventListener('click', () => this.toggleRecording());
        document.getElementById('add-warning-btn')?.addEventListener('click', () => this.toggleWarningMode());
        
        // Modal menus
        document.getElementById('routes-menu-btn')?.addEventListener('click', () => this.openModal('routes-modal'));
        document.getElementById('user-menu-btn')?.addEventListener('click', () => this.openModal('user-menu-modal'));
        
        // Close modal buttons (using event delegation for all close buttons)
        document.addEventListener('click', (e) => {
            const target = e.target.closest('.close-modal-btn');
            if (target) {
                const modalId = target.getAttribute('data-modal');
                if (modalId) {
                    this.closeModal(modalId);
                }
            }
        });
        
        // Close modals when clicking outside (on backdrop)
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal') && e.target.classList.contains('active')) {
                this.closeModal(e.target.id);
            }
        });
        
        // Locate me
        document.getElementById('locate-me-btn')?.addEventListener('click', () => this.locateMe());
        
        // Route form
        document.getElementById('route-form')?.addEventListener('submit', (e) => this.handleSaveRoute(e));
        document.getElementById('cancel-modal-btn')?.addEventListener('click', () => this.closeModal('route-modal'));
        
        // Details modal
        document.getElementById('close-details-btn')?.addEventListener('click', () => this.closeModal('details-modal'));
        document.getElementById('export-geojson-btn')?.addEventListener('click', () => this.exportRoute('geojson'));
        document.getElementById('export-gpx-btn')?.addEventListener('click', () => this.exportRoute('gpx'));
        document.getElementById('delete-route-btn')?.addEventListener('click', () => this.deleteRoute());
        document.getElementById('edit-route-btn')?.addEventListener('click', () => this.startEditingRoute());
        document.getElementById('save-edit-btn')?.addEventListener('click', () => this.saveEditedRoute());
        document.getElementById('cancel-edit-btn')?.addEventListener('click', () => this.cancelEditingRoute());
    }

    showLogin() {
        document.getElementById('login-screen').classList.add('active');
        document.getElementById('app-screen').classList.remove('active');
    }

    showApp() {
        console.log('showApp called, currentUser:', this.currentUser);
        
        document.getElementById('login-screen').classList.remove('active');
        document.getElementById('app-screen').classList.add('active');
        
        // Update user info in dropdown
        const userInfo = document.getElementById('user-info');
        if (userInfo && this.currentUser) {
            userInfo.innerHTML = `
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                    <div style="width: 16px; height: 16px; border-radius: 50%; background: ${this.currentUser.color};"></div>
                    <strong>${this.currentUser.username}</strong>
                </div>
            `;
            console.log('User info updated');
        }
        
        console.log('Initializing map...');
        this.initMap();
        console.log('Loading routes...');
        this.loadRoutes();
        console.log('Loading warnings...');
        this.loadWarnings();
        console.log('Connecting WebSocket...');
        this.connectWebSocket();
        console.log('showApp complete');
    }

    async handleLogin(e) {
        e.preventDefault();
        
        const username = document.getElementById('username').value.trim();
        const password = document.getElementById('password').value;
        const errorDiv = document.getElementById('login-error');
        const submitBtn = e.target.querySelector('button[type="submit"]');
        
        errorDiv.textContent = '';
        
        if (!username || !password) {
            errorDiv.textContent = 'Please enter both username and password';
            return;
        }
        
        submitBtn.disabled = true;
        submitBtn.textContent = 'Signing in...';
        
        try {
            console.log('Attempting login for:', username);
            
            const response = await fetch('/api/login', {
                method: 'POST',
                headers: { 
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                credentials: 'include',
                body: JSON.stringify({ username, password })
            });
            
            console.log('Response status:', response.status);
            console.log('Response headers:', [...response.headers.entries()]);
            
            const data = await response.json();
            console.log('Response data:', data);
            
            if (response.ok && data.success) {
                console.log('Login successful, user:', data.user);
                this.currentUser = data.user;
                console.log('Calling showApp...');
                this.showApp();
            } else {
                errorDiv.textContent = data.error || 'Login failed. Please check your credentials.';
                console.error('Login failed:', data);
                submitBtn.disabled = false;
                submitBtn.textContent = 'Sign In';
            }
        } catch (error) {
            errorDiv.textContent = 'Connection error. Please try again.';
            console.error('Login error:', error);
            submitBtn.disabled = false;
            submitBtn.textContent = 'Sign In';
        }
    }

    async handleLogout() {
        try {
            await fetch('/api/logout', { method: 'POST' });
            this.cleanup();
            this.showLogin();
        } catch (error) {
            console.error('Logout error:', error);
        }
    }

    cleanup() {
        if (this.ws) {
            this.ws.close();
        }
        if (this.locationWatchId !== null) {
            navigator.geolocation.clearWatch(this.locationWatchId);
            this.locationWatchId = null;
        }
        if (this.isRecordingRoute) {
            this.stopRecording();
        }
        if (this.map) {
            this.map.remove();
            this.map = null;
        }
        this.routes = [];
        this.routeLayers.clear();
        this.currentUser = null;
        this.recordedPoints = [];
    }

    initMap() {
        // Initialize Leaflet map
        this.map = L.map('map', {
            center: [48.8566, 2.3522], // Default to Paris
            zoom: 13,
            zoomControl: true
        });

        // Define base layers
        const esriSatellite = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
            attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
            maxZoom: 19
        });

        const openTopoMap = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
            attribution: 'Map data: &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, <a href="http://viewfinderpanoramas.org">SRTM</a> | Map style: &copy; <a href="https://opentopomap.org">OpenTopoMap</a> (<a href="https://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA</a>)',
            maxZoom: 17
        });

        const osmStandard = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
            maxZoom: 19
        });

        // Define overlay layers
        const labelsOverlay = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}', {
            maxZoom: 19,
            opacity: 0.7
        });

        // Add default layer
        esriSatellite.addTo(this.map);
        labelsOverlay.addTo(this.map);

        // Create layer control
        const baseLayers = {
            "Satellite": esriSatellite,
            "Topographic": openTopoMap,
            "Street Map": osmStandard
        };

        const overlayLayers = {
            "Labels": labelsOverlay
        };

        L.control.layers(baseLayers, overlayLayers, {
            position: 'topright',
            collapsed: true
        }).addTo(this.map);

        // Try to get user's location
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.map.setView([position.coords.latitude, position.coords.longitude], 13);
                },
                (error) => {
                    console.log('Location access denied or unavailable');
                }
            );
        }

        // Setup map click for drawing
        this.map.on('click', (e) => {
            if (this.isDrawing) {
                this.addPoint(e.latlng);
            }
        });
    }

    startDrawing() {
        this.isDrawing = true;
        this.currentPoints = [];
        
        document.getElementById('draw-route-btn').style.display = 'none';
        document.getElementById('record-route-btn').style.display = 'none';
        document.getElementById('stop-drawing-btn').style.display = 'block';
        document.getElementById('cancel-drawing-btn').style.display = 'block';
        
        const status = document.getElementById('drawing-status');
        status.textContent = 'Click on the map to add points to your route';
        status.classList.add('active');
        
        this.map.getContainer().style.cursor = 'crosshair';
    }

    addPoint(latlng) {
        this.currentPoints.push(latlng);
        
        // Remove old preview polyline
        if (this.currentPolyline) {
            this.map.removeLayer(this.currentPolyline);
        }
        
        // Draw new preview polyline
        this.currentPolyline = L.polyline(this.currentPoints, {
            color: this.currentUser.color,
            weight: 12,
            opacity: 0.7
        }).addTo(this.map);
        
        // Update status
        const status = document.getElementById('drawing-status');
        status.textContent = `Points: ${this.currentPoints.length} - Click to continue, or click "Finish" to save`;
    }

    finishDrawing() {
        if (this.currentPoints.length < 2) {
            alert('A route must have at least 2 points');
            return;
        }
        
        this.isDrawing = false;
        this.map.getContainer().style.cursor = '';
        
        document.getElementById('drawing-status').classList.remove('active');
        
        // Show save modal
        this.openModal('route-modal');
    }

    cancelDrawing() {
        this.isDrawing = false;
        this.currentPoints = [];
        
        if (this.currentPolyline) {
            this.map.removeLayer(this.currentPolyline);
            this.currentPolyline = null;
        }
        
        document.getElementById('draw-route-btn').style.display = 'block';
        document.getElementById('record-route-btn').style.display = 'block';
        document.getElementById('stop-drawing-btn').style.display = 'none';
        document.getElementById('cancel-drawing-btn').style.display = 'none';
        document.getElementById('drawing-status').classList.remove('active');
        
        this.map.getContainer().style.cursor = '';
    }

    async handleSaveRoute(e) {
        e.preventDefault();
        
        // Prevent double submission
        const submitBtn = e.target.querySelector('button[type="submit"]');
        if (submitBtn.disabled) return;
        submitBtn.disabled = true;
        submitBtn.textContent = 'Saving...';
        
        const name = document.getElementById('route-name').value;
        const description = document.getElementById('route-description').value;
        
        // Convert points to GeoJSON
        const coordinates = this.currentPoints.map(p => [p.lng, p.lat]);
        const geojson = {
            type: 'Feature',
            geometry: {
                type: 'LineString',
                coordinates: coordinates
            },
            properties: {
                name: name,
                description: description
            }
        };
        
        try {
            const response = await fetch('/api/routes', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name, description, geojson })
            });
            
            if (response.ok) {
                const data = await response.json();
                
                // Check if WebSocket already added this route (race condition)
                const existingIndex = this.routes.findIndex(r => r.id === data.route.id);
                if (existingIndex === -1) {
                    // Add to routes array
                    this.routes.push(data.route);
                } else {
                    // WebSocket already added it, just update the data
                    this.routes[existingIndex] = data.route;
                }
                
                this.addRouteToMap(data.route);
                this.updateRoutesList();
                
                // Clean up
                if (this.currentPolyline) {
                    this.map.removeLayer(this.currentPolyline);
                    this.currentPolyline = null;
                }
                this.currentPoints = [];
                
                this.closeModal('route-modal');
                document.getElementById('route-form').reset();
                submitBtn.disabled = false;
                submitBtn.textContent = 'Save';
                
                document.getElementById('draw-route-btn').style.display = 'block';
                document.getElementById('record-route-btn').style.display = 'block';
                document.getElementById('stop-drawing-btn').style.display = 'none';
                document.getElementById('cancel-drawing-btn').style.display = 'none';
            } else {
                submitBtn.disabled = false;
                submitBtn.textContent = 'Save';
                alert('Failed to save route');
            }
        } catch (error) {
            submitBtn.disabled = false;
            submitBtn.textContent = 'Save';
            alert('Error saving route');
            console.error(error);
        }
    }

    async loadRoutes() {
        try {
            const response = await fetch('/api/routes');
            if (response.ok) {
                const data = await response.json();
                this.routes = data.routes;
                
                // Add all routes to map
                this.routes.forEach(route => this.addRouteToMap(route));
                this.updateRoutesList();
            }
        } catch (error) {
            console.error('Error loading routes:', error);
        }
    }

    addRouteToMap(route) {
        // Remove existing layer if any
        if (this.routeLayers.has(route.id)) {
            const oldLayer = this.routeLayers.get(route.id);
            this.map.removeLayer(oldLayer.polyline);
            // Remove waypoint markers
            if (oldLayer.markers) {
                oldLayer.markers.forEach(marker => this.map.removeLayer(marker));
            }
        }
        
        const coordinates = route.geojson.geometry.coordinates.map(c => [c[1], c[0]]);
        
        const polyline = L.polyline(coordinates, {
            color: route.color,
            weight: 9,
            opacity: 0.8
        }).addTo(this.map);
        
        polyline.bindPopup(`
            <div class="route-popup">
                <h3>${route.name}</h3>
                <p><strong>By:</strong> ${route.username}</p>
                ${route.description ? `<p>${route.description}</p>` : ''}
                <p><strong>Distance:</strong> ${(this.calculateRouteDistance(route.geojson.geometry.coordinates) / 1000).toFixed(2)} km</p>
                ${route.user_id === this.currentUser.id ? '<p><em>Click "Edit" in details to modify waypoints</em></p>' : ''}
            </div>
        `);
        
        polyline.on('click', () => {
            this.showRouteDetails(route);
        });
        
        this.routeLayers.set(route.id, { 
            polyline, 
            route,
            markers: []
        });
    }

    updateRoutesList() {
        const listDiv = document.getElementById('routes-list');
        
        if (this.routes.length === 0) {
            listDiv.innerHTML = '<div class="empty-state">No routes yet. Draw your first route!</div>';
            return;
        }
        
        // Show all routes from all users
        listDiv.innerHTML = this.routes.map(route => {
            const distance = this.calculateRouteDistance(route.geojson.geometry.coordinates);
            const distanceKm = (distance / 1000).toFixed(1);
            const distanceMiles = (distance / 1609.34).toFixed(2);
            
            let dateStr = 'Unknown';
            try {
                const date = new Date(route.created_at);
                if (!isNaN(date.getTime())) {
                    dateStr = date.toLocaleDateString();
                }
            } catch (e) {
                dateStr = '';
            }
            
            const isOwner = route.user_id === this.currentUser.id;
            
            return `
                <div class="route-item collapsible" data-route-id="${route.id}">
                    <div class="route-item-header">
                        <div class="route-color" style="background: ${route.color}"></div>
                        <div class="route-name">${route.name}</div>
                        <button class="route-expand-btn" aria-label="Expand">
                            <img src="/icons/chevron-down.svg" width="20" height="20">
                        </button>
                    </div>
                    <div class="route-meta">
                        <img src="/icons/user-filled.svg" alt="" width="12" height="12" style="display:inline; vertical-align: middle; filter: grayscale(1) opacity(0.6);"> ${route.username} • <img src="/icons/map-pin.svg" alt="" width="12" height="12" style="display:inline; vertical-align: middle; filter: grayscale(1) opacity(0.6);"> ${route.geojson.geometry.coordinates.length} pts • <img src="/icons/ruler.svg" alt="" width="12" height="12" style="display:inline; vertical-align: middle; filter: grayscale(1) opacity(0.6);"> ${distanceKm} km
                    </div>
                    ${dateStr ? `<div class="route-meta-date">${dateStr}</div>` : ''}
                    
                    <div class="route-details">
                        <div class="route-info">
                            <p><strong>Distance:</strong> ${distanceKm} km (${distanceMiles} mi)</p>
                            ${route.description ? `<p><strong>Description:</strong> ${route.description}</p>` : ''}
                            <p><strong>Created:</strong> ${dateStr}</p>
                        </div>
                        <div class="route-actions">
                            <button class="route-action-btn view-btn" data-action="view" title="View on Map">
                                <img src="/icons/eye.svg" width="20" height="20"> View
                            </button>
                            <button class="route-action-btn export-btn" data-action="export-geojson" title="Export GeoJSON">
                                <img src="/icons/download.svg" width="20" height="20"> GeoJSON
                            </button>
                            <button class="route-action-btn export-btn" data-action="export-gpx" title="Export GPX">
                                <img src="/icons/download.svg" width="20" height="20"> GPX
                            </button>
                            ${isOwner ? `
                                <button class="route-action-btn edit-btn" data-action="edit" title="Edit Route">
                                    <img src="/icons/edit.svg" width="20" height="20"> Edit
                                </button>
                                <button class="route-action-btn delete-btn" data-action="delete" title="Delete Route">
                                    <img src="/icons/trash.svg" width="20" height="20"> Delete
                                </button>
                            ` : ''}
                        </div>
                    </div>
                </div>
            `;
        }).join('');
        
        // Add click handlers
        listDiv.querySelectorAll('.route-item').forEach(item => {
            const routeId = item.dataset.routeId;
            const route = this.routes.find(r => r.id === routeId);
            if (!route) return;
            
            // Toggle collapse on header click
            const header = item.querySelector('.route-item-header');
            header.addEventListener('click', (e) => {
                e.stopPropagation();
                item.classList.toggle('expanded');
            });
            
            // Handle action buttons
            item.querySelectorAll('.route-action-btn').forEach(btn => {
                btn.addEventListener('click', async (e) => {
                    e.stopPropagation();
                    const action = btn.dataset.action;
                    this.selectedRoute = route;
                    
                    switch(action) {
                        case 'view':
                            this.focusRoute(route);
                            break;
                        case 'export-geojson':
                            await this.exportRoute('geojson');
                            break;
                        case 'export-gpx':
                            await this.exportRoute('gpx');
                            break;
                        case 'edit':
                            this.closeModal('routes-modal');
                            this.startEditingRoute();
                            break;
                        case 'delete':
                            await this.deleteRouteInline();
                            break;
                    }
                });
            });
        });
    }

    focusRoute(route) {
        const coordinates = route.geojson.geometry.coordinates.map(c => [c[1], c[0]]);
        const bounds = L.latLngBounds(coordinates);
        this.map.fitBounds(bounds, { padding: [50, 50] });
    }

    calculateRouteDistance(coordinates) {
        // Calculate distance using Haversine formula
        if (coordinates.length < 2) return 0;
        
        let totalDistance = 0;
        
        for (let i = 0; i < coordinates.length - 1; i++) {
            const [lon1, lat1] = coordinates[i];
            const [lon2, lat2] = coordinates[i + 1];
            
            const R = 6371000; // Earth radius in meters
            const φ1 = lat1 * Math.PI / 180;
            const φ2 = lat2 * Math.PI / 180;
            const Δφ = (lat2 - lat1) * Math.PI / 180;
            const Δλ = (lon2 - lon1) * Math.PI / 180;
            
            const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
                      Math.cos(φ1) * Math.cos(φ2) *
                      Math.sin(Δλ/2) * Math.sin(Δλ/2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
            
            totalDistance += R * c;
        }
        
        return totalDistance;
    }

    startEditingRoute() {
        if (!this.selectedRoute || this.selectedRoute.user_id !== this.currentUser.id) {
            return;
        }

        this.isEditingRoute = true;
        this.editingRouteId = this.selectedRoute.id;
        this.closeModal('details-modal');

        const layerData = this.routeLayers.get(this.editingRouteId);
        if (!layerData) return;

        // Disable popup on polyline to prevent blocking
        layerData.polyline.unbindPopup();
        layerData.polyline.setStyle({ opacity: 0.3, weight: 9 });
        
        // Disable click events on polyline during editing
        layerData.polyline.off('click');

        // Create draggable markers for each waypoint
        const coordinates = this.selectedRoute.geojson.geometry.coordinates;
        this.editMarkers = coordinates.map((coord, index) => {
            const marker = L.marker([coord[1], coord[0]], {
                draggable: true,
                icon: this.createWaypointIcon(this.selectedRoute.color, index + 1)
            }).addTo(this.map);

            marker.waypointIndex = index;

            // Show tooltip on hover instead of popup
            marker.bindTooltip(`Waypoint ${index + 1}`, {
                permanent: false,
                direction: 'top',
                offset: [0, -15]
            });

            marker.on('drag', () => {
                this.updateEditPolyline();
                this.updateEditStatus();
            });

            // Right-click or long-press to remove waypoint
            marker.on('contextmenu', (e) => {
                L.DomEvent.preventDefault(e);
                if (this.editMarkers.length > 2) {
                    this.removeWaypoint(index);
                } else {
                    alert('A route must have at least 2 waypoints');
                }
            });

            // Don't add click handler - it interferes with dragging
            // Just show tooltip on hover instead

            return marker;
        });

        // Allow clicking on map to add new waypoints
        this.map.on('click', this.handleEditMapClick);

        // Show editing UI
        document.getElementById('draw-route-btn').style.display = 'none';
        this.updateEditStatus();

        // Show edit panel at bottom
        document.getElementById('edit-panel').classList.add('active');
    }

    updateEditStatus() {
        const status = document.getElementById('drawing-status');
        const distance = this.calculateRouteDistance(
            this.editMarkers.map(m => {
                const ll = m.getLatLng();
                return [ll.lng, ll.lat];
            })
        );
        const distanceKm = (distance / 1000).toFixed(2);
        
        status.innerHTML = `
            <strong>Editing: ${this.selectedRoute.name}</strong><br>
            ${this.editMarkers.length} waypoints • ${distanceKm} km<br>
            <small>Drag markers • Click map to add • Right-click to remove</small>
        `;
        status.classList.add('active');
    }

    showWaypointInfo(number, lat, lng) {
        const status = document.getElementById('drawing-status');
        const distance = this.calculateRouteDistance(
            this.editMarkers.map(m => {
                const ll = m.getLatLng();
                return [ll.lng, ll.lat];
            })
        );
        const distanceKm = (distance / 1000).toFixed(2);
        
        status.innerHTML = `
            <strong>Waypoint ${number}</strong><br>
            ${lat.toFixed(6)}, ${lng.toFixed(6)}<br>
            Total: ${this.editMarkers.length} waypoints • ${distanceKm} km<br>
            <small>Drag to move • Right-click to delete</small>
        `;
        
        // Reset to normal status after 3 seconds
        setTimeout(() => {
            if (this.isEditingRoute) {
                this.updateEditStatus();
            }
        }, 3000);
    }

    handleEditMapClick = (e) => {
        if (!this.isEditingRoute) return;

        // Find the closest position in the route to insert the new waypoint
        const newLatLng = e.latlng;
        let closestIndex = 0;
        let minDist = Infinity;

        for (let i = 0; i < this.editMarkers.length - 1; i++) {
            const p1 = this.editMarkers[i].getLatLng();
            const p2 = this.editMarkers[i + 1].getLatLng();
            const dist = this.distanceToSegment(newLatLng, p1, p2);
            if (dist < minDist) {
                minDist = dist;
                closestIndex = i + 1;
            }
        }

        // Create new marker
        const marker = L.marker(newLatLng, {
            draggable: true,
            icon: this.createWaypointIcon(this.selectedRoute.color, closestIndex + 1)
        }).addTo(this.map);

        marker.on('drag', () => {
            this.updateEditPolyline();
            this.updateEditStatus();
        });

        marker.on('contextmenu', (e) => {
            L.DomEvent.preventDefault(e);
            if (this.editMarkers.length > 2) {
                const idx = this.editMarkers.indexOf(marker);
                this.removeWaypoint(idx);
            } else {
                alert('A route must have at least 2 waypoints');
            }
        });

        marker.on('click', (e) => {
            L.DomEvent.stopPropagation(e);
            const latlng = marker.getLatLng();
            const idx = this.editMarkers.indexOf(marker);
            this.showWaypointInfo(idx + 1, latlng.lat, latlng.lng);
        });

        // Add tooltip
        marker.bindTooltip(`Waypoint ${closestIndex + 1}`, {
            permanent: false,
            direction: 'top',
            offset: [0, -15]
        });

        this.editMarkers.splice(closestIndex, 0, marker);
        this.updateWaypointNumbers();
        this.updateEditPolyline();
    }

    distanceToSegment(point, lineStart, lineEnd) {
        const x = point.lng;
        const y = point.lat;
        const x1 = lineStart.lng;
        const y1 = lineStart.lat;
        const x2 = lineEnd.lng;
        const y2 = lineEnd.lat;

        const A = x - x1;
        const B = y - y1;
        const C = x2 - x1;
        const D = y2 - y1;

        const dot = A * C + B * D;
        const lenSq = C * C + D * D;
        let param = -1;

        if (lenSq !== 0) param = dot / lenSq;

        let xx, yy;

        if (param < 0) {
            xx = x1;
            yy = y1;
        } else if (param > 1) {
            xx = x2;
            yy = y2;
        } else {
            xx = x1 + param * C;
            yy = y1 + param * D;
        }

        const dx = x - xx;
        const dy = y - yy;
        return Math.sqrt(dx * dx + dy * dy);
    }

    removeWaypoint(index) {
        if (this.editMarkers.length <= 2) {
            alert('A route must have at least 2 waypoints');
            return;
        }

        const marker = this.editMarkers[index];
        this.map.removeLayer(marker);
        this.editMarkers.splice(index, 1);
        this.updateWaypointNumbers();
        this.updateEditPolyline();
        this.updateEditStatus();
    }

    updateWaypointNumbers() {
        this.editMarkers.forEach((marker, index) => {
            marker.setIcon(this.createWaypointIcon(this.selectedRoute.color, index + 1));
            // Update tooltip
            marker.unbindTooltip();
            marker.bindTooltip(`Waypoint ${index + 1}`, {
                permanent: false,
                direction: 'top',
                offset: [0, -15]
            });
        });
    }

    updateEditPolyline() {
        const layerData = this.routeLayers.get(this.editingRouteId);
        if (!layerData) return;

        const coordinates = this.editMarkers.map(marker => marker.getLatLng());
        layerData.polyline.setLatLngs(coordinates);
    }

    createWaypointIcon(color, number) {
        return L.divIcon({
            className: 'waypoint-marker',
            html: `<div style="background: ${color}; color: white; width: 28px; height: 28px; border-radius: 50%; border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 12px;">${number}</div>`,
            iconSize: [28, 28],
            iconAnchor: [14, 14]
        });
    }

    async saveEditedRoute() {
        if (!this.editingRouteId || this.editMarkers.length < 2) {
            alert('A route must have at least 2 waypoints');
            return;
        }

        const coordinates = this.editMarkers.map(marker => {
            const latlng = marker.getLatLng();
            return [latlng.lng, latlng.lat];
        });

        const geojson = {
            type: 'Feature',
            geometry: {
                type: 'LineString',
                coordinates: coordinates
            },
            properties: {
                name: this.selectedRoute.name,
                description: this.selectedRoute.description
            }
        };

        try {
            const response = await fetch(`/api/routes/${this.editingRouteId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    name: this.selectedRoute.name,
                    description: this.selectedRoute.description,
                    geojson
                })
            });

            if (response.ok) {
                const data = await response.json();
                const index = this.routes.findIndex(r => r.id === this.editingRouteId);
                if (index !== -1) {
                    this.routes[index] = data.route;
                }
                this.addRouteToMap(data.route);
                this.cancelEditingRoute();
                document.getElementById('edit-panel').classList.remove('active');
            } else {
                alert('Failed to update route');
            }
        } catch (error) {
            console.error('Error updating route:', error);
            alert('Error updating route');
        }
    }

    cancelEditingRoute() {
        this.isEditingRoute = false;
        this.map.off('click', this.handleEditMapClick);

        // Remove edit markers
        this.editMarkers.forEach(marker => this.map.removeLayer(marker));
        this.editMarkers = [];

        // Restore original polyline
        if (this.editingRouteId) {
            const layerData = this.routeLayers.get(this.editingRouteId);
            if (layerData) {
                layerData.polyline.setStyle({ opacity: 0.8, weight: 9 });
                // Restore to saved coordinates
                const route = this.routes.find(r => r.id === this.editingRouteId);
                if (route) {
                    const coordinates = route.geojson.geometry.coordinates.map(c => [c[1], c[0]]);
                    layerData.polyline.setLatLngs(coordinates);
                    
                    // Re-enable popup and click
                    const distance = this.calculateRouteDistance(route.geojson.geometry.coordinates);
                    layerData.polyline.bindPopup(`
                        <div class="route-popup">
                            <h3>${route.name}</h3>
                            <p><strong>By:</strong> ${route.username}</p>
                            ${route.description ? `<p>${route.description}</p>` : ''}
                            <p><strong>Distance:</strong> ${(distance / 1000).toFixed(2)} km</p>
                            ${route.user_id === this.currentUser.id ? '<p><em>Click "Edit" in details to modify waypoints</em></p>' : ''}
                        </div>
                    `);
                    layerData.polyline.on('click', () => {
                        this.showRouteDetails(route);
                    });
                }
            }
        }

        this.editingRouteId = null;
        document.getElementById('drawing-status').classList.remove('active');
        document.getElementById('draw-route-btn').style.display = 'block';
        document.getElementById('edit-panel').classList.remove('active');
    }

    toggleRecording() {
        if (this.isRecordingRoute) {
            this.stopRecording();
        } else {
            this.startRecording();
        }
    }

    startRecording() {
        if (!navigator.geolocation) {
            alert('Geolocation is not supported by your browser');
            return;
        }

        if (this.isDrawing) {
            alert('Please finish or cancel manual drawing first');
            return;
        }

        this.isRecordingRoute = true;
        this.recordedPoints = [];
        this.recordingStartTime = Date.now();

        // Update UI
        document.getElementById('draw-route-btn').style.display = 'none';
        document.getElementById('record-route-btn').classList.add('active');

        const status = document.getElementById('drawing-status');
        status.innerHTML = `
            <div style="display: flex; align-items: center; justify-content: center; gap: 0.5rem;">
                <img src="/icons/point.svg" alt="" width="20" height="20" style="filter: invert(1);">
                <strong>Recording Route</strong>
            </div>
            <span id="recording-stats">0 points • 0.00 km</span><br>
            <small>Move around to record your path</small>
        `;
        status.classList.add('active');

        // Start watching position
        this.locationWatchId = navigator.geolocation.watchPosition(
            (position) => {
                const lat = position.coords.latitude;
                const lng = position.coords.longitude;
                const accuracy = position.coords.accuracy;

                // Store current GPS location for instant warning placement
                this.currentGPSLocation = { lat, lng, accuracy };

                // Only add point if accuracy is reasonable (< 50m) and different from last point
                if (accuracy < 50) {
                    const shouldAdd = this.recordedPoints.length === 0 || 
                        this.getDistanceBetweenPoints(
                            [lng, lat],
                            this.recordedPoints[this.recordedPoints.length - 1]
                        ) > 5; // Only add if moved at least 5 meters

                    if (shouldAdd) {
                        this.recordedPoints.push([lng, lat]);
                        this.updateRecordingDisplay();
                    }
                }

                // Update live position marker
                if (this.userLocationMarker) {
                    this.map.removeLayer(this.userLocationMarker);
                }
                if (this.userLocationCircle) {
                    this.map.removeLayer(this.userLocationCircle);
                }

                const heading = position.coords.heading;
                const directionArrow = heading !== null ? 
                    `<div class="location-arrow" style="transform: rotate(${heading}deg)">▲</div>` : '';

                this.userLocationMarker = L.marker([lat, lng], {
                    icon: L.divIcon({
                        className: 'user-location-marker',
                        html: `
                            <div class="location-pulse recording"></div>
                            <div class="location-dot recording"></div>
                            ${directionArrow}
                        `,
                        iconSize: [40, 40],
                        iconAnchor: [20, 20]
                    })
                }).addTo(this.map);

                this.userLocationCircle = L.circle([lat, lng], {
                    radius: accuracy,
                    color: '#FF0000',
                    fillColor: '#FF0000',
                    fillOpacity: 0.1,
                    weight: 1
                }).addTo(this.map);

                // Pan to current location
                this.map.panTo([lat, lng], { animate: true });

                // Broadcast live location to other users via WebSocket
                if (this.ws && this.ws.readyState === WebSocket.OPEN) {
                    this.ws.send(JSON.stringify({
                        type: 'location',
                        userId: this.currentUser.id,
                        username: this.currentUser.username,
                        color: this.currentUser.color,
                        lat: lat,
                        lng: lng,
                        heading: heading
                    }));
                }
            },
            (error) => {
                console.error('Recording error:', error);
                alert('Unable to record location');
                this.stopRecording();
            },
            {
                enableHighAccuracy: true,
                timeout: 30000,
                maximumAge: 0
            }
        );
    }

    stopRecording() {
        if (this.locationWatchId !== null) {
            navigator.geolocation.clearWatch(this.locationWatchId);
            this.locationWatchId = null;
        }

        this.isRecordingRoute = false;

        // Broadcast stop recording to other users
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify({
                type: 'location_stop',
                userId: this.currentUser.id
            }));
        }

        // Update UI
        document.getElementById('record-route-btn').classList.remove('active');
        document.getElementById('drawing-status').classList.remove('active');

        if (this.recordedPoints.length < 2) {
            alert('Not enough points recorded. Move around more and try again.');
            this.recordedPoints = [];
            document.getElementById('draw-route-btn').style.display = 'block';
            return;
        }

        // Create polyline preview
        const previewCoords = this.recordedPoints.map(p => [p[1], p[0]]);
        this.currentPolyline = L.polyline(previewCoords, {
            color: this.currentUser.color,
            weight: 12,
            opacity: 0.7
        }).addTo(this.map);

        // Fit map to recorded route
        const bounds = L.latLngBounds(previewCoords);
        this.map.fitBounds(bounds, { padding: [50, 50] });

        // Store as currentPoints for saving
        this.currentPoints = previewCoords.map(c => L.latLng(c[0], c[1]));

        // Show save modal
        this.openModal('route-modal');
    }

    updateRecordingDisplay() {
        if (!this.isRecordingRoute) return;

        const distance = this.calculateRouteDistance(this.recordedPoints);
        const distanceKm = (distance / 1000).toFixed(2);
        const duration = Math.floor((Date.now() - this.recordingStartTime) / 1000);
        const minutes = Math.floor(duration / 60);
        const seconds = duration % 60;

        // Draw the recorded path
        if (this.currentPolyline) {
            this.map.removeLayer(this.currentPolyline);
        }
        const coords = this.recordedPoints.map(p => [p[1], p[0]]);
        this.currentPolyline = L.polyline(coords, {
            color: '#FF0000',
            weight: 9,
            opacity: 0.8
        }).addTo(this.map);

        // Update stats
        const statsEl = document.getElementById('recording-stats');
        if (statsEl) {
            statsEl.textContent = `${this.recordedPoints.length} points • ${distanceKm} km • ${minutes}:${seconds.toString().padStart(2, '0')}`;
        }
    }

    getDistanceBetweenPoints(p1, p2) {
        const [lon1, lat1] = p1;
        const [lon2, lat2] = p2;
        
        const R = 6371000; // Earth radius in meters
        const φ1 = lat1 * Math.PI / 180;
        const φ2 = lat2 * Math.PI / 180;
        const Δφ = (lat2 - lat1) * Math.PI / 180;
        const Δλ = (lon2 - lon1) * Math.PI / 180;
        
        const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
                  Math.cos(φ1) * Math.cos(φ2) *
                  Math.sin(Δλ/2) * Math.sin(Δλ/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        
        return R * c;
    }

    toggleWarningMode() {
        if (this.isDrawing || this.isEditingRoute) {
            alert('Please finish current activity first');
            return;
        }

        // If tracking/recording, instantly add warning at current GPS location
        if ((this.isTrackingLocation || this.isRecordingRoute) && this.currentGPSLocation) {
            this.addInstantWarning();
            return;
        }

        this.isPlacingWarning = !this.isPlacingWarning;
        const btn = document.getElementById('add-warning-btn');
        
        if (this.isPlacingWarning) {
            btn.classList.add('active');
            this.map.getContainer().style.cursor = 'crosshair';
            
            // Add click handler to map
            this.warningMapClickHandler = (e) => {
                this.placeWarning(e.latlng);
            };
            this.map.on('click', this.warningMapClickHandler);
        } else {
            btn.classList.remove('active');
            this.map.getContainer().style.cursor = '';
            if (this.warningMapClickHandler) {
                this.map.off('click', this.warningMapClickHandler);
            }
        }
    }

    async addInstantWarning() {
        // Add warning immediately at current GPS location
        const btn = document.getElementById('add-warning-btn');
        btn.disabled = true;
        
        try {
            const response = await fetch('/api/warnings', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    type: 'warning',
                    description: 'Warning point',
                    lat: this.currentGPSLocation.lat,
                    lng: this.currentGPSLocation.lng
                })
            });
            
            if (response.ok) {
                const data = await response.json();
                this.addWarningToMap(data.warning);
                // Brief visual feedback
                btn.classList.add('active');
                setTimeout(() => btn.classList.remove('active'), 300);
            } else {
                alert('Failed to save warning');
            }
        } catch (error) {
            console.error('Error saving warning:', error);
            alert('Failed to save warning');
        } finally {
            btn.disabled = false;
        }
    }

    placeWarning(latlng) {
        // Store temporary location
        this.pendingWarningLocation = latlng;
        
        // Deactivate warning mode
        this.isPlacingWarning = false;
        document.getElementById('add-warning-btn').classList.remove('active');
        this.map.getContainer().style.cursor = '';
        if (this.warningMapClickHandler) {
            this.map.off('click', this.warningMapClickHandler);
        }
        
        // Show warning form modal
        this.openModal('warning-modal');
        
        // Setup form handlers
        const form = document.getElementById('warning-form');
        const cancelBtn = document.getElementById('cancel-warning-btn');
        
        // Remove old listeners
        const newForm = form.cloneNode(true);
        form.parentNode.replaceChild(newForm, form);
        const newCancelBtn = document.getElementById('cancel-warning-btn');
        
        newForm.addEventListener('submit', (e) => this.handleSaveWarning(e));
        newCancelBtn.addEventListener('click', () => {
            this.closeModal('warning-modal');
            newForm.reset();
            this.pendingWarningLocation = null;
        });
    }

    async handleSaveWarning(e) {
        e.preventDefault();
        
        const submitBtn = e.target.querySelector('button[type="submit"]');
        if (submitBtn.disabled) return;
        submitBtn.disabled = true;
        submitBtn.textContent = 'Saving...';
        
        const description = document.getElementById('warning-description').value.trim() || 'Warning point';
        
        try {
            const response = await fetch('/api/warnings', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    type: 'warning',
                    description,
                    lat: this.pendingWarningLocation.lat,
                    lng: this.pendingWarningLocation.lng
                })
            });
            
            if (response.ok) {
                const data = await response.json();
                this.addWarningToMap(data.warning);
                
                this.closeModal('warning-modal');
                document.getElementById('warning-form').reset();
                this.pendingWarningLocation = null;
            } else {
                alert('Failed to save warning');
            }
        } catch (error) {
            console.error('Error saving warning:', error);
            alert('Error saving warning');
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = 'Save Warning';
        }
    }

    addWarningToMap(warning) {
        // Remove existing marker if any
        if (this.warningMarkers.has(warning.id)) {
            const oldMarker = this.warningMarkers.get(warning.id);
            this.map.removeLayer(oldMarker);
        }
        
        const marker = L.marker([warning.lat, warning.lng], {
            icon: L.divIcon({
                className: 'warning-marker',
                html: `
                    <div class="warning-icon" style="background: ${warning.user_color || '#FFA500'};">
                        <img src="/icons/alert-triangle.svg" alt="" width="20" height="20" style="filter: invert(1);">
                    </div>
                `,
                iconSize: [36, 36],
                iconAnchor: [18, 18]
            }),
            zIndexOffset: 1000
        }).addTo(this.map);
        
        marker.bindPopup(`
            <div class="warning-popup">
                <h4><img src="/icons/alert-triangle.svg" alt="" width="16" height="16" style="display:inline; vertical-align: middle; margin-right: 0.25rem;"> Warning</h4>
                ${warning.description ? `<p>${warning.description}</p>` : ''}
                <small>By: ${warning.username}</small>
                ${warning.user_id === this.currentUser.id ? '<br><button class="btn-danger" onclick="app.deleteWarning(\'' + warning.id + '\')">Delete</button>' : ''}
            </div>
        `);
        
        this.warningMarkers.set(warning.id, marker);
    }

    async loadWarnings() {
        try {
            const response = await fetch('/api/warnings');
            if (response.ok) {
                const data = await response.json();
                data.warnings.forEach(warning => this.addWarningToMap(warning));
            }
        } catch (error) {
            console.error('Error loading warnings:', error);
        }
    }

    async deleteWarning(warningId) {
        if (!confirm('Delete this warning?')) {
            return;
        }
        
        try {
            const response = await fetch(`/api/warnings/${warningId}`, {
                method: 'DELETE'
            });
            
            if (response.ok) {
                const marker = this.warningMarkers.get(warningId);
                if (marker) {
                    this.map.removeLayer(marker);
                    this.warningMarkers.delete(warningId);
                }
            } else {
                alert('Failed to delete warning');
            }
        } catch (error) {
            console.error('Error deleting warning:', error);
            alert('Error deleting warning');
        }
    }

    showRouteDetails(route) {
        this.selectedRoute = route;
        
        const modal = document.getElementById('details-modal');
        document.getElementById('details-title').textContent = route.name;
        
        // Calculate distance
        const distance = this.calculateRouteDistance(route.geojson.geometry.coordinates);
        const distanceKm = (distance / 1000).toFixed(2);
        const distanceMiles = (distance / 1609.34).toFixed(2);
        
        // Fix date parsing
        let dateStr = 'Unknown';
        if (route.created_at) {
            try {
                const date = new Date(route.created_at);
                if (!isNaN(date.getTime())) {
                    dateStr = date.toLocaleString();
                }
            } catch (e) {
                dateStr = route.created_at;
            }
        }
        
        const content = document.getElementById('details-content');
        content.innerHTML = `
            <p><strong>Created by:</strong> ${route.username}</p>
            <p><strong>Date:</strong> ${dateStr}</p>
            ${route.description ? `<p><strong>Description:</strong> ${route.description}</p>` : ''}
            <p><strong>Waypoints:</strong> ${route.geojson.geometry.coordinates.length}</p>
            <p><strong>Distance:</strong> ${distanceKm} km (${distanceMiles} mi)</p>
        `;
        
        // Show edit and delete buttons only for own routes
        const isOwner = route.user_id === this.currentUser.id;
        document.getElementById('delete-route-btn').style.display = isOwner ? 'inline-block' : 'none';
        document.getElementById('edit-route-btn').style.display = isOwner ? 'inline-block' : 'none';
        
        this.openModal('details-modal');
    }

    async exportRoute(format) {
        if (!this.selectedRoute) return;
        
        try {
            const response = await fetch(`/api/routes/${this.selectedRoute.id}/export?format=${format}`);
            if (response.ok) {
                const blob = await response.blob();
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `${this.selectedRoute.name}.${format === 'gpx' ? 'gpx' : 'geojson'}`;
                document.body.appendChild(a);
                a.click();
                window.URL.revokeObjectURL(url);
                document.body.removeChild(a);
            }
        } catch (error) {
            console.error('Export error:', error);
            alert('Failed to export route');
        }
    }

    async deleteRouteInline() {
        if (!this.selectedRoute) return;
        
        if (!confirm(`Delete route "${this.selectedRoute.name}"?`)) {
            return;
        }
        
        try {
            const response = await fetch(`/api/routes/${this.selectedRoute.id}`, {
                method: 'DELETE'
            });
            
            if (response.ok) {
                // Remove from map
                const layerData = this.routeLayers.get(this.selectedRoute.id);
                if (layerData) {
                    this.map.removeLayer(layerData.polyline);
                    if (layerData.markers) {
                        layerData.markers.forEach(marker => this.map.removeLayer(marker));
                    }
                    this.routeLayers.delete(this.selectedRoute.id);
                }
                
                // Remove from routes array
                this.routes = this.routes.filter(r => r.id !== this.selectedRoute.id);
                this.updateRoutesList();
                
                this.selectedRoute = null;
            } else {
                alert('Failed to delete route');
            }
        } catch (error) {
            console.error('Delete error:', error);
            alert('Failed to delete route');
        }
    }

    async deleteRoute() {
        if (!this.selectedRoute) return;
        
        if (!confirm(`Delete route "${this.selectedRoute.name}"?`)) {
            return;
        }
        
        try {
            const response = await fetch(`/api/routes/${this.selectedRoute.id}`, {
                method: 'DELETE'
            });
            
            if (response.ok) {
                // Remove from map
                const layerData = this.routeLayers.get(this.selectedRoute.id);
                if (layerData) {
                    this.map.removeLayer(layerData.polyline);
                    if (layerData.markers) {
                        layerData.markers.forEach(marker => this.map.removeLayer(marker));
                    }
                    this.routeLayers.delete(this.selectedRoute.id);
                }
                
                // Remove from routes array
                this.routes = this.routes.filter(r => r.id !== this.selectedRoute.id);
                this.updateRoutesList();
                
                this.closeModal('details-modal');
                this.selectedRoute = null;
            } else {
                alert('Failed to delete route');
            }
        } catch (error) {
            console.error('Delete error:', error);
            alert('Failed to delete route');
        }
    }

    connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        this.ws = new WebSocket(`${protocol}//${window.location.host}`);
        
        this.ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            
            if (data.type === 'new') {
                // Check if route already exists (from HTTP response)
                const existingIndex = this.routes.findIndex(r => r.id === data.route.id);
                if (existingIndex === -1) {
                    // New route - add it
                    this.routes.push(data.route);
                    this.addRouteToMap(data.route);
                    this.updateRoutesList();
                } else {
                    // Route already exists - update it with complete data from server
                    // (WebSocket has complete data with created_at that might have arrived after HTTP response)
                    this.routes[existingIndex] = data.route;
                    this.addRouteToMap(data.route);
                    this.updateRoutesList();
                }
            } else if (data.type === 'update') {
                // Update existing route
                const index = this.routes.findIndex(r => r.id === data.route.id);
                if (index !== -1) {
                    this.routes[index] = data.route;
                    this.addRouteToMap(data.route);
                    this.updateRoutesList();
                }
            } else if (data.type === 'delete') {
                // Remove deleted route
                const layerData = this.routeLayers.get(data.routeId);
                if (layerData) {
                    this.map.removeLayer(layerData.polyline);
                    if (layerData.markers) {
                        layerData.markers.forEach(marker => this.map.removeLayer(marker));
                    }
                    this.routeLayers.delete(data.routeId);
                }
                this.routes = this.routes.filter(r => r.id !== data.routeId);
                this.updateRoutesList();
            } else if (data.type === 'location') {
                // Live location update from another user
                if (data.userId !== this.currentUser.id) {
                    this.updateLiveUserMarker(data);
                }
            } else if (data.type === 'location_stop') {
                // User stopped recording, remove their marker
                if (data.userId !== this.currentUser.id) {
                    this.removeLiveUserMarker(data.userId);
                }
            } else if (data.type === 'warning_new') {
                // New warning added
                this.addWarningToMap(data.warning);
            } else if (data.type === 'warning_delete') {
                // Warning deleted
                const marker = this.warningMarkers.get(data.warningId);
                if (marker) {
                    this.map.removeLayer(marker);
                    this.warningMarkers.delete(data.warningId);
                }
            }
        };
        
        this.ws.onclose = () => {
            // Reconnect after 5 seconds
            setTimeout(() => this.connectWebSocket(), 5000);
        };
    }

    openModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.add('active');
        }
    }

    closeModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.remove('active');
        }
    }

    locateMe() {
        if (!navigator.geolocation) {
            alert('Geolocation is not supported by your browser');
            return;
        }

        const btn = document.getElementById('locate-me-btn');
        
        // Toggle tracking mode
        if (this.isTrackingLocation) {
            this.stopTracking();
            return;
        }
        
        btn.classList.add('active');
        btn.disabled = true;
        this.isTrackingLocation = true;

        // Start watching position for live tracking
        this.locationWatchId = navigator.geolocation.watchPosition(
            (position) => {
                const lat = position.coords.latitude;
                const lng = position.coords.longitude;
                const accuracy = position.coords.accuracy;
                const heading = position.coords.heading; // Direction of movement
                const speed = position.coords.speed; // Speed in m/s

                // Store current GPS location for instant warning placement
                this.currentGPSLocation = { lat, lng, accuracy };

                // Update heading if available, otherwise keep last
                if (heading !== null && !isNaN(heading)) {
                    this.lastHeading = heading;
                }

                // Center map on user location (only first time or if marker doesn't exist)
                if (!this.userLocationMarker) {
                    this.map.setView([lat, lng], 16);
                } else {
                    // Smoothly pan to new location
                    this.map.panTo([lat, lng], { animate: true, duration: 0.5 });
                }

                // Remove old markers
                if (this.userLocationMarker) {
                    this.map.removeLayer(this.userLocationMarker);
                }
                if (this.userLocationCircle) {
                    this.map.removeLayer(this.userLocationCircle);
                }

                // Create direction indicator HTML
                const directionArrow = heading !== null ? 
                    `<div class="location-arrow" style="transform: rotate(${heading}deg)">▲</div>` : '';
                
                // Create pulsing marker with direction
                this.userLocationMarker = L.marker([lat, lng], {
                    icon: L.divIcon({
                        className: 'user-location-marker',
                        html: `
                            <div class="location-pulse"></div>
                            <div class="location-dot"></div>
                            ${directionArrow}
                        `,
                        iconSize: [40, 40],
                        iconAnchor: [20, 20]
                    })
                }).addTo(this.map);

                // Build popup content
                const speedKmh = speed !== null ? (speed * 3.6).toFixed(1) : 'N/A';
                const headingDeg = heading !== null ? Math.round(heading) : 'N/A';
                const directionStr = this.getCompassDirection(heading);

                this.userLocationMarker.bindPopup(`
                    <div class="route-popup">
                        <h3><img src="/icons/current-location.svg" alt="" width="20" height="20" style="display:inline; vertical-align: middle; margin-right: 0.5rem;"> Your Location (Live)</h3>
                        <p><strong>Coordinates:</strong><br>${lat.toFixed(6)}, ${lng.toFixed(6)}</p>
                        <p><strong>Accuracy:</strong> ±${Math.round(accuracy)}m</p>
                        ${heading !== null ? `<p><strong>Heading:</strong> ${headingDeg}° (${directionStr})</p>` : ''}
                        ${speed !== null ? `<p><strong>Speed:</strong> ${speedKmh} km/h</p>` : ''}
                        <p><em>Tracking live...</em></p>
                    </div>
                `);

                // Show accuracy circle
                this.userLocationCircle = L.circle([lat, lng], {
                    radius: accuracy,
                    color: '#4285F4',
                    fillColor: '#4285F4',
                    fillOpacity: 0.1,
                    weight: 1
                }).addTo(this.map);

                btn.classList.add('active');
                btn.title = 'Stop Tracking';
                btn.disabled = false;
            },
            (error) => {
                console.error('Geolocation error:', error);
                let message = 'Unable to get your location';
                if (error.code === error.PERMISSION_DENIED) {
                    message = 'Location access denied. Please enable location permissions.';
                } else if (error.code === error.POSITION_UNAVAILABLE) {
                    message = 'Location information unavailable.';
                } else if (error.code === error.TIMEOUT) {
                    message = 'Location request timed out.';
                }
                alert(message);
                this.stopTracking();
            },
            {
                enableHighAccuracy: true,
                timeout: 30000,
                maximumAge: 0
            }
        );
    }

    stopTracking() {
        if (this.locationWatchId !== null) {
            navigator.geolocation.clearWatch(this.locationWatchId);
            this.locationWatchId = null;
        }
        
        this.isTrackingLocation = false;
        
        const btn = document.getElementById('locate-me-btn');
        btn.classList.remove('active');
        btn.title = 'Show My Location';
        btn.disabled = false;
        
        // Keep markers visible but stop updating
        if (this.userLocationMarker) {
            const popup = this.userLocationMarker.getPopup();
            if (popup) {
                const content = popup.getContent();
                popup.setContent(content.replace('Tracking live...', 'Tracking stopped'));
            }
        }
    }

    getCompassDirection(heading) {
        if (heading === null || isNaN(heading)) return 'Unknown';
        
        const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
        const index = Math.round(heading / 45) % 8;
        return directions[index];
    }

    updateLiveUserMarker(data) {
        const { userId, username, color, lat, lng, heading } = data;
        
        // Remove existing marker if present
        if (this.liveUserMarkers.has(userId)) {
            const oldMarker = this.liveUserMarkers.get(userId);
            this.map.removeLayer(oldMarker);
        }
        
        // Create direction arrow if heading is available
        const directionArrow = heading !== null ? 
            `<div class="location-arrow" style="transform: rotate(${heading}deg)">▲</div>` : '';
        
        // Create new marker
        const marker = L.marker([lat, lng], {
            icon: L.divIcon({
                className: 'live-user-marker',
                html: `
                    <div class="location-pulse" style="background: ${color};"></div>
                    <div class="location-dot" style="background: ${color};"></div>
                    ${directionArrow}
                `,
                iconSize: [40, 40],
                iconAnchor: [20, 20]
            }),
            zIndexOffset: 900
        }).addTo(this.map);
        
        marker.bindPopup(`
            <div style="text-align: center;">
                <strong style="color: ${color};"><img src="/icons/point.svg" alt="" width="16" height="16" style="display:inline; vertical-align: middle; filter: invert(1);"> ${username}</strong><br>
                <small>Recording route...</small>
            </div>
        `);
        
        this.liveUserMarkers.set(userId, marker);
    }

    removeLiveUserMarker(userId) {
        if (this.liveUserMarkers.has(userId)) {
            const marker = this.liveUserMarkers.get(userId);
            this.map.removeLayer(marker);
            this.liveUserMarkers.delete(userId);
        }
    }
}

// Initialize the app
const app = new RouteMaker();
