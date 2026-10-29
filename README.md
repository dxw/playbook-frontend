# Outline Playbook Overlay

Our new Playbook is managed in [Outline](https://dxw.getoutline.com/). This application overlays Outline's API to provide a custom front-end for our Playbook content where we can implement our own styling and navigation.

## Setup

1. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

2. **Configure environment variables**
   Copy `.env.example` to `.env` and set your Outline API credentials. For SAML sign-in, follow the [authentication setup](#authentication) below.

## Authentication

Pages with `[private]` in their title are visible only to signed-in users with a SAML assertion email address ending in `@dxw.com`. Public visitors cannot see these pages in navigation or search, and direct page requests return `404`.

### Configure SAML sign-in with Google Workspace

1. In the [Google Admin console](https://admin.google.com/), go to **Apps > Web and mobile apps > Add app > Add custom SAML app**. In **Google IdP information**, copy the **SSO URL** and download the **Certificate** (or IdP metadata) for the environment variables below.
2. In **Service provider details**, enter:
   - **ACS URL:** `https://playbook.dxw.com/auth/saml/callback`
   - **Entity ID:** `https://playbook.dxw.com/auth/saml/metadata` (or another stable identifier, matching `SAML_SP_ENTITY_ID`)
   - **Name ID format:** `EMAIL`; **Name ID:** `Basic Information > Primary email`.

   The application's SP metadata is available at `https://playbook.dxw.com/auth/saml/metadata`. Google must POST the SAML response to the ACS URL.
3. In **Attribute mapping**, map Google's **Basic Information > Primary email** to an app attribute named `email` (or `mail`). The app reads this attribute, not just the Name ID, to sign users in. Turn on the SAML app for the intended dxw users or organizational units; only addresses ending in `@dxw.com` can sign in.
4. Set these environment variables in `.env` for development and in the deployment environment for production:

   ```dotenv
   SAML_SP_ENTITY_ID=https://playbook.dxw.com/auth/saml/metadata
   SAML_IDP_SSO_SERVICE_URL=<Google SSO URL>
   SAML_IDP_CERT=-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----
   SAML_ASSERTION_CONSUMER_SERVICE_URL=https://playbook.dxw.com/auth/saml/callback
   SESSION_SECRET=<long-random-value>
   ```

   Use the **SSO URL** and **Certificate** for this Google SAML app, not the SP metadata URL. If you chose a different Entity ID in Google, update `SAML_SP_ENTITY_ID` to match. For `SAML_IDP_CERT`, use the PEM certificate with literal `\n` between lines when storing it on one line. Set `SESSION_SECRET` to a long random value; it is required in production. Keep the certificate and session secret out of version control.
5. On the deployed HTTPS host, use **Sign in with your dxw account** to test the flow. It submits a POST to `/auth/saml`; confirm an assigned dxw account can open a `[private]` page and that an account without a `@dxw.com` email is rejected with `403`.

For more on Google's setup screens, see [Set up your own custom SAML app](https://knowledge.workspace.google.com/admin/apps/set-up-your-own-custom-saml-app).

SAML-specific setup is confined to the OmniAuth middleware and callback in `app.rb`. `lib/authentication.rb` owns the application session contract (`user_email`), so an alternative identity provider can replace those integration points without changing visibility logic.

## Error Monitoring

This application uses [Rollbar](https://rollbar.com/) for error tracking and monitoring. To enable:

1. Sign up for a Rollbar account at https://rollbar.com/
2. Create a project and get your access token
3. Add `ROLLBAR_ACCESS_TOKEN` to your `.env` file
4. In production, Rollbar will automatically track errors when the access token is set

## Running the Application

### Development
Run with automatic reloading on file changes:
```bash
bundle exec rerun ruby app.rb
```

### Production
```bash
bundle exec ruby app.rb
```

The application will be available at `http://localhost:4567`

## Routes

- `GET /` - Homepage
- `GET /doc/:id` - View a specific page
- `GET /search?query=query` - Search

## Testing

```bash
# Run all tests
bundle exec rspec

# Run with coverage report
bundle exec rake coverage
```

## Caching

The application includes Redis caching to improve performance by reducing API calls to Outline. If Redis is not available, the application will run without caching (all requests go directly to Outline's API).

To clear one document's cache locally:

```bash
bundle exec rake "cache:clear_document[DOCUMENT_ID]"
```

For example, to clear `ai-usage-guidance-eVDXTJHGwD`:

```bash
bundle exec rake "cache:clear_document[ai-usage-guidance-eVDXTJHGwD]"
```

To clear one document's cache on Heroku:

```bash
heroku run -a dxw-playbook-frontend -- bundle exec rake "cache:clear_document[DOCUMENT_ID]"
```

To clear all Playbook cache entries locally:

```bash
bundle exec rake cache:clear_all
```

To clear all Playbook cache entries on Heroku:

```bash
heroku run -a dxw-playbook-frontend -- bundle exec rake cache:clear_all
```