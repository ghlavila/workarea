CREATE TABLE user_events (
    event_id string NOT NULL,
    user_id long NOT NULL,
    event_type string NOT NULL,
    timestamp timestamp NOT NULL,
    session_id string,
    properties string,
    device_type string
)
PARTITIONED BY (date(timestamp)) 