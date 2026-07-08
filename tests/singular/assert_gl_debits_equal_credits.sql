-- GL double-entry: total debits should equal total credits per journal
select
    journal_entry_id,
    sum(debit_amount) as total_debits,
    sum(credit_amount) as total_credits
from {{ ref('fct_journal_entries') }}
group by journal_entry_id
having abs(sum(debit_amount) - sum(credit_amount)) > 0.01
