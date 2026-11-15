// src/services/technicianHeartbeat.service.js
import api from './api';

const HEARTBEAT_INTERVAL_MS = 120000; // 2 minutes
const MIN_MOVE_METERS = 15; // skip a "real" update if barely moved, still ping online status
const GEO_TIMEOUT_MS = 20000;

class TechnicianHeartbeatService {
    constructor() {
        this._timer = null;
        this._isRunning = false;
        this._isSending = false;
        this._lastPosition = null; // { latitude, longitude }
        this._lastSentAt = null;
        this._listeners = new Set(); // callback(state) on every status change
    }

    // ─── Public API ─────────────────────────────────────────
    start() {
        if (this._isRunning) return;
        this._isRunning = true;

        this._timer = setInterval(() => this._sendHeartbeat(), HEARTBEAT_INTERVAL_MS);

        // Send immediately so location isn't stale for up to 2 minutes
        this._sendHeartbeat();

        this._emit();
        console.log(`📡 Technician heartbeat started (every ${HEARTBEAT_INTERVAL_MS / 1000}s)`);
    }

    stop() {
        if (this._timer) clearInterval(this._timer);
        this._timer = null;
        this._isRunning = false;
        this._isSending = false;
        this._emit();
        console.log('📡 Technician heartbeat stopped');
    }

    /** Force an immediate send, e.g. right after toggling online, or on tab focus */
    sendNow() {
        return this._sendHeartbeat(true);
    }

    get isRunning() {
        return this._isRunning;
    }

    get lastSentAt() {
        return this._lastSentAt;
    }

    /** Subscribe to state changes: { isRunning, lastSentAt, lastError } */
    subscribe(callback) {
        this._listeners.add(callback);
        callback(this._getState());
        return () => this._listeners.delete(callback);
    }

    // ─── Internal ───────────────────────────────────────────
    _getState() {
        return {
            isRunning: this._isRunning,
            lastSentAt: this._lastSentAt,
            lastError: this._lastError || null,
        };
    }

    _emit() {
        const state = this._getState();
        this._listeners.forEach((cb) => cb(state));
    }

    async _sendHeartbeat(force = false) {
        if (this._isSending) return;
        this._isSending = true;

        try {
            const position = await this._getCurrentPosition();
            if (!position) {
                this._lastError = 'Location unavailable or permission denied';
                this._emit();
                return;
            }

            const { latitude, longitude } = position;

            if (!force && this._lastPosition) {
                const moved = this._distanceMeters(
                    this._lastPosition.latitude,
                    this._lastPosition.longitude,
                    latitude,
                    longitude
                );
                if (moved < MIN_MOVE_METERS) {
                    // still ping so technician doesn't get marked stale/offline
                    await api.post('/v2/technicians/heartbeat', { latitude, longitude });
                    this._lastSentAt = new Date();
                    this._lastError = null;
                    this._emit();
                    console.log(`📡 Heartbeat (idle ping): moved ${moved.toFixed(1)}m`);
                    return;
                }
            }

            await api.post('/v2/technicians/heartbeat', { latitude, longitude });

            this._lastPosition = { latitude, longitude };
            this._lastSentAt = new Date();
            this._lastError = null;
            this._emit();

            console.log(`📡 Heartbeat sent: ${latitude}, ${longitude}`);
        } catch (err) {
            this._lastError = err?.response?.data?.message || err.message || 'Heartbeat failed';
            this._emit();
            console.error('❌ Heartbeat error:', this._lastError);
            // Don't stop() — a single failed request shouldn't kill the loop.
        } finally {
            this._isSending = false;
        }
    }

    _getCurrentPosition() {
        return new Promise((resolve) => {
            if (!('geolocation' in navigator)) {
                resolve(null);
                return;
            }
            navigator.geolocation.getCurrentPosition(
                (pos) =>
                    resolve({
                        latitude: pos.coords.latitude,
                        longitude: pos.coords.longitude,
                    }),
                (err) => {
                    console.warn('Geolocation error:', err.message);
                    resolve(null);
                },
                {
                    enableHighAccuracy: true,
                    timeout: GEO_TIMEOUT_MS,
                    maximumAge: 0,
                }
            );
        });
    }

    _distanceMeters(lat1, lon1, lat2, lon2) {
        const R = 6371000; // Earth radius in meters
        const toRad = (deg) => (deg * Math.PI) / 180;
        const dLat = toRad(lat2 - lat1);
        const dLon = toRad(lon2 - lon1);
        const a =
            Math.sin(dLat / 2) ** 2 +
            Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}

// Singleton — one heartbeat loop per browser tab/session
export const technicianHeartbeatService = new TechnicianHeartbeatService();
export default technicianHeartbeatService;