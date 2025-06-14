require('dotenv').config();
const express = require('express');
const cookieParser = require('cookie-parser');
const axios = require('axios');
const { createProxyMiddleware } = require('http-proxy-middleware');
const http = require('http');
const cors = require('cors');

const app = express();
app.use(cookieParser());

// CORS: Allow requests from your frontend domain
app.use(cors({
  origin: [
    'https://zackywacky.net',
    'https://planka.zackywacky.net',
    'http://localhost:3000',
    'https://localhost:3000',
    'http://127.0.0.1:3000',
    'https://127.0.0.1:3000'
  ],
  credentials: true,
}));

// Load from environment variables with fallbacks for manual testing
const PLANKA_URL = process.env.PLANKA_URL || 'http://localhost:4000';
const PLANKA_DEFAULT_USER_PASSWORD = process.env.PLANKA_DEFAULT_USER_PASSWORD || 'P@55w0rd';

console.log(`🌐 Planka URL: ${PLANKA_URL}`);
console.log(`🔑 Using default password: ${PLANKA_DEFAULT_USER_PASSWORD}`);

// Health check endpoint for Docker
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// This route logs in and gets all the proper cookies from Planka
app.get('/planka-login', async (req, res) => {
    const email = req.query.email || req.query.emailOrUsername;  // support both
    const password = PLANKA_DEFAULT_USER_PASSWORD;
  
    if (!email) {
      return res.status(400).send('Missing email');
    }
  
    try {
      // Make the login request with axios but capture the cookies
      const response = await axios.post(`${PLANKA_URL}/api/access-tokens`, {
        emailOrUsername: email,
        password,
      }, {
        // Enable cookie handling to capture all cookies from Planka
        withCredentials: true,
        // Don't follow redirects so we can handle them ourselves
        maxRedirects: 0
      });

      // The token is directly in response.data.item (it's a JWT string)
      const token = response.data.item;

      if (!token) {
        console.error('No token received in response:', response.data);
        return res.status(401).send('Login failed - no token received');
      }

      console.log(`✅ Login successful for: ${email}`);
      console.log(`🍪 Token received: ${token.substring(0, 20)}...`);
      
      // Extract cookies from the response headers if they exist
      const setCookieHeaders = response.headers['set-cookie'] || [];
      console.log('🍪 Cookies from Planka:', setCookieHeaders);

      // Store the token temporarily and redirect to our auth handler
      const redirectUrl = `${req.protocol}://${req.get('host')}/proxy-auth-login?token=${encodeURIComponent(token)}&email=${encodeURIComponent(email)}`;
      return res.redirect(redirectUrl);
      
    } catch (err) {
      console.error('Login failed:', err.response && err.response.data || err.message);
      res.status(401).send('Login failed');
    }
  });

// Special route to handle authentication - make a proper login to get httpOnlyToken
app.get('/proxy-auth-login', async (req, res) => {
  const token = req.query.token;
  const email = req.query.email;
  
  if (!token || !email) {
    return res.redirect('/');
  }
  
  console.log(`🍪 Setting up complete authentication for Planka...`);
  
  try {
    // Make a direct login request to Planka to get the httpOnlyToken  
    const loginResponse = await axios.post(`${PLANKA_URL}/api/access-tokens`, {
      emailOrUsername: email,
      password: PLANKA_DEFAULT_USER_PASSWORD,
    }, {
      withCredentials: true,
      validateStatus: () => true // Accept any status
    });
    
    // Extract all cookies from Planka's response
    const setCookieHeaders = loginResponse.headers['set-cookie'] || [];
    console.log('🍪 All cookies from Planka login:', setCookieHeaders);
    
    // Forward all the cookies from Planka to the client
    setCookieHeaders.forEach(cookie => {
      res.setHeader('Set-Cookie', cookie);
    });
    
    // Also manually set the tokens we know about
    res.cookie('accessToken', token, {
      path: '/',
      httpOnly: false,
      secure: false,  // Allow HTTP for localhost
      sameSite: 'Lax'
    });
    
    res.cookie('accessTokenVersion', '1', {
      path: '/',
      httpOnly: false,
      secure: false,  // Allow HTTP for localhost
      sameSite: 'Lax'
    });
    
  } catch (error) {
    console.error('Error getting full auth cookies:', error.message);
  }
  
  // Redirect to Planka dashboard
  return res.send(`
    <html>
      <head><title>Authentication Complete</title></head>
      <body>
        <h2>✅ Authentication set up successfully!</h2>
        <p>All cookies configured. Redirecting to Planka...</p>
        
        <script>
          console.log('🍪 All authentication cookies set');
          console.log('🔄 Redirecting to Planka...');
          
          // Redirect to the proxy server root (which proxies to Planka)
          setTimeout(() => {
            window.location.href = '/';
          }, 2000);
        </script>
        
        <p><a href="/">Click here if you are not redirected automatically</a></p>
      </body>
    </html>
  `);
});

// Simplified proxy configuration with basic WebSocket support
const proxy = createProxyMiddleware({
  target: PLANKA_URL,
  changeOrigin: true,
  ws: true, // Re-enable WebSocket support with simpler config
  logLevel: 'warn', // Reduce logging noise
  secure: false,
  
  // Basic request handling
  onProxyReq(proxyReq, req, res) {
    // Always forward cookies
    if (req.headers.cookie) {
      proxyReq.setHeader('Cookie', req.headers.cookie);
    }
    
    // Forward authentication for API requests
    if (req.cookies.accessToken) {
      proxyReq.setHeader('Authorization', `Bearer ${req.cookies.accessToken}`);
    }
  },
  
  // Basic WebSocket handling with origin header fix
  onProxyReqWs(proxyReq, req, socket) {
    console.log(`🔌 WebSocket upgrade: ${req.url}`);
    
    // Forward essential headers
    if (req.headers.cookie) {
      proxyReq.setHeader('Cookie', req.headers.cookie);
      console.log(`🍪 Forwarding cookies: ${req.headers.cookie.substring(0, 50)}...`);
    }
    
    // Fix the origin header to match what Planka expects
    proxyReq.setHeader('Origin', 'http://localhost:4000');
    console.log(`🌐 Setting origin header to: http://localhost:4000`);
  },
  
  onError(err, req, res) {
    console.error('❌ Proxy error:', err.message);
    if (res && res.writeHead && !res.headersSent) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Proxy error: ' + err.message);
    }
  }
});

// Handle all routes except login and our special auth route
app.use((req, res, next) => {
  // Skip proxy for our special routes
  if (req.path === '/planka-login' || req.path === '/proxy-auth-login') {
    return next();
  }
  // Proxy everything else to Planka
  return proxy(req, res, next);
});

const PORT = process.env.PROXY_PORT || 3001;

// Create HTTP server
const server = http.createServer(app);

// Simple WebSocket upgrade handling
server.on('upgrade', (req, socket, head) => {
  console.log(`🔌 WebSocket upgrade request: ${req.url}`);
  
  try {
    // Use the proxy to handle WebSocket upgrades
    proxy.upgrade(req, socket, head);
  } catch (error) {
    console.error('🔌 WebSocket upgrade error:', error.message);
    socket.destroy();
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Proxy server running at http://0.0.0.0:${PORT}`);
  console.log(`🔗 Access Planka login at: http://localhost:${PORT}/planka-login?email=user@example.com`);
  console.log(`🌐 After login, Planka will be available at: http://localhost:${PORT}/`);
  console.log(`🔌 WebSocket support enabled with simplified config`);
});
