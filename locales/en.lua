--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-BUSINESS — Locale: English (canonical)
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('en', {
    error = {
        rate = 'Slow down.', invalid = 'That request is not valid.', too_far = 'Go to your desk.', not_yours = 'That ledger is not yours to open.', above_you = 'Not above your own grade.',
        no_hire = 'Your grade does not hire.', no_fire = 'Your grade does not let people go.', no_promote = 'Your grade does not change grades.', no_society = 'Your grade has no say over the book.',
        not_staff = 'They do not work here.', yourself = 'Not on yourself.', too_far_hire = 'They must stand at the desk.', not_hireable = 'This trade is not hired at a desk.', no_bank = 'The bank is closed.',
        amount = 'Enter a proper amount.', no_cash = 'You do not carry $%{amount}.', book_poor = 'The book does not hold that much.',
    },
    info = { you_fired = 'You no longer work for %{job}.' },
    ui = {
        kicker = 'The ledger', ledger_of = '%{job} — the ledger', open_ledger = 'Open the ledger', hint_close = 'leave', close = 'Leave',
        staff = 'Staff', no_staff = 'Nobody on the books.', on_duty = 'on duty', online = 'in town', last_seen = 'last seen', let_go = 'Let go',
        book = 'The book', no_bank = 'no bank', wage_bill = 'wages owed per pay: $%{amount} for %{n} on the books', deposit = 'Deposit', withdraw = 'Withdraw',
        hire = 'Hire', no_hire_perm = 'Your grade does not hire.', nobody_at_desk = 'Nobody is standing at the desk.', stranger_id = 'Stranger #%{id}',
        grades = 'Grades & wages', grade = 'grade', boss = 'proprietor',
    },
})
