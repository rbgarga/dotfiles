# Work logs in with OAuth2, as Thunderbird's client

Netgate's Workspace allows no app passwords, so Work logs into Gmail
(IMAP and SMTP) with OAuth2, while Personal and FreeBSD keep app
passwords, which need no token handling. The OAuth2 client is
Thunderbird's public one: Netgate already lets Thunderbird reach the
account, whereas a client registered in a project of our own could be
blocked by the Workspace admin, and its refresh tokens expire after 7
days until the project is published. The cost is posing as Thunderbird,
which Google's terms do not allow, and depending on Mozilla never
rotating that client; its id and secret stay out of this repo, as a
mail-secret.

## Considered Options

- **mbsync XOAUTH2**: Homebrew's isync uses the system libsasl2, whose
  own OAUTHBEARER plugin needs an Apple-specific callback mbsync does
  not provide. The cyrus-sasl-xoauth2 plugin, built from a pinned commit
  into `~/.local/lib/sasl2` and found through `SASL_PATH`, works with
  that isync. Rejected: the benswift/homebrew-tap isync, a rebuild of
  isync and cyrus-sasl from a two-commit tap whose build was broken by
  openssl@4; and email-oauth2-proxy, one more daemon between mbsync and
  Gmail.
- **Tokens**: `mail-oauth2`, a stdlib-only script, rather than neomutt's
  `mutt_oauth2.py`, which keeps its tokens in a GPG-encrypted file (the
  user's key is expired); the refresh token goes to the Keychain through
  mail-secret, like every other secret.
