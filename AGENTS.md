# zoho-mail agent instructions

A Ruby client for Zoho Mail's REST API, built on Active Resource, with a command
line interface in `bin/zoho-mail`.

## Public repository

- This repository is public. Never commit personal data or account details: no
  real email addresses, domains, organisation, account or user IDs, OAuth client
  IDs, secrets or tokens. Examples and fixtures use example.com, example.org and
  example.net, and invented IDs.
- Credentials come only from environment variables: `ZOHO_CLIENT_ID`,
  `ZOHO_CLIENT_SECRET`, `ZOHO_REFRESH_TOKEN` and `ZOHO_DOMAIN`.

## Ruby

- Follow omakase Ruby styling (`rubocop-rails-omakase`). `bundle exec
  rubocop` must pass.
- Order methods top to bottom in the order they are called, including private
  methods and test helpers.
- Comment only facts the code cannot show, such as Zoho behaviour that differs
  from its documentation. No header comments, and no comments that repeat what a
  method does.
- No `# frozen_string_literal`, and no `.freeze` unless it makes a measurable
  difference to performance. Use named block parameters, not `_1` or `it`. Name a
  method `foo!` only when a `foo` also exists.
- The CLI only formats output. Logic goes in the models.

## Domain modeling

- One Active Resource model per Zoho Mail resource: `Account`, `Domain`, `User`,
  `Subscription`. Name a model for what it represents in Zoho Mail, not for its
  endpoint: Zoho's API calls an organisation's users "accounts", and the model is
  `User`.
- Keep Zoho's payload keys inside the models. Callers use readers named for what
  the value means, such as `domain.verified?` rather than
  `domain.verificationStatus`. An extraction moves the rules with the data.
- Give collections and instances expressive APIs, as Active Record does:
  `domains.pending` and `domain.verified?`, `users.admins` and `user.aliases`.
  Collections own selection; instances own their state and behaviour.
- Zoho makes most changes with a PUT whose body names the change as `mode`. Wrap
  each mode in a method named for the change, such as `domain.verify` or
  `user.add_alias`, that calls `Base#change`.
- Name constants for values whose meaning is not obvious at the call site, and
  keep each constant with the model that owns the rule.
- Use Active Support duration helpers for times and timeouts, such as
  `REQUEST_TIMEOUT = 10.seconds` and `1.hour.from_now`. Convert units only where
  an API needs something else.
- Generalize from concrete uses. Add an endpoint when something needs it; avoid
  speculative base classes and options.

## Tests

- Minitest with `ActiveSupport::TestCase` and `test "..." do`. `bundle exec rake
  test` must pass.
- Stub Zoho Mail's API with `ActiveResource::HttpMock`, Zoho's OAuth server with
  WebMock, and other collaborators with mocha (`stubs`, `expects`), not
  `Minitest::Mock`.
- Load API responses from `test/fixtures/*.json`. Base a new fixture on the
  sample response in Zoho's documentation for that endpoint, with invented
  values. Name fixtures for what makes them different
  (`users_as_single_object`), not `users_two`.
- Name variables for the thing and its role, including in tests:
  `primary_domain`, `added_domain`.

## Writing

- Docs, comments and commit messages say what happens, without metaphors,
  idioms or anthropomorphism.
