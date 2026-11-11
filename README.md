# Outline Playbook Overlay

Our new Playbook is managed in [Outline](https://dxw.getoutline.com/). This application overlays Outline's API to provide a custom front-end for our Playbook content where we can implement our own styling and navigation.

## Setup

1. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

2. **Configure environment variables**
   Copy `.env.example` to `.env` and set your Outline API credentials. For SAML sign-in, follow the [SAML setup](#configure-saml-sign-in-with-google-workspace) below.

## Private pages and authentication

Most pages are public. Some pages are private, and you must sign in with a dxw account to view them.

### How private pages work

- A page is private if its Outline title contains `[private]` (case-insensitive), for example `Salary bands [private]`. To make a page private, add `[private]` to its title in Outline. To make it public again, remove it.
- Privacy is set per page. Child pages of a private page don't appear in navigation or the sitemap, because those skip the whole branch. But the children are still public in search and through direct links. Add `[private]` to each child page that should be private too.
- When a visitor is not signed in:
  - private pages are left out of the page navigation
  - private pages are left out of search results, and the search page tells the visitor that private matches were hidden and links to sign-in
  - requesting a private page directly (`/doc/:id`) returns `404`, the same as a missing page, so the page's existence is not revealed
- `/sitemap.xml` always leaves out private pages, whether or not the visitor is signed in.
- Signed-in dxw users see private pages in navigation and search and can open them directly.

The checks are the `private_page?` and `visible_page?` helpers in `app.rb`. Sign-in state comes from `Authentication.signed_in?` in `lib/authentication.rb`.

### How SAML sign-in works

dxw staff sign in through Google Workspace using SAML ([OmniAuth SAML](https://github.com/omniauth/omniauth-saml)):

1. The header shows a **Sign in with your dxw account** button, and search results show a **Sign in** link when private matches were hidden. Both submit a `POST` to `/auth/saml`. The current page path goes in `RelayState`, and the request carries a CSRF token.
2. OmniAuth redirects the user to Google, where they sign in.
3. Google `POST`s the SAML response to `/auth/saml/callback`. The app reads the user's email from the `email` attribute. If that attribute is missing, it uses the NameID, which Google sets to the user's primary email.
4. If the email ends in `@dxw.com` (case-insensitive), the email is stored in the session (`session[:user_email]`). The user is then sent back to the page they started on. Only local paths are allowed as return destinations, to prevent open redirects. Any other email gets a `403` and is not signed in.
5. If SAML authentication fails (for example, a bad signature or a cancelled sign-in), OmniAuth sends the user to `/auth/failure`, which shows an error page with status `401`.
6. **Sign out** submits a `POST` to `/sign-out`, which clears the session and redirects to the homepage.

Sessions are stored in a signed cookie (`playbook.session`) using `SESSION_SECRET`. The cookie is marked `Secure` in production, so sign-in only works over HTTPS there.

### Configure SAML sign-in with Google Workspace

1. In the [Google Admin console](https://admin.google.com/), go to **Apps > Web and mobile apps > Add app > Add custom SAML app**. In **Google IdP information**, copy the **SSO URL** and download the **Certificate** (or IdP metadata) for the environment variables below.
2. In **Service provider details**, enter:
   - **ACS URL:** `https://playbook.dxw.com/auth/saml/callback`
   - **Entity ID:** `https://playbook.dxw.com/auth/saml/metadata` (or another stable identifier, matching `SAML_SP_ENTITY_ID`)
   - **Name ID format:** `EMAIL`; **Name ID:** `Basic Information > Primary email`.

   The application's SP metadata is available at `https://playbook.dxw.com/auth/saml/metadata`. Google must POST the SAML response to the ACS URL.
3. In **Attribute mapping**, map Google's **Basic Information > Primary email** to an app attribute named `email`. This is recommended but optional, because the app falls back to the NameID. Turn on the SAML app for the intended dxw users or organisational units. Only addresses ending in `@dxw.com` can sign in.
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
- `GET /doc/:id` - View a specific page (returns `404` for private pages unless signed in)
- `GET /search?query=query` - Search
- `GET /sitemap.xml` - Sitemap of public pages
- `POST /auth/saml` - Start SAML sign-in
- `POST /auth/saml/callback` - SAML assertion consumer service (ACS) URL
- `GET /auth/saml/metadata` - SAML service provider metadata
- `GET /auth/failure` - Shown when SAML sign-in fails
- `POST /sign-out` - Sign out

## Testing

```bash
# Run all tests
bundle exec rspec

# Run accessibility checks (requires Chrome)
bundle exec rspec spec/accessibility_spec.rb

# Run with coverage report
bundle exec rake coverage
```

Accessibility checks use axe-core to test rendered pages against WCAG 2.2 AA.

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