# Outline Playbook Overlay

Our new Playbook is managed in [Outline](https://dxw.getoutline.com/). This application overlays Outline's API to provide a custom front-end for our Playbook content where we can implement our own styling and navigation.

## Setup

1. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

2. **Configure environment variables**
   Edit `.env` and set your Outline API credentials.

## Running the Application

### Development
```bash
bundle exec rerun ruby app.rb
```

### Production
```bash
bundle exec puma
```

The application will be available at `http://localhost:4567`

## Routes

- `GET /` - Homepage
- `GET /doc/:id` - View a specific page
- `GET /search?q=query` - Search
