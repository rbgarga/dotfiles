# Mail runbook

neomutt in the terminal, on desktop-profile hosts (m2; e14 untested),
for three Gmail accounts and a set of gmane lists. The words used here
(account, identity, label view, reply copy, ...) are defined in
[GLOSSARY.md](GLOSSARY.md); the design decisions are in [adr/](adr/).

| Piece | Config | Job |
|---|---|---|
| mbsync (isync) | `~/.mbsyncrc` | Gmail IMAP ⇄ `~/Mail/{personal,freebsd,work}` |
| nntp-sync | `~/.config/nntp-sync/groups` | gmane → `~/Mail/lists/<list>` |
| notmuch | `~/.config/notmuch/default/config` | index of all of `~/Mail` |
| msmtp | `~/.config/msmtp/config` | sending, account picked by From |
| neomutt | `~/.config/neomutt/` | reading and writing |
| mail-sync | launchd `org.rbgarga.mail-sync` | mbsync, nntp-sync, notmuch new every 5 minutes |
| mail-secret | Keychain / `~/.config/mail/secrets` | passwords and OAuth2 secrets |
| mail-oauth2 | `~/.cache/mail-oauth2` | Work's OAuth2 access tokens for mbsync and msmtp |
| xoauth2 SASL plugin | `~/.local/lib/sasl2` (macOS) | lets mbsync log into Work with OAuth2 |
| mail-label | (called by neomutt) | Delete and Unlabel in label views |

Accounts, labels and lists are listed once, in
`.chezmoidata/mail.yaml`, and rendered into the mbsync, nntp-sync and
neomutt configs. To add a label or a list, add it there, `chezmoi
apply`, and run `mail-sync`.

## 1. Gmail prerequisites (each of the three accounts)

In the Google account of Personal and FreeBSD:

- 2-Step Verification on, then create an app password ("Mail", one per
  account).

Work allows no app passwords and logs in with OAuth2 instead (see
section 3 and [adr/0003](adr/0003-work-oauth2-thunderbird-client.md)).

In Gmail settings, "Forwarding and POP/IMAP":

- IMAP access on.
- Auto-Expunge on.
- "When a message is marked as deleted and expunged from the last
  visible IMAP folder": Archive the message (the default). This is what
  makes Archive (`y`) remove only the INBOX label.
- Folder size limits: no limit.

In "Labels", "Show in IMAP" must be on for All Mail, Spam, Trash, Sent,
Drafts and every label in `.chezmoidata/mail.yaml`.

## 2. Secrets

`mail-secret <name>` prints one of five secrets:

| Name | Secret |
|---|---|
| `personal` | app password of rbgarga@gmail.com |
| `freebsd-gmail` | app password of garga.bsd@gmail.com |
| `freebsd-smtp` | password of the `garga/mail` principal |
| `work-oauth-client` | Thunderbird's OAuth2 client: `<client id> <client secret>` |
| `work-oauth-refresh` | OAuth2 refresh token of garga@netgate.com, stored by `mail-oauth2 --authorize work` |

Work has no password here. `work-oauth-client` is not one: it is
Thunderbird's OAuth2 client id and secret (section 3), which identify
the application, not the user, and which mail-oauth2 sends to Google
with every token request. They are public, but kept out of this repo.
The account's password is only typed in the browser, during
`mail-oauth2 --authorize work`, and never reaches mail-oauth2.

On macOS they live in the login Keychain (each command prompts for the
value):

```sh
security add-generic-password -a "$USER" -s mail-personal -w
security add-generic-password -a "$USER" -s mail-freebsd-gmail -w
security add-generic-password -a "$USER" -s mail-freebsd-smtp -w
# "<client id> <client secret>", separated by a space
security add-generic-password -a "$USER" -s mail-work-oauth-client -w
mail-secret personal >/dev/null && echo ok
```

Elsewhere they are files readable only by the owner (`mail-secret`
refuses anything with group or other permissions):

```sh
mkdir -p ~/.config/mail/secrets && chmod 700 ~/.config/mail/secrets
(umask 077; cat > ~/.config/mail/secrets/personal)    # and so on
```

## 3. Work: OAuth2

Work uses Thunderbird's OAuth2 client, which Netgate already allows. Its
id and secret are the Google entry (`accounts.google.com`) of
`OAuth2Providers.sys.mjs` in Thunderbird's source
(`comm/mailnews/base/src/`, on searchfox.org); store them, separated by
a space, as `work-oauth-client` (above). Then log in once in the
browser, which stores the refresh token:

```sh
mail-oauth2 --authorize work
mail-oauth2 work >/dev/null && echo ok
```

`mail-oauth2 work` prints an access token, refreshed when it is about to
expire. If Google revokes the refresh token (password change, access
removed in the Google account), mbsync and msmtp fail with a message
telling to run `--authorize` again.

On macOS, mbsync finds the XOAUTH2 plugin only with `SASL_PATH` set;
`mail-sync` sets it, a by-hand `mbsync` of Work needs
`SASL_PATH=~/.local/lib/sasl2` in front. The plugin is built by
`chezmoi apply` (needs the Xcode command line tools). On FreeBSD it is
the `cyrus-sasl-xoauth2` package, found without `SASL_PATH`.

## 4. FreeBSD sending: the `garga/mail` principal

Mail from garga@FreeBSD.org goes through smtp.FreeBSD.org:587
(STARTTLS), authenticating as the Kerberos principal `garga/mail`. The
FreeBSD docs do not say how to create it; ask clusteradm if it does not
exist yet. Its password is the `freebsd-smtp` secret. Check it with:

```sh
msmtp -a freebsd --serverinfo
```

Falling back to the plain `garga` principal is a decision to take
explicitly, not a default.

## 5. First sync

`mail-sync -s`, which is what launchd runs, does nothing until the
notmuch database exists. So nothing is synced until the steps below are
done by hand:

```sh
# Work needs the XOAUTH2 plugin (section 3)
export SASL_PATH=~/.local/lib/sasl2

# Check the labels Gmail has against .chezmoidata/mail.yaml
mbsync --list personal
mbsync --list freebsd
mbsync --list work

# INBOX first, then index: this creates ~/Mail/.notmuch and
# enables the launchd runs
mbsync personal-inbox freebsd-inbox work-inbox
notmuch new

# Then everything (or leave it to launchd). All Mail can take more
# than a day: Gmail limits IMAP downloads to about 2.5 GB a day, and
# mbsync just resumes on the next run
mail-sync

# The lists: one small group first, then all of them
nntp-sync -v sudo-announce
nntp-sync -v
```

Logs: `~/Library/Logs/mail-sync.log` on macOS,
`~/.local/state/mail-sync.log` elsewhere. Only output and failures are
logged; past 1 MB the log is moved to `mail-sync.log.0`. The agent is
checked with
`launchctl print gui/$(id -u)/org.rbgarga.mail-sync`.

Each list keeps the days of history set in `mail.yaml`: `mail-sync`
removes the messages that grow older, except the flagged ones. After
raising a list's days, fetch its older history with:

```sh
nntp-sync -v --backfill freebsd-current 720
```

Two optional settings of a group in `mail.yaml` change what is
fetched. `skip` is a Perl regex: the articles whose Subject matches it
are neither fetched nor stored (commits-src skips the commits to
`stable/*`, the branches whose commits are of no interest). `read: true`
delivers every article already read, for the lists used only to look
things up (git). Changing either affects only the articles fetched from
then on; the ones already mirrored are removed or marked read by hand.

## 6. Using neomutt

neomutt starts in the Personal INBOX. The sidebar holds Flagged (all
accounts), then each account's INBOX, label views, Sent and Drafts,
then the Lists.

| Key | Action |
|---|---|
| `gg` / `G` | first / last message |
| `^d` / `^u` | half page down / up |
| `J` / `K` | in a message: line down / up (`j` / `k`: next / previous message) |
| `^j` / `^k` / `^o` | sidebar next / previous / open |
| `B` | toggle the sidebar |
| `,n` / `,p` | open the next / previous mailbox with unread mail |
| `,r` | mark every message of the mailbox read |
| `d` | Delete: move to Trash (INBOX, Sent, Drafts, label views) |
| `y` | Archive: remove from INBOX (INBOX only) |
| `,u` | Unlabel: remove the label (label views only) |
| `r` / `R` / `L` | reply / group reply / list reply; `r` is group reply in list views |
| `F` | Flagged (Gmail's Starred) |
| `\` | notmuch search over everything |
| `S` | sync now (`mail-sync`) |
| `V` | open the HTML part in the browser |
| `^b` | pick a link with urlscan |
| `Tab` (address prompt) | complete from notmuch and the aliases |

Where an action does not apply (e.g. `d` in Flagged or a search, `y`
outside INBOX) the key only prints a message: neomutt's own delete
could remove the All Mail copy and delete the message for good.

Replies use the identity the original was sent to, among the current
account's identities (Work: renato@ by default, garga@ when the message
went there). A reply read from INBOX or a label view is also saved
there (reply copy); FreeBSD mail is also recorded in its Sent, since
smtp.FreeBSD.org keeps no copy. List views always reply from FreeBSD,
to the list and the author, with a Mail-Followup-To that keeps the user
in.

## 7. Risks to verify on a test message

Before relying on them:

1. A reply copy (an APPEND of a message whose Message-ID Gmail already
   has in Sent) should add the label, not duplicate the message.
2. Delete from INBOX and from a label (a new file in the local Trash)
   should trash the message in Gmail; Unlabel (the label's file
   removed) should only remove the label.
3. Netgate accepts Thunderbird's client for IMAP and SMTP, and the
   Work refresh token still works a week after `--authorize`.
4. `garga/mail` exists and can send; the received message carries
   `Authenticated sender: garga/mail`.

## Known limits

- **Flagged and searches** use the Personal account: a reply from there
  only picks between Personal identities. Change From on the compose
  screen if needed.
- **Delete and Unlabel in a label view** only act on a message that
  is under the label. Another one (e.g. the user's own reply shown in
  the thread) is hidden and left alone, which the status line says, and
  is back when the view is reopened.
- **nntp-sync** fetches one article at a time, about 5 a second, so the
  first import of the commit lists takes hours.
- **Spotlight**: `~/Mail/.metadata_never_index` may be ignored by
  recent macOS; if `mds` indexes `~/Mail`, add it to Spotlight's
  privacy list in System Settings.
- **Work's OAuth2 client** is Thunderbird's: if Mozilla rotates it,
  update `work-oauth-client` and run `mail-oauth2 --authorize work`
  again.
- **FreeBSD (e14)**: untested. Sync needs a cron job running
  `mail-sync -s` every 5 minutes (not set up), the neomutt port must
  be built with NOTMUCH (the default package is), and the isync port
  must use cyrus-sasl for Work's XOAUTH2.
- **GPG**: the key `39BE8FC7125C657A` is expired; signing needs a renewed
  key.
- **Thunderbird** keeps working in parallel on the same accounts.
