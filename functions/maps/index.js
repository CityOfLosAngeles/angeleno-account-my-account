const {onRequest} = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const express = require('express');



admin.initializeApp();
const app = express();

const {
    corsProxyAutofill,
    corsProxyPlaceDetails
   
} = require('./api/maps.js');

app.use(express.json());

app.get('/corsProxyAutofill', corsProxyAutofill);
app.get('/corsProxyPlaceDetails', corsProxyPlaceDetails);

//export const maps = onRequest(app);
exports.maps = onRequest(app);
