-- No journal entries should have a posting date in the future
select *
from {{ ref('fct_journal_entries') }}
where posting_date > current_date()
