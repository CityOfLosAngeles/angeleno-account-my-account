import { nameRegex, phoneRegex } from "../utils/constants.js";

export class User {
  constructor({
      userId,
      email,
      firstName,
      lastName,
      address,
      address2,
      city,
      state,
      zip,
      phone,
      metadata
  }) {

    this.userId = userId;
    this.email = email;
    
    if (firstName.trim().length > 300 || firstName.trim().length === 0) {
      throw new Error('First name must be between 1 and 300 characters');
    }

    if (lastName.trim().length > 150 || lastName.trim().length === 0) {
      throw new Error('Last name must be between 1 and 150 characters');
    }

    if (nameRegex.test(firstName) === false || nameRegex.test(lastName) === false) {
      throw new Error('Invalid name submitted. ');
    }

    phone = phone.replaceAll(' ', '');
    // We accept empty phone numbers, so enforce restrictions only if a phone number is provided
    if (phone.length > 0 && (phone.length > 15 || phoneRegex.test(phone) === false)) {
      throw new Error('Phone must be less than 15 characters and include valid characters');
    }

    this.lastName = lastName;
    this.firstName = firstName;
    this.address = address;
    this.address2 = address2;
    this.city = city;
    this.state = state;
    this.zip = zip;
    this.phone = phone;
    this.metadata = metadata;
  }
}