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

  try {
    user = new User(req.body);
  } catch (err) {
    console.error(err);
    return res.status(400).send(err.message);
  }

  const updatedUserObject = {};

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
        connection: 'Username-Password-Authentication',
      },
    };

    await axios.request(passwordUpdateRequest);

    res.status(200).send();
    return;
  } catch (err) {
    console.error(`Error: ${err.message}`);

    const {
      status = 500,
      data: {error_description, message},
    } = err?.response;

    res
      .status(status)
      .send(message || error_description || 'Error encountered');
    return;
  }
});

export const authMethods = onRequest(async (req, res) => {
  const userId = req.params.userId;

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

   const applications = await getConnectedServices(userId);

    const response = {
      mfaMethods: request.data,
      services: applications.filter((e) => e !== null)
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

  try {
    const validateResponse = await authorizeUser(
      email,
      password,
      '/mfa/'
    );

    const mfaToken = validateResponse?.data?.access_token;

    let additionalData = {};

    if (mfaFactor == 'oob') {
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
    let additionalData = {};

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

export const removeConnection = onRequest(async (req, res) => {
  try {
    const {
      connectionId
    } = req.body;

    if (!connectionId) {
      res.status(400).send('Invalid request - missing required fields.');
      return;
    }
  
    const config = {
      method: 'delete',
      maxBodyLength: Infinity,
      url: `https://${auth0Domain}/api/v2/grants/${connectionId}`,
      headers: {
        'Authorization': `Bearer ${await getAccessToken()}`
      }
    };
    
    await axios.request(config)
    res.status(200).send();
  } catch (error) {
    console.log(error);

    const {
      status = 500,
      message = '',
    } = error.response;

    return res.status(status).send(message);
  };
});

const getConnectedServices = async (userId) => {

  if (!userId) {
    res.status(400).send('Invalid request - missing required fields.');
    return;
  }

  try {
    const auth0Token = await getAccessToken();

    const grantConfig = {
      method: 'get',
      maxBodyLength: Infinity,
      url: `https://${auth0Domain}/api/v2/grants?user_id=${userId}`,
      headers: {
        'Accept': 'application/json',
        'Authorization': `Bearer ${auth0Token}`,
      },
    };

    const grantRequest = await axios.request(grantConfig);

    const thirdPartyApps = grantRequest.data.filter((grant) => grant.clientID !== auth0ClientId);

    return await Promise.all(thirdPartyApps.map(async (grant) => {

      const {
        clientID:clientId,
        scope,
        id: grantId
      } = grant;

      const clientConfig = {
        method: 'get',
        maxBodyLength: Infinity,
        url: `https://${auth0Domain}/api/v2/clients/${clientId}`,
        headers: {
          'Accept': 'application/json',
          'Authorization': `Bearer ${auth0Token}`,
        },
      };

      const clientRequest = await axios.request(clientConfig);

      const {
        name,
        logo_uri,
        is_first_party:isFirstParty
      } = clientRequest.data

      if (isFirstParty) {
        return null;
      }

      return {
        name,
        logo_uri,
        clientId,
        scope,
        grantId
      }
    }));

  } catch (err) {
    console.error(err);

    const {
      status = 500,
      message = '',
    } = err.response;

    return res.status(status).send(message);
  }
};