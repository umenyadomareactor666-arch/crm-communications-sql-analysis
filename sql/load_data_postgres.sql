-- Run from the project root in psql:
-- psql -d your_database -f sql/schema.sql
-- psql -d your_database -f sql/load_data_postgres.sql

\copy clients FROM 'data/clients.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy campaigns FROM 'data/campaigns.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy campaign_audience FROM 'data/campaign_audience.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy messages FROM 'data/messages.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy message_events FROM 'data/message_events.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
\copy loan_applications FROM 'data/loan_applications.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
