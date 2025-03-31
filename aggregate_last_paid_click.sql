-- SQL для агрегации данных из модели атрибуции Last Paid Click
WITH last_paid_click AS (
    SELECT
        s.visitor_id,
        CAST(s.visit_date AS DATE) AS visit_date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        ROW_NUMBER() OVER (PARTITION BY s.visitor_id ORDER BY s.visit_date DESC) AS visit_rank
    FROM
        sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id
        AND l.created_at >= s.visit_date
    WHERE
        s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),
ad_costs AS (
    SELECT
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM vk_ads
        UNION ALL
        SELECT campaign_date, utm_source, utm_medium, utm_campaign, daily_spent FROM ya_ads
    ) AS combined_ads
    GROUP BY campaign_date, utm_source, utm_medium, utm_campaign
)
SELECT
    lpc.visit_date,
    COUNT(DISTINCT lpc.visitor_id) AS visitors_count,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    CASE WHEN ac.total_cost IS NULL THEN '' ELSE CAST(ac.total_cost AS VARCHAR) END AS total_cost,
    COUNT(DISTINCT lpc.lead_id) AS leads_count,
    COUNT(DISTINCT CASE WHEN lpc.closing_reason = 'Успешно реализовано' OR lpc.status_id = 142 THEN lpc.lead_id END) AS purchases_count,
    SUM(CASE WHEN lpc.closing_reason = 'Успешно реализовано' OR lpc.status_id = 142 THEN lpc.amount ELSE 0 END) AS revenue
FROM
    last_paid_click AS lpc
LEFT JOIN ad_costs AS ac
    ON lpc.visit_date = ac.campaign_date
    AND lpc.utm_source = ac.utm_source
    AND lpc.utm_medium = ac.utm_medium
    AND lpc.utm_campaign = ac.utm_campaign
WHERE
    lpc.visit_rank = 1
GROUP BY
    lpc.visit_date, lpc.utm_source, lpc.utm_medium, lpc.utm_campaign, ac.total_cost
ORDER BY
    revenue DESC NULLS LAST,
    lpc.visit_date ASC,
    visitors_count DESC,
    lpc.utm_source ASC,
    lpc.utm_medium ASC,
    lpc.utm_campaign ASC;
