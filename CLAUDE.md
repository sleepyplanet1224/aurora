# Aurora - AI Assistant Guide

Aurora is a Ruby on Rails 7.1.6 personal finance tracking web application built with Ruby 3.3.5 and PostgreSQL. It helps users track monthly financial data including total assets, savings amounts, and financial events with 30-year projections.

## Quick Reference

### Common Commands
```bash
bin/rails server          # Start development server (http://localhost:3000)
bin/rails console         # Rails console
bin/rails test            # Run all tests
bin/rails test:models     # Run model tests
bin/rails test:system     # Run system tests (Capybara)
bin/rails db:migrate      # Run pending migrations
bin/rails db:seed         # Load seed data (creates test user: aurora@gmail.com / 123456)
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
- **Frontend**: Hotwire (Turbo + Stimulus), Bootstrap 5.3, SCSS, Font Awesome
- **Authentication**: Devise
- **JavaScript**: ImportMap (not Webpack)
- **Forms**: SimpleForm with Bootstrap
- **Charting**: Chartkick with Chart.js v4.4.1 (loaded via CDN, line charts with filled areas for financial projections)
- **AI**: RubyLLM (~> 1.2.0) gem present but not yet integrated

### Data Models
- **User**: Devise authentication, has_many :months. Requires birthday. Has username and is_public (boolean, default false).
- **Month**: belongs_to :user, has_many :events. Requires date, total_assets (integer), saved_amount (integer).
- **Event**: belongs_to :month. Requires name, new_saved_amount (integer), new_total_assets (integer). Predefined names: "birth of a child", "marriage", "promotion" (Event::NAMES constant).

### Key Routes
```
/                  → pages#home (public landing page - placeholder)
/dashboard         → pages#dashboard (authenticated, main app view)
/months/new        → months#new (authenticated)
/months            → months#create POST (authenticated)
/events/new        → events#new (authenticated, Turbo Stream)
/events            → events#create POST (authenticated)
/up                → Health check endpoint
devise_for :users  → All Devise routes
```

## Core Features

### Financial Projections
- When a user creates their first month, the system generates 30 years of projected months
- Each month's total_assets = previous total_assets + saved_amount (compound accumulation)
- Events can retroactively adjust all future months from the event date forward

### Dashboard (pages#dashboard)
- Interactive stacked line chart with filled areas showing total assets over time (Chartkick + Chart.js)
- Three data series: "Savings per Month" (teal, fill to origin), "Total Invested Assets" (purple, fill to previous series), and "Life Event" markers (red dots, separate stack group)
- Date range filtering with preset buttons (1, 3, 5, 10, 20, 30 years) and custom date modal
- Event creation via Bootstrap modal with Turbo Stream form loading
- Currency displayed in yen (¥)
- Chart uses `line_chart` with `stacked: true` and `fill` options for proper stacking behavior
- Life Events use `stack: "events"` to plot independently at the combined saved + other value

### Event System
- Events represent life changes affecting finances (birth of child, marriage, promotion)
- Creating an event updates new_saved_amount and new_total_assets
- All months from event date forward are recalculated automatically

### Month Creation (months#create)
- User inputs initial total_assets and saved_amount
- System generates months from current date to 30 years ahead
- Uses find_or_create_by! to avoid duplicates

## Code Style

- Max line length: 120 characters
- RuboCop configured with relaxed rules (.rubocop.yml)
- Use Bootstrap classes for styling
- ERB templates for views
- Stimulus controllers in app/javascript/controllers/ (minimal usage currently)

## Project Status

Active development - core functionality implemented:
- Authentication working (Devise)
- Models defined with validations and associations
- Controllers fully implemented with financial projection logic
- Chartkick integrated with stacked line chart visualization (using line_chart with fill options, not area_chart)
- Turbo Stream used for dynamic event form loading
- 30-year financial projection generation working

### Known Issues / TODO
- Home page (pages/home.html.erb) is a placeholder
- Navbar has duplicate `<nav>` blocks that need cleanup
- Events index route referenced in navbar but not defined in routes.rb
- RubyLLM AI summary code is commented out in PagesController (not implemented)
- No edit/delete functionality for events
- Minimal Stimulus controller usage (mostly relying on Turbo)

## Important Notes

- Most routes require authentication (ApplicationController enforces `before_action :authenticate_user!`)
- PostgreSQL required (not SQLite) - database server must be running
- config/master.key needed to decrypt credentials in production
- Uses Importmap for JavaScript imports
- Seed data creates test user: aurora@gmail.com with password 123456
