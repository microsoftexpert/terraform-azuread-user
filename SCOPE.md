# SCOPE — tf-mod-azuread-user

## In scope
- `azuread_user.this` — one cloud-only Entra ID user account

## Out of scope (consumed/owned elsewhere)
- Guest / B2B users → `tf-mod-azuread-invitation`
- On-premises-synced (hybrid) users → owned by Azure AD Connect / Entra Cloud Sync
- Group membership, administrative-unit membership/role scoping, directory-role assignment, access-package requestor/approver association → consume this module's `object_id`

## Data sources used
- `data.azuread_user` (read-only lookup)
- `data.azuread_users` (read-only lookup)
- `data.azuread_domains` (read-only lookup)

> ℹ️ This module does **not** itself declare these data sources — it manages only `azuread_user.this`.
> They are listed because callers commonly pair them with this module (e.g. resolving a verified
> domain for the UPN suffix, or looking up an existing manager). Read-only lookups need only
> `User.Read.All` / `Directory.Read.All`.

## Graph API permissions required
| Permission | Type | Required for |
|---|---|---|
| `User.ReadWrite.All` | Application | Create / update / delete the user, and read it on plan/refresh. **Least-privileged** for this resource. |
| `Directory.ReadWrite.All` | Application | Higher-privilege alternative that also satisfies the resource (prefer `User.ReadWrite.All`). |

- Requires **admin consent**. Missing/un-consented → `403 Authorization_RequestDenied` at plan/apply.
- **Sensitive-action escalation:** creating/managing a user who holds a *privileged admin role*
  requires the SP to *also* be assigned a directory role (e.g. User Administrator,
  Privileged Authentication Administrator) — application permission alone is insufficient.
- User-principal auth instead of an SP → needs the **User Administrator** or **Global Administrator** directory role.
- No P2 licensing required for user CRUD.

## Emits
| Output | Description | Typically consumed by |
|---|---|---|
| `object_id` | Object ID of `azuread_user` | **Primary key** — `tf-mod-azuread-group` (`members[*].member_object_id`), `tf-mod-azuread-administrative-unit` (`members[*].member_object_id` / `role_members[*].member_object_id`), `tf-mod-azuread-directory-role` / `tf-mod-azuread-pim-group` (principal), `tf-mod-azuread-access-package` (requestor/approver `singleUser` reference), another user's `manager_id` |
| `id` | Fully-qualified Graph ID (`/users/<object_id>`) | Direct Graph references, import |
| `user_principal_name` | UPN (primary sign-in identifier) | External system config, mail routing, audit |
| `display_name` | Address-book display name | Logging, drift reports |
| `mail` | SMTP address (may be computed by Exchange/Graph) | Distribution-list / notification wiring |
| `mail_nickname` | Mail alias (defaults to UPN prefix) | Exchange addressing |
| `account_enabled` | Whether sign-in is enabled | Lifecycle/staging logic |
| `user_type` | `"Member"` for cloud-only users here | Branch logic (`Guest` only via invitation) |
| `creation_type` | Account origin (`null` for work/school) | Provenance checks; `try(..., null)` |
| `im_addresses` | IM/VOIP SIP addresses (read-only) | Informational; `try(..., [])` |
| `proxy_addresses` | Mailbox proxy addresses (read-only) | Mail routing diagnostics; `try(..., [])` |
| `onpremises_sync_enabled` | On-prem sync state (`null` cloud-only) | Hybrid drift checks; `try(..., null)` |

> 🔐 **No credential output.** `password` is a write-only **input** held in state and is
> deliberately **not** emitted — there is nothing to re-read from Graph and re-exporting it would
> only widen exposure. No output on this module is `sensitive`.

## Provider notes / gotchas (verified against hashicorp/azuread v3.9.0)
- **No `ForceNew` attributes.** Nothing on `azuread_user` forces destroy/recreate — including
  `user_principal_name`, which the provider updates **in place** (Graph PATCH). The earlier
  "UPN is immutable / forces recreate" note was incorrect and has been corrected.
- **UPN is a stable identity, not immutable.** Per Microsoft guidance, treat `object_id` as the
  durable identifier. A UPN change is in-place but operationally consequential: breaks sign-in,
  invalidates tokens, can spawn a new JIT profile in downstream SaaS/LoB apps, and can suppress
  Authenticator notifications until re-registration.
- **UPN suffix must be a verified tenant domain** — otherwise Entra rewrites it to
  `<tenant>.onmicrosoft.com`. The module validates UPN *shape* only; domain verification is server-side.
- **`password` is write-only** — Graph never returns it after creation. Required on create; may be
  null on import (the provider won't reset an imported user's password unless the value changes).
  Blank/removed password does **not** clear it server-side. No native rotation block — rotate by
  changing the value (e.g. keyed on `time_rotating`).
- **`usage_location`** is required before license assignment and **cannot be reset to null** once set
  (can be changed to another code). Group-based licensing never back-fills it — set at creation.
- **`mail`** cannot be unset once specified (can be changed, not cleared).
- **`business_phones`** accepts at most one number (Graph constraint; enforced by module validation).
- **Cloud-only users** must complete a first-sign-in password change to generate credential hashes
  for downstream services (e.g. Entra Domain Services) — `force_password_change = true` drives this.
- **30-day soft delete** — deleted users are restorable from `deletedItems` for 30 days.
- **Eventual consistency** — brief replication lag after create can cause "resource not found" on
  immediately-dependent group/role resources; rely on the dependency graph, extend `timeouts` for batches.

## Design decisions
- **Standalone single-resource module** — one `azuread_user.this`, four files, no `provider {}` block.
- **Flat top-level variables** mirror the provider 1:1 (the resource has no nested blocks except
  `timeouts`), per the house rule "mirror the provider's block structure in the type."
- **Secure-by-default account controls** — `force_password_change`, password expiry, and
  strong-password enforcement default to the choice defensible in a security review.
- **No `tags`** (`azuread_user` does not support them); **no `resource_group_name`** (tenant-scoped).
