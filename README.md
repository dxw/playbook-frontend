# Outline Playbook Overlay

Our new Playbook is managed in [Outline](https://dxw.getoutline.com/). This application overlays Outline's API to provide a custom front-end for our Playbook content where we can implement our own styling and navigation.

## Setup

1. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

2. **Configure environment variables**
   Edit `.env` and set your Outline API credentials

   SAML sign-in also requires:

   ```bash
   SAML_SP_ENTITY_ID=
   SAML_IDP_SSO_SERVICE_URL=
   SAML_IDP_CERT=
   SAML_ASSERTION_CONSUMER_SERVICE_URL=https://your-host/auth/saml/callback
   SESSION_SECRET=
   ```

   `SESSION_SECRET` must be a long random value in production. Obtain the IdP SSO URL and signing certificate from the identity provider's metadata, and configure `SAML_ASSERTION_CONSUMER_SERVICE_URL` as its assertion consumer service URL. Use `https://your-host/auth/saml/metadata` to give the identity provider this application's SAML metadata.

## Authentication

Pages with `[private]` in their title are visible only to signed-in users with a SAML assertion email address ending in `@dxw.com`. Public visitors cannot see these pages in navigation or search, and direct page requests return `404`.

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

To clear the redis cache:

```bash
redis-cli FLUSHALL
```