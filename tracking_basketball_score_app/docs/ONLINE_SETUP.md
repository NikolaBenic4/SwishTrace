# ShotLab Online Setup

The online feature is implemented without storing secrets in source control.

## 1. Firebase Authentication

1. Create a Firebase project.
2. Enable **Authentication > Email/Password**.
3. Copy the Firebase web API key.

## 2. Deploy the AWS backend

Install AWS SAM CLI, authenticate the AWS CLI, then run:

```text
cd backend
sam build
sam deploy --guided
```

Provide the Firebase project ID when prompted. The stack creates:

- API Gateway HTTP API
- Lambda API handler
- daily quest-calculation Lambda
- DynamoDB on-demand table with point-in-time recovery
- leaderboard and email lookup indexes

## 3. Build the app

Use the API URL printed by the deployment:

```text
flutter run \
  --dart-define=FIREBASE_API_KEY=your-key \
  --dart-define=SHOTLAB_API_BASE_URL=https://your-api-id.execute-api.region.amazonaws.com
```

The app remains fully usable offline when either value is omitted. Sessions are
always saved locally first. Cloud synchronization is best-effort.

## Security

- Firebase passwords are sent only to Google's Identity Toolkit endpoint.
- The app sends Firebase ID tokens as bearer tokens.
- Lambda verifies each token with Firebase Admin before accessing DynamoDB.
- Raw camera frames never leave the phone.
- Use restrictive CORS origins before a web release; the starter stack allows
  all origins for native-development convenience.
