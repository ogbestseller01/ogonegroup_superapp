// src/hooks/useTechnicianHeartbeat.js
import { useEffect, useState, useRef } from 'react';
import technicianHeartbeatService from 'services/technicianHeartbeat.service';

/**
 * Drives the heartbeat loop for a technician while `isOnline` is true.
 * Also forces an immediate send when the browser tab regains focus,
 * since location may be stale after being backgrounded.
 */
export function useTechnicianHeartbeat(isOnline) {
    const [state, setState] = useState({
        isRunning: false,
        lastSentAt: null,
        lastError: null,
    });
    const wasOnline = useRef(isOnline);

    useEffect(() => {
        const unsubscribe = technicianHeartbeatService.subscribe(setState);
        return unsubscribe;
    }, []);

    useEffect(() => {
        if (isOnline) {
            technicianHeartbeatService.start();
        } else {
            technicianHeartbeatService.stop();
        }
        wasOnline.current = isOnline;
    }, [isOnline]);

    useEffect(() => {
        const handleVisibility = () => {
            if (document.visibilityState === 'visible' && wasOnline.current) {
                technicianHeartbeatService.sendNow();
            }
        };
        document.addEventListener('visibilitychange', handleVisibility);
        return () => document.removeEventListener('visibilitychange', handleVisibility);
    }, []);

    useEffect(() => {
        // Safety: stop the loop if the technician navigates away/unmounts the app shell
        return () => technicianHeartbeatService.stop();
    }, []);

    return state; // { isRunning, lastSentAt, lastError }
}

export default useTechnicianHeartbeat;