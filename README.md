# Outline Playbook Overlay

A simple Sinatra application that renders pages by calling Outline's API and displaying the results in a clean, readable format.

## Features

- 📚 Browse all documents from your Outline knowledge base
- 🔍 Search through documents
- 📖 View individual documents with formatted content
- 🎨 Clean, responsive UI design

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

## API Endpoints

- `GET /` - Homepage
- `GET /doc/:id` - View a specific page
- `GET /search?q=query` - Search

## Project Structure

```
├── app.rb              # Main Sinatra application
├── config.ru           # Puma configuration
├── Gemfile             # Ruby dependencies
├── .env.example        # Environment variables template
├── views/              # ERB templates
│   ├── layout.erb      # Main layout
│   ├── index.erb       # Document listing
│   ├── document.erb    # Individual document view
│   ├── search.erb      # Search page
│   ├── error.erb       # Error page
│   └── not_found.erb   # 404 page
└── README.md           # This file
```

## Outline API Integration

This application uses the following Outline API endpoints:

- `POST /api/documents.list` - Retrieve all documents
- `POST /api/documents.info` - Get specific document details
- `POST /api/documents.search` - Search documents

For more information about Outline's API, visit the [Outline API documentation](https://www.getoutline.com/developers).

## Customization

You can customize the appearance by modifying the CSS in `views/layout.erb` or add additional features by extending the routes in `app.rb`.

## Error Handling

The application includes comprehensive error handling for:
- API connection issues
- Missing environment variables
- Invalid document IDs
- Network timeouts
- 404 errors

## Development

To contribute or modify this application:

1. Clone the repository
2. Follow the setup instructions above
3. Make your changes
4. Test thoroughly with your Outline instance
5. Submit a pull request

## License

MIT License - feel free to use and modify as needed.