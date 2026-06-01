SELECT 'clients' AS table_name, COUNT(*) AS rows_count FROM clients
UNION ALL
SELECT 'campaigns', COUNT(*) FROM campaigns
UNION ALL
SELECT 'campaign_audience', COUNT(*) FROM campaign_audience
UNION ALL
SELECT 'messages', COUNT(*) FROM messages
UNION ALL
SELECT 'message_events', COUNT(*) FROM message_events
UNION ALL
SELECT 'loan_applications', COUNT(*) FROM loan_applications
ORDER BY rows_count DESC;

SELECT
    campaign_id,
    client_id,
    COUNT(*) AS records_count
FROM campaign_audience
GROUP BY campaign_id, client_id
HAVING COUNT(*) > 1;

SELECT
    SUM(CASE WHEN client_id IS NULL THEN 1 ELSE 0 END) AS missing_client_id,
    SUM(CASE WHEN segment IS NULL THEN 1 ELSE 0 END) AS missing_segment,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS missing_age
FROM clients;

SELECT
    segment,
    COUNT(*) AS clients,
    ROUND(AVG(age), 1) AS avg_age,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_clients,
    ROUND(SUM(CASE WHEN is_active THEN 1 ELSE 0 END)::numeric / COUNT(*), 3) AS active_share
FROM clients
GROUP BY segment
ORDER BY clients DESC;

WITH event_flags AS (
    SELECT
        m.message_id,
        m.campaign_id,
        m.client_id,
        MAX(CASE WHEN e.event_type = 'sent' THEN 1 ELSE 0 END) AS sent,
        MAX(CASE WHEN e.event_type = 'delivered' THEN 1 ELSE 0 END) AS delivered,
        MAX(CASE WHEN e.event_type = 'opened' THEN 1 ELSE 0 END) AS opened,
        MAX(CASE WHEN e.event_type = 'clicked' THEN 1 ELSE 0 END) AS clicked
    FROM messages m
    LEFT JOIN message_events e ON m.message_id = e.message_id
    GROUP BY m.message_id, m.campaign_id, m.client_id
),
audience_conversions AS (
    SELECT
        ca.audience_id,
        ca.campaign_id,
        ca.client_id,
        ca.group_type,
        MAX(CASE
            WHEN la.application_at >= ca.assigned_at
             AND la.application_at < ca.assigned_at + INTERVAL '7 days'
            THEN 1 ELSE 0 END) AS converted_7d,
        MAX(CASE
            WHEN la.application_at >= ca.assigned_at
             AND la.application_at < ca.assigned_at + INTERVAL '7 days'
             AND la.status = 'approved'
            THEN 1 ELSE 0 END) AS approved_7d,
        SUM(CASE
            WHEN la.application_at >= ca.assigned_at
             AND la.application_at < ca.assigned_at + INTERVAL '7 days'
             AND la.status = 'approved'
            THEN la.requested_amount ELSE 0 END) AS approved_amount_7d
    FROM campaign_audience ca
    LEFT JOIN loan_applications la
        ON ca.campaign_id = la.campaign_id
       AND ca.client_id = la.client_id
    GROUP BY ca.audience_id, ca.campaign_id, ca.client_id, ca.group_type
),
final AS (
    SELECT
        c.campaign_id,
        c.campaign_name,
        c.channel,
        ac.group_type,
        ac.client_id,
        COALESCE(ef.sent, 0) AS sent,
        COALESCE(ef.delivered, 0) AS delivered,
        COALESCE(ef.opened, 0) AS opened,
        COALESCE(ef.clicked, 0) AS clicked,
        ac.converted_7d,
        ac.approved_7d,
        ac.approved_amount_7d
    FROM audience_conversions ac
    JOIN campaigns c ON ac.campaign_id = c.campaign_id
    LEFT JOIN event_flags ef
        ON ac.campaign_id = ef.campaign_id
       AND ac.client_id = ef.client_id
)
SELECT
    campaign_name,
    channel,
    COUNT(DISTINCT client_id) AS audience,
    SUM(sent) AS sent,
    SUM(delivered) AS delivered,
    SUM(opened) AS opened,
    SUM(clicked) AS clicked,
    SUM(converted_7d) AS conversions_7d,
    SUM(approved_7d) AS approvals_7d,
    SUM(approved_amount_7d) AS approved_amount_7d,
    ROUND(SUM(delivered)::numeric / NULLIF(SUM(sent), 0), 3) AS delivery_rate,
    ROUND(SUM(opened)::numeric / NULLIF(SUM(delivered), 0), 3) AS open_rate,
    ROUND(SUM(clicked)::numeric / NULLIF(SUM(delivered), 0), 3) AS ctr,
    ROUND(SUM(converted_7d)::numeric / NULLIF(COUNT(DISTINCT client_id), 0), 3) AS conversion_rate
FROM final
GROUP BY campaign_name, channel
ORDER BY conversion_rate DESC;

WITH conversions AS (
    SELECT
        ca.campaign_id,
        ca.client_id,
        ca.group_type,
        MAX(CASE
            WHEN la.application_at >= ca.assigned_at
             AND la.application_at < ca.assigned_at + INTERVAL '7 days'
            THEN 1 ELSE 0 END) AS converted_7d
    FROM campaign_audience ca
    LEFT JOIN loan_applications la
        ON ca.campaign_id = la.campaign_id
       AND ca.client_id = la.client_id
    GROUP BY ca.campaign_id, ca.client_id, ca.group_type
),
group_metrics AS (
    SELECT
        c.campaign_name,
        c.channel,
        group_type,
        COUNT(DISTINCT client_id) AS clients,
        SUM(converted_7d) AS conversions,
        SUM(converted_7d)::numeric / COUNT(DISTINCT client_id) AS conversion_rate
    FROM conversions conv
    JOIN campaigns c ON conv.campaign_id = c.campaign_id
    GROUP BY c.campaign_name, c.channel, group_type
),
pivoted AS (
    SELECT
        campaign_name,
        channel,
        MAX(CASE WHEN group_type = 'test' THEN clients END) AS test_clients,
        MAX(CASE WHEN group_type = 'control' THEN clients END) AS control_clients,
        MAX(CASE WHEN group_type = 'test' THEN conversion_rate END) AS test_cr,
        MAX(CASE WHEN group_type = 'control' THEN conversion_rate END) AS control_cr
    FROM group_metrics
    GROUP BY campaign_name, channel
)
SELECT
    campaign_name,
    channel,
    test_clients,
    control_clients,
    ROUND(test_cr, 4) AS test_conversion_rate,
    ROUND(control_cr, 4) AS control_conversion_rate,
    ROUND((test_cr - control_cr) * 100, 2) AS uplift_pp,
    ROUND((test_cr - control_cr) * test_clients, 1) AS incremental_conversions
FROM pivoted
ORDER BY uplift_pp DESC;

WITH conversions AS (
    SELECT
        ca.campaign_id,
        ca.client_id,
        cl.segment,
        MAX(CASE
            WHEN la.application_at >= ca.assigned_at
             AND la.application_at < ca.assigned_at + INTERVAL '7 days'
            THEN 1 ELSE 0 END) AS converted_7d,
        MAX(CASE
            WHEN la.application_at >= ca.assigned_at
             AND la.application_at < ca.assigned_at + INTERVAL '7 days'
             AND la.status = 'approved'
            THEN 1 ELSE 0 END) AS approved_7d,
        SUM(CASE
            WHEN la.application_at >= ca.assigned_at
             AND la.application_at < ca.assigned_at + INTERVAL '7 days'
             AND la.status = 'approved'
            THEN la.requested_amount ELSE 0 END) AS approved_amount_7d
    FROM campaign_audience ca
    JOIN clients cl ON ca.client_id = cl.client_id
    LEFT JOIN loan_applications la
        ON ca.campaign_id = la.campaign_id
       AND ca.client_id = la.client_id
    GROUP BY ca.campaign_id, ca.client_id, cl.segment
)
SELECT
    c.campaign_name,
    conv.segment,
    COUNT(DISTINCT conv.client_id) AS clients,
    SUM(converted_7d) AS conversions_7d,
    SUM(approved_7d) AS approvals_7d,
    SUM(approved_amount_7d) AS approved_amount_7d,
    ROUND(SUM(converted_7d)::numeric / COUNT(DISTINCT conv.client_id), 4) AS conversion_rate
FROM conversions conv
JOIN campaigns c ON conv.campaign_id = c.campaign_id
GROUP BY c.campaign_name, conv.segment
ORDER BY conversion_rate DESC;

WITH clicked_clients AS (
    SELECT DISTINCT
        m.campaign_id,
        m.client_id
    FROM messages m
    JOIN message_events e ON m.message_id = e.message_id
    WHERE e.event_type = 'clicked'
),
converted_clients AS (
    SELECT DISTINCT
        ca.campaign_id,
        ca.client_id
    FROM campaign_audience ca
    JOIN loan_applications la
        ON ca.campaign_id = la.campaign_id
       AND ca.client_id = la.client_id
    WHERE la.application_at >= ca.assigned_at
      AND la.application_at < ca.assigned_at + INTERVAL '7 days'
)
SELECT
    cc.campaign_id,
    c.campaign_name,
    cc.client_id,
    cl.segment,
    cl.city,
    cl.age
FROM clicked_clients cc
JOIN campaigns c ON cc.campaign_id = c.campaign_id
JOIN clients cl ON cc.client_id = cl.client_id
LEFT JOIN converted_clients conv
    ON cc.campaign_id = conv.campaign_id
   AND cc.client_id = conv.client_id
WHERE conv.client_id IS NULL
ORDER BY c.campaign_name, cl.segment, cc.client_id;

SELECT
    m.message_id,
    m.sent_at,
    e.event_type,
    e.event_at
FROM messages m
JOIN message_events e ON m.message_id = e.message_id
WHERE e.event_at < m.sent_at;

SELECT
    ca.campaign_id,
    ca.client_id,
    ca.group_type,
    COUNT(m.message_id) AS messages_count
FROM campaign_audience ca
JOIN messages m
    ON ca.campaign_id = m.campaign_id
   AND ca.client_id = m.client_id
WHERE ca.group_type = 'control'
GROUP BY ca.campaign_id, ca.client_id, ca.group_type
HAVING COUNT(m.message_id) > 0;
