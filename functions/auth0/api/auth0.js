import {onRequest} from 'firebase-functions/v2/https';
import axios from 'axios';
import {User} from '../models/user.js';

import {
  auth0Domain,
  auth0ClientId,
  auth0ClientSecret,
} from '../utils/constants.js';

import {getAccessToken, authorizeUser} from '../utils/auth0.js';

export const updateUser = onRequest(async (req, res) => {

  let user;
  let updatedUserObject = {};

  if (req.body.app_metadata) {
    user = {};
    user['userId'] = req.query.userId;
    updatedUserObject = req.body;
  } else {
    
    try {
      user = new User(req.body);
    } catch (err) {
      console.error(err);
      return res.status(400).send(err.message);
    }


    if (user.firstName) {
      updatedUserObject['given_name'] = user.firstName;
      updatedUserObject['name'] = user.firstName;
    }

    if (user.lastName) {
      updatedUserObject['family_name'] = user.lastName;
      updatedUserObject['name'] += ` ${user.lastName}`;
    }

    const primaryAddress = {};
    
    if (user.zip) {
      primaryAddress['zip'] = user.zip;
    }

    if (user.address) {
      primaryAddress['address'] = user.address;
    }

    if (user.address2) {
      primaryAddress['address2'] = user.address2;
    }

    if (user.state) {
      primaryAddress['state'] = user.state;
    }

    if (user.city) {
      primaryAddress['city'] = user.city;
    }

    const metaAddresses = user.metadata['addresses'];

    if (metaAddresses) {
      metaAddresses['primary'] = primaryAddress;
    } else {
      user.metadata = {
        addresses: {
          primary: primaryAddress,
        },
      };
    }

    user.metadata['phone'] = user.phone;

    updatedUserObject['user_metadata'] = user.metadata;
  
  }

  const updateUserUrl = `https://${auth0Domain}/api/v2/users/${user.userId}`;
  const token = await getAccessToken();
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': `Bearer ${token}`,
  };

  try {
    await axios.patch(updateUserUrl, updatedUserObject, {
      headers,
    });

    return res.status(200).send();
  } catch (err) {
    console.error(err);
    
    const {
      status = 500,
      message = '',
      data: {error_description},
    } = err.response;

    return res.status(status).send(message || error_description);
  }
});

export const updatePassword = onRequest(async (req, res) => {
  const body = req.body;

  const {
    email,
    oldPassword,
    newPassword,
    userId
  } = body;

  if (!email.length || !oldPassword.length ||
    !newPassword.length || !userId.length) {
    res.status(400).send('Invalid request - missing required fields.');
    return;
  }

  try {
    await authorizeUser(email, oldPassword);

    const auth0Token = await getAccessToken();
    const passwordUpdateRequest = {
      method: 'PATCH',
      url: `https://${auth0Domain}/api/v2/users/${userId}`,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${auth0Token}`,
      },
      data: {
        password: newPassword,
        connection: 'Angeleno-Account-Users',
      },
    };

    await axios.request(passwordUpdateRequest);

    res.status(200).send();
  } catch (err) {
    console.error(`Error: ${err.message}`);

    const {
      status = 500,
      data: {error_description, message},
    } = err?.response;

    if (message.toLowerCase().includes('passwordbreachederror')) {
      return res
        .status(status)
        .send(
          `This combination of email address and password was detected in a public data breach on another site.\n` +
          `To keep your Angeleno Account secure, please use a new, unique password. ` +
          `For more information, visit help article <a href="https://account.lacity.gov/help/password-breach" target="_blank">Breached password on another site.</a>`
        );
    }

    res
      .status(status)
      .send(message || error_description || 'Error encountered');
  }
});

export const authMethods = onRequest(async (req, res) => {
  const userId = req.query.userId;

  if (!userId) {
    res.status(400).send('Invalid request - missing required fields.');
    return;
  }

  try {
    const auth0Token = await getAccessToken();

    const config = {
      method: 'get',
      maxBodyLength: Infinity,
      url: `https://${auth0Domain}/api/v2/users/${userId}/authentication-methods`,
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${auth0Token}`,
      },
    };

    const request = await axios.request(config);

    const response = {
      mfaMethods: request.data
    }

    res.status(200).send(response);
  } catch (err) {
    console.error(err);

    const {
      status = 500,
      message = '',
    } = err.response;

    return res.status(status).send(message);
  }
});

export const enrollMFA = onRequest(async (req, res) => {
  const body = req.body;

  const {
    email,
    password,
    mfaFactor = '',
    number,
    channel
  } = body;

  let mfaToken = body.mfaToken || '';

  try {
   
    if (!mfaToken) {
      const validateResponse = await authorizeUser(
        email,
        password,
        '/mfa/'
      );

      if (validateResponse.status === 403) {
        // Auth0 uses a 403 for Wrong Email/Password and
        // when MFA is required, so we manipulate it to 401 for our use case 
        res.status(401).send({
          mfaToken: validateResponse.data.mfa_token,
        });
        return;
      } else {
        mfaToken = validateResponse?.data?.access_token;
      }
    }
    
    if (!mfaToken) {
      res.status(400).send('Invalid request - missing required fields.');
      return;
    }

    let additionalData = {};

    if (mfaFactor === 'oob') {
      additionalData = {
        'oob_channels': [channel],
        'phone_number': number
      };
    }

    const otpRequest = {
      method: 'POST',
      url: `https://${auth0Domain}/mfa/associate`,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${mfaToken}`,
      },
      data: {
        authenticator_types: [mfaFactor],
        ...additionalData
      },
    };

    const otpResponse = await axios.request(otpRequest);
    otpResponse.data.token = mfaToken;
    res.status(200).send(otpResponse?.data);
  } catch (err) {
    console.error(err);

    let {
      status = 500,
      message,
      data: {
        error_description
      }
    } = err.response;

    // Status Code for failed Authorization
    if (status === 403) {
      message = 'Invalid Password.';
    }

    res.status(status).send({error: error_description || message || 'Error encountered'});
  }
});

export const confirmMFA = onRequest(async (req, res) => {
  const body = req.body;

  const {
    mfaToken,
    userOtpCode = '',
    oobCode = '',
  } = body;

  if (!mfaToken) {
    res.status(400).send('Invalid request - missing required fields.');
    return;
  }

  try {
    let additionalData;

    if (oobCode.length) {
      additionalData = {
        oob_code: `${oobCode}`,
        binding_code: `${userOtpCode}`
      };
    } else {
      additionalData = {
        otp: `${userOtpCode}`
      };
    }

    const options = {
      method: 'POST',
      url: `https://${auth0Domain}/oauth/token`,
      headers: {'content-type': 'application/x-www-form-urlencoded'},
      data: new URLSearchParams({
        grant_type: `http://auth0.com/oauth/grant-type/${oobCode.length ? 'mfa-oob' : 'mfa-otp'}`,
        client_id: `${auth0ClientId}`,
        client_secret: `${auth0ClientSecret}`,
        mfa_token: `${mfaToken}`,
        ...additionalData
      }),
    };

    await axios.request(options);

    res.sendStatus(200);
  } catch (err) {
    let customError = '';

    const {
      status = 500,
      message = '',
      data: {error_description},
    } = err?.response;

    if (status === 403) {
      customError = 'Invalid code.';
    }

    res.status(status).send({error: message || customError || error_description});
  }
});

export const unenrollMFA = onRequest(async (req, res) => {
  const body = req.body;

  const { userId, authFactorId } = body;

  if (!userId || !authFactorId) {
    res.status(400).send('Invalid request - missing required fields.');
    return;

  }

  try {
    const auth0Token = await getAccessToken();

    const config = {
      method: 'delete',
      maxBodyLength: Infinity,
      url: `https://${auth0Domain}/api/v2/users/${userId}/authentication-methods/${authFactorId}`,
      headers: {
        'Authorization': `Bearer ${auth0Token}`,
      },
    };

    const request = await axios.request(config);
    res.status(200).send(request.data);
  } catch (err) {
    console.error(err);

    const {
      status = 500,
      message = '',
    } = err.response;

    return res.status(status).send(message);
  }
});

export const challengeMfa = onRequest(async (req, res) => {

  try {
    const {
      mfaToken,
      authenticatorId: mfaFactor
    } = req.body;


    if (!mfaToken || !mfaFactor) {
      res.status(400).send('Invalid request - missing required fields.');
      return;
    }

    const requestOptions = {
      method: 'POST',
      url: `https://${auth0Domain}/mfa/challenge`,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${mfaToken}`,
      },
      data: {
        client_id: auth0ClientId,
        client_secret: auth0ClientSecret,
        challenge_type: mfaFactor,
        mfa_token: mfaToken,
      },
    }

    const request = await axios.request(requestOptions);

    return res.status(200).send(request.data);
  } catch (err) {
    console.log(err);

    return res.status(500).send();
  }

});

export const requestMFAToken = onRequest(async (req, res) => {

  try {
    const {
      mfaToken: mfa_token,
      oobCode: oob_code,
      bindingCode: binding_code
    } = req.body;

    if (!mfa_token) {
      res.status(400).send('Invalid request - missing required fields.');
      return;
    }

    const data = !binding_code ? {
      grant_type: "http://auth0.com/oauth/grant-type/mfa-otp",
      client_id: auth0ClientId,
      client_secret: auth0ClientSecret,
      mfa_token,
      otp: oob_code
    } : {
      grant_type: "http://auth0.com/oauth/grant-type/mfa-oob",
      client_id: auth0ClientId,
      client_secret: auth0ClientSecret,
      mfa_token,
      oob_code,
      binding_code
    };

    const requestOptions = {
      method: 'POST',
      url: `https://${auth0Domain}/oauth/token`,
      headers: {
        'Content-Type': 'application/json'
      },
      data
    }

    const request = await axios.request(requestOptions);

    return res.status(200).send(request.data);
  } catch (err) {
    console.error(err);

    const {
      status = 500,
      message = '',
    } = error.response;

    return res.status(status).send(message);
  }

});

export const getConsentedApps = onRequest(async (req, res) => {
  const apps = req.query.apps || '';

  let applications = [];

  applications = apps.length ? await getConnectedServices(apps) : [];  

  res.status(200).send({
    services: applications.filter((e) => e !== null)
  });

});

const getConnectedServices = async (applicationIds) => {

  try {
    const auth0Token = await getAccessToken();

    const thirdPartyApps = applicationIds.split(',');

    return await Promise.all(thirdPartyApps.map(async (appId) => {

      const clientConfig = {
        method: 'get',
        maxBodyLength: Infinity,
        url: `https://${auth0Domain}/api/v2/clients/${appId}`,
        headers: {
          'Accept': 'application/json',
          'Authorization': `Bearer ${auth0Token}`,
        },
      };

      const clientRequest = await axios.request(clientConfig);

      const {
        name,
        client_id:clientId,
        logo_uri = '',
        client_metadata: {
          scopes
        }
      } = clientRequest.data

      return {
        name,
        logo_uri,
        clientId,
        scopes
      }
    }));

  } catch (err) {
    console.error(err);

    const {
      status = 500,
      message = '',
    } = err.response;

    // res is invalid here because this is a helper function, so we just return the error info for the calling function to handle the response
    return res.status(status).send(message);
  }
};
