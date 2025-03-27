-- Витрина для модели атрибуции Last Paid Click
WITH last_paid_click AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM
        sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id
        AND l.created_at >= s.visit_date
    WHERE
        s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
)
SELECT *
FROM last_paid_click
ORDER BY
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC,
    lead_id ASC;

