const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

// Initialize DynamoDB client
const dynamoClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const TABLE_NAME = process.env.EMAILS_TABLE_NAME || "email-collection-table";

// Response headers for CORS
const CORS_HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "OPTIONS,POST",
  "Access-Control-Allow-Headers": "Content-Type"
};

/**
 * Validate email format
 */
const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Validate email payload
 */
const validateEmailPayload = (payload) => {
  const { email } = payload;
  
  if (!email?.trim()) {
    throw new Error('Email is required');
  }
  
  if (!validateEmail(email.trim())) {
    throw new Error('Invalid email format');
  }
  
  return true;
};

/**
 * Prepare email item for DynamoDB storage
 */
const prepareEmailItem = (email) => {
  return {
    id: randomUUID(),
    email: email.toLowerCase().trim(),
    subscribedAt: new Date().toISOString(),
    status: "active"
  };
};

/**
 * Store email in DynamoDB
 */
const storeEmailInDynamoDB = async (emailItem) => {
  const putCommand = new PutCommand({
    TableName: TABLE_NAME,
    Item: emailItem,
    ConditionExpression: "attribute_not_exists(email)"
  });
  
  try {
    await dynamoClient.send(putCommand);
    console.log(`Successfully stored email: ${emailItem.email}`);
    return emailItem.id;
  } catch (error) {
    console.error("DynamoDB storage failed:", error);
    throw error;
  }
};

/**
 * Create standardized error response
 */
const createErrorResponse = (statusCode, message) => ({
  statusCode,
  headers: CORS_HEADERS,
  body: JSON.stringify({ error: message })
});

/**
 * Create standardized success response
 */
const createSuccessResponse = (data) => ({
  statusCode: 200,
  headers: CORS_HEADERS,
  body: JSON.stringify(data)
});

/**
 * Main Lambda handler for email collection
 */
exports.handler = async (event) => {
  console.log("Email subscription request received");
  
  try {
    // Parse request body
    let emailPayload;
    try {
      emailPayload = JSON.parse(event.body);
    } catch (parseError) {
      console.error("Invalid JSON in request body:", parseError);
      return createErrorResponse(400, "Invalid JSON format");
    }
    
    console.log("Processing email:", emailPayload.email);
    
    // Validate the email payload
    try {
      validateEmailPayload(emailPayload);
    } catch (validationError) {
      console.log("Email validation failed:", validationError.message);
      return createErrorResponse(400, validationError.message);
    }
    
    // Prepare email item for storage
    const emailItem = prepareEmailItem(emailPayload.email);
    console.log("Prepared email item:", {
      id: emailItem.id,
      email: emailItem.email,
      subscribedAt: emailItem.subscribedAt
    });
    
    // Store email in DynamoDB
    const subscriptionId = await storeEmailInDynamoDB(emailItem);
    
    // Return success response
    return createSuccessResponse({
      message: "Email successfully subscribed!",
      subscriptionId,
      email: emailItem.email
    });
    
  } catch (error) {
    console.error("Error processing email subscription:", error);
    
    // Handle specific DynamoDB errors
    if (error.name === "ConditionalCheckFailedException") {
      return createErrorResponse(409, "Email already exists");
    }
    
    if (error.name === "ValidationException") {
      return createErrorResponse(400, "Invalid email data");
    }
    
    if (error.name === "ResourceNotFoundException") {
      return createErrorResponse(500, "Email storage not available");
    }
    
    // Generic server error
    return createErrorResponse(500, "Internal server error");
  }
};