# Local Maildir synced by mbsync, indexed by notmuch

neomutt reads mail from local Maildirs that mbsync keeps in sync with
each account's IMAP server, and notmuch indexes them, instead of
neomutt talking IMAP directly. Searching the full history and the
label views in the sidebar are notmuch queries, which need the mail on
disk; it also makes reading work offline and keeps large Gmail
mailboxes fast. The cost is a sync job to run and the whole history
duplicated on local disk (Gmail's All Mail plus every synced label).
