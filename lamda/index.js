const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { randomUUID } = require("crypto");

// Initialize DynamoDB client
const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

// Environment variable for table name
const TABLE_NAME = process.env.CONTACTS_TABLE_NAME || "ContactSubmissions";

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body);

    const { fullName, email, company, phone, message } = body;

    // Basic validation
    if (!fullName || !email || !company || !phone || !message) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*", // Adjust for your domain
        },
        body: JSON.stringify({ error: "Missing required fields" }),
      };
    }

    // Email validation (basic)
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Invalid email format" }),
      };
    }

    // Prepare item for DynamoDB
    const contactItem = {
      id: randomUUID(), // Primary key
      fullName: fullName.trim(),
      email: email.toLowerCase().trim(),
      company: company.trim(),
      phone: phone.trim(),
      message: message.trim(),
      submittedAt: new Date().toISOString(),
      status: "new", // Can be used for follow-up tracking
    };

    // Store in DynamoDB
    const putCommand = new PutCommand({
      TableName: TABLE_NAME,
      Item: contactItem,
      // Prevent overwriting if somehow the same ID exists
      ConditionExpression: "attribute_not_exists(id)",
    });

    await docClient.send(putCommand);

    console.log("Contact form submission stored:", {
      id: contactItem.id,
      email: contactItem.email,
      company: contactItem.company,
    });

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*", // Adjust for your domain
      },
      body: JSON.stringify({
        message: "Contact form submitted successfully!",
        submissionId: contactItem.id,
      }),
    };

  } catch (error) {
    console.error("Error processing contact form:", error);

    // Handle specific DynamoDB errors
    if (error.name === "ConditionalCheckFailedException") {
      return {
        statusCode: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Submission conflict, please try again" }),
      };
    }

    // Handle validation errors from DynamoDB
    if (error.name === "ValidationException") {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Invalid data format" }),
      };
    }

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};