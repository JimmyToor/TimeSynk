# TimeSynk
<hr>
TimeSynk is a Rails app that makes it easy to find time to game with friends. 
Input your available times and TimeSynk will find the best time for everyone to play together.

## Features
- Create groups and invite friends
- Propose and vote on games to play 
- Setup one-off or recurring availability schedules and use different schedules for different games or groups
- See scheduled game sessions and everyone's available times at a glance

## Requirements
- Ruby 3.3.5
- Node 20.13
- Yarn 1.22
- SMTP Credentials
- [IGDB API](https://api-docs.igdb.com/#getting-started) Credentials.

# Development
<hr>

## Setup

1. Clone the repository

2. Install dependencies
   ```bash
   bundle install
   yarn install
   ```

3. Setup `.env.development` environment variables.

   | Variable                   | Description                                                                                                |
   |----------------------------|------------------------------------------------------------------------------------------------------------|
   | RAILS_MAX_THREADS          | Number of threads per Rails worker (default: 5)                                                            |
   | PORT                       | Listening Port (default: 3000)                                                                             |
   | MAINTENANCE_MODE           | Set to 'true' to enable maintenance mode, <br/>preventing non-admins from using the site. (default: false) |
   | MAILER_ADDRESS             | SMTP server address for sending emails                                                                     |
   | MAILER_HOST                | Default host for email links                                                                               |
   | MAILER_FROM                | Default sender email address                                                                               |
   | IGDB_CLIENT                | [IGDB API](https://api-docs.igdb.com/#getting-started) client ID                                           |
   | IGDB_SECRET                | [IGDB API](https://api-docs.igdb.com/#getting-started) client secret                                       |
   | MAILER_USERNAME            | SMTP authentication username                                                                               |
   | MAILER_PASSWORD            | SMTP authentication password                                                                               |
   | TIMESYNK_DATABASE_USER     | Database server username (default: postgres)                                                               |
   | TIMESYNK_DATABASE_PASSWORD | Database server password (default: postgres)                                                               |
   | TIMESYNK_DATABASE_PASSWORD | Database server password (default: postgres)                                                               |
   | REDIS_URL                  | Redis server URL                                                                                           |
   

## Running

1. Start Postgres and Redis databases.
   ```bash
   docker compose -f docker-compose.dev.yml up -d
   ```

2. Setup database. Games are fetched from IGDB.
   ```bash
   bin/rails db:setup
   bin/rails csv:fetch_games
   bin/rails db:import_games
   ```
3. Start the Rails server
   ```bash
   bin/dev
   ```

# Deployment
<hr>

1. Setup credentials (replace `code` with your preferred editor)
   ```bash
   VISUAL="code --wait" bin/rails credentials:edit --environment=production
   ```
   The credentials file should include:
   
   | Credential Key             | Description                                   |
   |----------------------------|-----------------------------------------------|
   | secret_key_base            | Rails secret key for verifying signed cookies |
   | igdb.client                | IGDB API client ID                            |
   | igdb.secret                | IGDB API client secret                        |
   | timesynk_database.user     | Production database username                  |
   | timesynk_database.password | Production database password                  |
   | mailer.username            | SMTP authentication username                  |
   | mailer.password            | SMTP authentication password                  |
   | admin.username             | TimeSynk admin account username               |
   | admin.password             | TimeSynk admin account password               |

   See `config/credentials/production.yml.example` for an example.


2. Setup `.env.production` environment variables

   | Variable         | Description                                                                                                |
   |------------------|------------------------------------------------------------------------------------------------------------|
   | RAILS_MAX_THREADS | (Default: 5)                                                                                               |
   | PORT             | Listening Port (default: 3000)                                                                             |
   | MAINTENANCE_MODE | Set to 'true' to enable maintenance mode, <br/>preventing non-admins from using the site. (default: false) |
   | MAILER_ADDRESS   | SMTP server address for sending emails                                                                     |
   | MAILER_HOST      | Default host for email links                                                                               |
   | MAILER_FROM      | Default sender email address                                                                               |
   | REDIS_URL        | Redis server URL                                                                                           |


3. Create `/config/secrets/postgres_password.secret` and `/config/secrets/postgres_user.secret` files with the production database password and username respectively. 


4. Run the docker container
   ```bash
   docker compose up -d
   ```
   
## Configuration

### Database Updates
`/config/sidekiq.yml` holds the schedules jobs for the application.
They update and fetch new games once a week and update popularity once a week.

### Initial Seed
If the Games table is empty when starting the application, it will be seeded with data from IGDB. 
If `db/seed/games.csv` is present, it will be used instead. To ignore this file, run the application with `IGNORE_SEED`.
```bash
IGNORE_SEED=true docker compose up 
```