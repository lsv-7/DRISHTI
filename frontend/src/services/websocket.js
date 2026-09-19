let socket = null;
const listeners = new Set();

export function connectWebSocket(onMessageCallback) {
  if (onMessageCallback) {
    listeners.add(onMessageCallback);
  }

  if (socket && (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING)) {
    return socket;
  }

  try {
    socket = new WebSocket("ws://localhost:3000/api/v1/ws");

    socket.onopen = () => {
      console.log("[WebSocket] Connected to Disaster Coordination Stream");
    };

    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        listeners.forEach(callback => callback(data));
      } catch (err) {
        console.error("[WebSocket] Parse error:", err);
      }
    };

    socket.onerror = (err) => {
      console.warn("[WebSocket] Connection error:", err);
    };

    socket.onclose = () => {
      console.log("[WebSocket] Closed. Attempting reconnect in 5s...");
      setTimeout(() => connectWebSocket(), 5000);
    };
  } catch (err) {
    console.warn("[WebSocket] Setup error:", err);
  }

  return socket;
}

export function sendWebSocketEvent(type, payload) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify({ type, payload, timestamp: new Date().toISOString() }));
  }
}

export function disconnectWebSocket(callback) {
  if (callback) {
    listeners.delete(callback);
  }
}
