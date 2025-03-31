-- Витрина для модели атрибуции Last Paid Click
WITH last_paid_click AS (
    SELECT
        visitor_id,
        visit_date,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign,
        ROW_NUMBER() OVER (PARTITION BY visitor_id ORDER BY visit_date DESC) AS session_number
    FROM sessions
    WHERE
        medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),
latest_paid_click AS (
    SELECT
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
    FROM last_paid_click
    WHERE session_number = 1
),
attributed_leads AS (
    SELECT
        lpc.visitor_id,
        lpc.visit_date,
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM
        latest_paid_click AS lpc
    LEFT JOIN leads AS l
        ON lpc.visitor_id = l.visitor_id AND lpc.visit_date <= l.created_at
)
SELECT *
FROM attributed_leads
ORDER BY
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;
