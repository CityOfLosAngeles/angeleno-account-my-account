import { onRequest } from 'firebase-functions/v2/https';
import admin from 'firebase-admin';
import express from 'express';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import { setGlobalOptions } from 'firebase-functions/v2';
import { auth0Domain } from './utils/constants.js';

import {
  updateUser,
  updatePassword,
  enrollMFA,
  confirmMFA,
  authMethods,
  unenrollMFA,
  removeConnection,
  challengeMfa,
  requestMFAToken
} from './api/auth0.js';

import rateLimit from 'express-rate-limit';

admin.initializeApp();
setGlobalOptions({
  region: 'us-west1'
})
const app = express();

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(limiter);

const client = jwksClient({
  jwksUri: `https://${auth0Domain}/.well-known/jwks.json`
});

function getKey(header, callback){
  client.getSigningKey(header.kid, function(err, key) {
    var signingKey = key.publicKey || key.rsaPublicKey;
    callback(null, signingKey);
  });
}

app.use((req, res, next) => {

  const accessTokenHeader = req.headers['X-ACCESS-TOKEN'] || req.headers['x-access-token'];
  const userId = req.body.userId || req.query.userId;

  if (!accessTokenHeader) {
    return res.status(401).send('Unauthorized: No token provided');
  }

  jwt.verify(accessTokenHeader, getKey, (err, decoded) => {
    if (err) {
      console.error('Token verification failed:', err);
      return res.status(401).send('Unauthorized: Invalid token');
    }

    if (decoded.sub !== userId) {
      return res.status(401).send('Unauthorized: User ID does not match token subject');
    }

    next();
  });
});

app.use(express.json());

app.get('/auth0/authMethods', authMethods);
app.post('/auth0/updateUser', updateUser);
app.post('/auth0/updatePassword', updatePassword);
app.post('/auth0/enrollMFA', enrollMFA);
app.post('/auth0/confirmMFA', confirmMFA);
app.post('/auth0/unenrollMFA', unenrollMFA);
app.post('/auth0/removeConnection', removeConnection);
app.post('/auth0/challengeMfa', challengeMfa);
app.post('/auth0/requestMFAToken', requestMFAToken);

export const auth0 = onRequest(app);
