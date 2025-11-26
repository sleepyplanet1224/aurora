# Aurora - AI Assistant Guide

Aurora is a Ruby on Rails 7.1.6 personal finance tracking web application built with Ruby 3.3.5 and PostgreSQL. It helps users track monthly financial data including total assets, savings amounts, and financial events.

## Quick Reference

### Common Commands
```bash
bin/rails server          # Start development server (http://localhost:3000)
bin/rails console         # Rails console
bin/rails test            # Run all tests
bin/rails test:models     # Run model tests
bin/rails test:system     # Run system tests (Capybara)
bin/rails db:migrate      # Run pending migrations
bin/rails db:seed         # Load seed data
bin/rails routes          # List all routes
```

### Setup
```bash
./bin/setup               # Automated setup (or: bundle install && bin/rails db:prepare)
```

## Architecture

### Stack
- **Backend**: Rails 7.1.6, Ruby 3.3.5
- **Database**: PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus), Bootstrap 5.3, SCSS
- **Authentication**: Devise
- **JavaScript**: ImportMap (not Webpack)
- **Forms**: SimpleForm with Bootstrap

### Data Models
- **User**: Devise authentication, has_many :months. Requires birthday.
- **Month**: belongs_to :user, has_many :events. Requires date, total_assets, saved_amount.
- **Event**: belongs_to :month. Requires name, new_saved_amount, new_total_assets.

### Key Routes
```
/                  → PagesController#home (public)
/dashboard         → PagesController#dashboard (authenticated)
/months            → MonthsController (create, new)
/events            → EventsController (create)
```

## Code Style

- Max line length: 120 characters
- RuboCop configured with relaxed rules (.rubocop.yml)
- Use Bootstrap classes for styling
- ERB templates for views
- Stimulus controllers in app/javascript/controllers/

## Project Status

Early development stage:
- Authentication working (Devise)
- Models defined with validations
- Controllers exist but are largely unimplemented
- Chartkick gem added for charting (not yet integrated)

## Important Notes

- Most routes require authentication (ApplicationController enforces this)
- PostgreSQL required (not SQLite) - database server must be running
- config/master.key needed to decrypt credentials in production
- Uses Importmap for JavaScript imports
