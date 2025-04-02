-- SQL для подготовки данных для дашборда
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
    LEFT JOIN
        leads AS l
        ON
            s.visitor_id = l.visitor_id
            AND l.created_at >= s.visit_date
    WHERE s.medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

ad_costs AS (
    SELECT
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent
        FROM
            vk_ads
        UNION ALL
        SELECT
            campaign_date,
            utm_source,
            utm_medium,
            utm_campaign,
            daily_spent
        FROM
            ya_ads
    ) AS combined_ads
    GROUP BY
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign
),

aggregated_data AS (
    SELECT
        lpc.visit_date,
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        COUNT(DISTINCT lpc.visitor_id) AS visitors_count,
        COALESCE(ac.total_cost, 0) AS total_cost,
        COUNT(DISTINCT lpc.lead_id) AS leads_count,
        COUNT(
            DISTINCT CASE
                WHEN
                    lpc.closing_reason = 'Успешно реализовано'
                    OR lpc.status_id = 142
                        THEN lpc.lead_id
            END
        ) AS purchases_count,
        SUM(
            CASE
                WHEN
                    lpc.closing_reason = 'Успешно реализовано'
                    OR lpc.status_id = 142
                        THEN lpc.amount
                ELSE 0
            END
        ) AS revenue
    FROM
        last_paid_click AS lpc
    LEFT JOIN
        ad_costs AS ac
        ON
            lpc.visit_date = ac.campaign_date
            AND lpc.utm_source = ac.utm_source
            AND lpc.utm_medium = ac.utm_medium
            AND lpc.utm_campaign = ac.utm_campaign
    GROUP BY
        lpc.visit_date,
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        ac.total_cost
)

SELECT
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    visitors_count,
    total_cost,
    leads_count,
    purchases_count,
    revenue,
    total_cost / NULLIF(visitors_count, 0) AS cpu,
    total_cost / NULLIF(leads_count, 0) AS cpl,
    total_cost / NULLIF(purchases_count, 0) AS cppu,
    (revenue - total_cost) / NULLIF(total_cost, 0) * 100 AS roi
FROM
    aggregated_data
ORDER BY
    roi DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;
