# zoho-mail

A Ruby client for the [Zoho Mail REST API](https://www.zoho.com/mail/help/api/),
built on [Active Resource](https://github.com/rails/activeresource), with a
command line interface for an organisation's account, subscription, domains and
users.

It covers the endpoints that the models in `lib/zoho_mail/` use. Zoho's API has
many more.

## Requirements

- Ruby 3.4 or later.
- A Zoho Mail account. The organisation commands need an organisation admin.

## Setup

```
git clone https://github.com/lewispb/zoho-mail
cd zoho-mail
bundle install
```

1. In Zoho's API console, https://api-console.zoho.com (or the console of your
   data centre), choose **Add Client**, then **Self Client**.
2. Set the client's ID and secret as environment variables, `ZOHO_CLIENT_ID`
   and `ZOHO_CLIENT_SECRET`. If your Zoho account is not in the US data centre,
   also set `ZOHO_DOMAIN` to your data centre's domain, such as `zoho.eu`,
   `zoho.in`, `zoho.com.au`, `zoho.jp` or `zohocloud.ca`.
3. In the Self Client, open **Generate Code**, enter the scopes and a time
   duration, and create the code. The read-only commands need:

   ```
   ZohoMail.accounts.READ,ZohoMail.organization.accounts.READ,ZohoMail.organization.domains.READ,ZohoMail.organization.subscriptions.READ
   ```

   To add and verify domains and add aliases too, use
   `ZohoMail.organization.domains.ALL` and `ZohoMail.organization.accounts.ALL`
   in place of their `READ` scopes.
4. Before the code expires, exchange it for a refresh token:

   ```
   bin/zoho-mail login <code>
   ```

   The command prints the refresh token. Store it in a password manager, and set
   it as `ZOHO_REFRESH_TOKEN`.

Set the variables from your password manager rather than in your shell history
or a file, for example with 1Password's CLI:
`op run --env-file .env -- bin/zoho-mail domains`, where `.env` holds
`op://` references. Git ignores `.env*` files.

Access tokens last an hour. Zoho limits how many access tokens a refresh token
can issue in ten minutes, so the client keeps the current one in
`$XDG_RUNTIME_DIR`, which is in memory and readable by your user only.

## Commands

```
bin/zoho-mail account        your account: its address, role, organisation ID and plan type
bin/zoho-mail subscription   the organisation's plan, add-ons and expiry date
bin/zoho-mail domains        the organisation's domains and their status
bin/zoho-mail users          the organisation's users and their addresses
bin/zoho-mail console        an IRB session with the ZohoMail models loaded
```

## Ruby

In `bin/zoho-mail console`:

```ruby
zoid = ZohoMail.organization_id

domains = ZohoMail::Domain.all(params: { zoid: zoid })
domains.pending.map(&:name)

domain = ZohoMail::Domain.create(zoid: zoid, domainName: "example.com")
domain.txt_verification_record # the TXT record to add to the domain's DNS
domain.verify
domain.enable_mail_hosting

users = ZohoMail::User.all(params: { zoid: zoid, limit: 100 })
users.admins.map(&:email_address)
users.first.add_alias("hello@example.com")

ZohoMail::Subscription.find(params: { zoid: zoid })
```

## Development

```
bundle exec rake test
bundle exec rubocop
```

The test fixtures are based on the sample responses in Zoho's documentation.
AGENTS.md describes the coding style.

## License

MIT. See LICENSE.
