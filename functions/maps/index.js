const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const axios = require("axios");
const express = require("express");

admin.initializeApp();
const app = express();

app.use(express.json());

const corsProxyAutofill = onRequest(async (req, res) => {
 
});

const corsProxyPlaceDetails = onRequest(async (req, res) => {
 
});

app.get("/maps/corsProxyPlaceDetails", corsProxyPlaceDetails);
app.get("/maps/corsProxyAutofill", corsProxyAutofill);

exports.maps = onRequest(app);
