import { onRequest } from 'firebase-functions/v2/https';
import admin from 'firebase-admin';
import express from 'express';

admin.initializeApp();
setGlobalOptions({
  region: 'us-west1'
})
const app = express();

import {
  updateUser,
  updatePassword,
  enrollMFA,
  confirmMFA,
  authMethods,
  unenrollMFA,
  removeConnection
} from './api/auth0.js';
import { setGlobalOptions } from 'firebase-functions/v2';

app.use(express.json());

app.post('/auth0/updateUser', updateUser);
app.post('/auth0/updatePassword', updatePassword);
app.post('/auth0/enrollMFA', enrollMFA);
app.post('/auth0/confirmMFA', confirmMFA);
app.get('/auth0/authMethods/:userId', authMethods);
app.post('/auth0/unenrollMFA', unenrollMFA);
app.post('/auth0/removeConnection', removeConnection);

export const auth0 = onRequest(app);