DROP TABLE IF EXISTS loan_applications;
DROP TABLE IF EXISTS message_events;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS campaign_audience;
DROP TABLE IF EXISTS campaigns;
DROP TABLE IF EXISTS clients;

CREATE TABLE clients (
    client_id          INT PRIMARY KEY,
    gender             VARCHAR(1),
    age                INT,
    city               VARCHAR(50),
    segment            VARCHAR(30),
    registration_date  DATE,
    is_active          BOOLEAN,
    last_activity_at   DATE
);

CREATE TABLE campaigns (
    campaign_id      INT PRIMARY KEY,
    campaign_name    VARCHAR(200),
    channel          VARCHAR(20),
    product          VARCHAR(30),
    start_date       DATE,
    target_segments  VARCHAR(100)
);

CREATE TABLE campaign_audience (
    audience_id  INT PRIMARY KEY,
    campaign_id  INT REFERENCES campaigns(campaign_id),
    client_id    INT REFERENCES clients(client_id),
    group_type   VARCHAR(20),
    assigned_at  TIMESTAMP
);

CREATE TABLE messages (
    message_id   INT PRIMARY KEY,
    campaign_id  INT REFERENCES campaigns(campaign_id),
    client_id    INT REFERENCES clients(client_id),
    channel      VARCHAR(20),
    sent_at      TIMESTAMP,
    status       VARCHAR(20)
);

CREATE TABLE message_events (
    event_id    INT PRIMARY KEY,
    message_id  INT REFERENCES messages(message_id),
    event_type  VARCHAR(20),
    event_at    TIMESTAMP
);

CREATE TABLE loan_applications (
    application_id    INT PRIMARY KEY,
    client_id         INT REFERENCES clients(client_id),
    campaign_id       INT REFERENCES campaigns(campaign_id),
    product           VARCHAR(30),
    application_at    TIMESTAMP,
    status            VARCHAR(20),
    requested_amount  NUMERIC(14, 2)
);

CREATE INDEX idx_audience_campaign_client ON campaign_audience(campaign_id, client_id);
CREATE INDEX idx_messages_campaign_client ON messages(campaign_id, client_id);
CREATE INDEX idx_events_message_type ON message_events(message_id, event_type);
CREATE INDEX idx_applications_campaign_client ON loan_applications(campaign_id, client_id);
CREATE INDEX idx_applications_date ON loan_applications(application_at);
