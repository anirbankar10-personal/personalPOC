---
name: setup-email-to-case
description: Build every Salesforce configuration and metadata component required to stand up one Email-to-Case mailbox, in dependency-safe order, from a single mailbox name.
license: Proprietary
user-invocable: true 
---

# Setup Email-to-Case Mailbox

This skill is invoked as **`/setup-email-to-case <mailbox name>`**. It builds the complete,
end-to-end configuration for **one** mailbox: Email-to-Case, its dedicated Record Type, Queues,
Business Hours, Presence/Routing configuration, Entitlement Process, Email Templates, sharing,
permission sets, and every dependent Custom Metadata Type (CMDT) record. It is designed to be
run once per mailbox (up to ~30 times for the full migration), producing identically-patterned,
uniquely-named components each time.

**Do not skip ahead.** The phases below are ordered so that every component only references
components that already exist. Complete each phase fully — and capture the Ids/API names it
produces — before starting the next one.

---

## Step 0 — Resolve inputs

### 0.1 Required argument
- `mailbox_name` — the mandatory argument to this command (e.g. `Support Inquiries`). This is
  the human-readable name customers and agents will see. If it was not supplied when the
  command was invoked, **stop and ask the user for it** before doing anything else.

### 0.2 Derive the abbreviation
Every component below needs a short, API-safe **abbreviation** (`[Mailbox abbreviation]`)
because Salesforce API names cannot contain spaces and have length limits. Derive a candidate
automatically:
- Take the initials of each word in `mailbox_name`, uppercase them (e.g. `Support Inquiries` →
  `SI`). If that collides with an abbreviation already used by another mailbox in the org (check
  existing Record Types / Queues named `<abbr> Case`, `Email <abbr> Queue`, etc.), fall back to a
  longer, still-readable abbreviation (e.g. `SUPINQ`).
- **Show the derived abbreviation to the user and ask them to confirm or override it** before
  proceeding — it gets baked into every API name created in this run and is painful to rename
  later.

### 0.3 Gather the remaining details up front
The rest of the build needs a handful of business values that cannot be derived from the
mailbox name alone. Ask for all of them now, in one pass, so the run isn't interrupted later.
If the user has already supplied any of these (in this conversation or a prior run for this
mailbox), reuse them instead of re-asking:

| Needed for | Ask the user for |
|---|---|
| Email-to-Case routing | The actual inbound email address for this mailbox (or confirm it will be created/forwarded separately) |
| Business Hours | Operating days/hours and time zone for this mailbox's SLA clock |
| Entitlement Process | SLA milestone targets (e.g. first response / resolution times) to apply |
| Status Based Routing | Which Case Status values route to the "Email" queue vs. the "Pending" queue (the sheet reserves 3 slots for the Email queue and 2 for the Pending queue — ask which statuses fill each) |
| Record Types to Profiles Map | The Profile (or Permission Set Group, if that's how agents are licensed) that should be mapped to this mailbox's Record Type |
| Custom Notifications Template Mapping | Confirm the notification should point at the auto-acknowledgement/agent-assignment template built in Phase 1 (default), or a different existing template |
| Reminder Template Merge Field | For each reminder template (Agency, MOP First–Fourth), the merge field API name(s) on the template and the Salesforce merge field they map to |
| Public Groups / Sharing | Initial members (users or roles) for the Agents, Managers, and KM Approval groups, if known now |

Record the confirmed `mailbox_name` and `abbreviation` and reuse them literally in every step
below — do not re-derive names mid-run.

### 0.4 Naming key
Throughout this skill, `{Name}` = the confirmed `mailbox_name` and `{Abbr}` = the confirmed
abbreviation. Every target name below is copied directly from the customer's component list.

### 0.5 Idempotency
Before creating any component, check whether one with the resolved name/API name already
exists in the org (or already exists in the local source under `force-app`). If it exists,
reuse it and its Id rather than creating a duplicate — report this to the user instead of
silently skipping.

---

## Phase 1 — Independent, foundational components
None of these reference anything else created in this run. Build all of them first.

1. **Business Hours** — `{Abbr} Operating Hours`. Configure per the hours/time zone gathered in
   Step 0.3.
2. **Public Groups** (3, empty for now unless members were given in Step 0.3):
   - `{Abbr} KM Approval Group`
   - `{Abbr} Agents`
   - `{Abbr} Managers`
3. **Queues** (Object: `Case`, 2):
   - `Email {Abbr} Queue`
   - `Pending {Abbr} Queue`
4. **Lightning Email Templates** (Object: `Case` where noted):
   - `{Abbr}_Auto_Acknowledgement`
   - `{Abbr} Reminder To Agency`
   - `{Abbr} Reminder To MOP First`
   - `{Abbr} Reminder To MOP Second`
   - `{Abbr} Reminder To MOP Third`
   - `{Abbr} Reminder To MOP Fourth`
   - `{Abbr}_Reminder_To_MOP_Email_Template` (Object: `Case`)
5. **Classic Email Template**: `{Abbr}_CSAT_Survey_Resolved_Case`
6. **Quick Action** (Object: `Case`): `SendEmail`

> Keep every Id / API name you just created (queues, templates, groups) — Phases 3 and 4 need
> them.

---

## Phase 2 — Case Record Type and its picklist value
Depends on Phase 1 only for naming consistency, not for Ids — but must exist before Phase 3/4,
which reference this Record Type's Id everywhere.

7. **Record Type** (Object: `Case`): `{Abbr} Case`
8. **Picklist Value** (Object: `Case`, field: `Sub Case Origin`): add value `{Name}`, then add it
   to the picklist's controlling-value list for the `{Abbr} Case` record type created in step 7.

---

## Phase 3 — Configuration that depends on Phases 1–2
Build in this order — each item leans on the Business Hours, Record Type, or Queues above.

9. **Entitlement Process**: `{Abbr} SLA Entitlement` — attach `{Abbr} Operating Hours`
   (Phase 1) as its Business Hours, scope it to the `{Abbr} Case` Record Type (Phase 2), and
   apply the SLA milestones gathered in Step 0.3.
10. **Presence Configuration**: `{Abbr} Agent Presence Config` — reference the service channel
    tied to the queues from Phase 1.
11. **Routing Configuration**: `{Abbr}_Case_Routing_Config` — route to `Email {Abbr} Queue` /
    `Pending {Abbr} Queue` (Phase 1) using the Presence Configuration from step 10, scoped to the
    `{Abbr} Case` Record Type (Phase 2).
12. **Permission Sets**:
    - `PSD {Abbr} View Case`
    - `PSD {Abbr} Edit Case`
    Grant object permissions on `Case` plus Record Type visibility for `{Abbr} Case` (View → read
    only; Edit → read/write), matching the org's existing pattern for other mailboxes' permission
    sets if one exists to copy.
13. **Sharing Settings** (Case sharing rules or manual-sharing config, per the org's existing
    pattern): `{Abbr} Agents Share Cases`, `{Abbr} Managers Share Cases` — share `{Abbr} Case`
    records with the `{Abbr} Agents` / `{Abbr} Managers` public groups from Phase 1.

---

## Phase 4 — Custom Metadata Types and records
These CMDTs are **shared across all mailboxes**. Only create the object/fields the first time
this skill runs in the org; every subsequent run just adds records to types that already exist.

### 4.1 Ensure the Custom Metadata Types exist (create only if missing)

| Custom Metadata Type | Fields to create if the type doesn't exist |
|---|---|
| Data Category to Group Map | `Record_Type_Id__c` (Text/Lookup-style Id), `Group_Id__c` (Text) |
| Status Based Routing | `Case_Status__c` (Text/Picklist), `Queue_Id__c` (Text) |
| Email Address Config | `Record_Type_Id__c` (Text), `Email_Addresses__c` (Text, long enough for multiple addresses) |
| Send Reminder Excluded Emails | `Record_Type_Id__c` (Text), `Email_Addresses__c` (Text) |
| Record Types to Profiles Map | `Record_Type_Id__c` (Text), `Profile_Id__c` (Text) |
| Custom Notifications Template Mapping | `Record_Type_Id__c` (Text), `Email_Template_Id__c` (Text) |
| Reminder Template Merge Field | `Email_Template_Id__c` (Text), `Field_on_Template__c` (Text), `Merge_Field__c` (Text) |

Before creating any of these seven types, check the org (or `force-app/main/default/objects`)
for an existing type that matches by label/purpose — reuse it rather than creating a duplicate
with different field names.

### 4.2 Insert this mailbox's records
Use the actual Ids/API names captured in Phases 1–2, not placeholder text.

| Type | Record name | Field values |
|---|---|---|
| Data Category to Group Map | `{Abbr}` | Record Type Id = `{Abbr} Case`; Group Id = `{Abbr} KM Approval Group` |
| Status Based Routing | `{Abbr} Queue Routing` | Case Status = 1st status from Step 0.3; Queue Id = `Email {Abbr} Queue` |
| Status Based Routing | `{Abbr} Queue Routing2` | Case Status = 2nd status from Step 0.3; Queue Id = `Email {Abbr} Queue` |
| Status Based Routing | `{Abbr} Queue Routing3` | Case Status = 3rd status from Step 0.3; Queue Id = `Email {Abbr} Queue` |
| Status Based Routing | `Pending {Abbr} Queue Routing` | Case Status = 1st "pending" status from Step 0.3; Queue Id = `Pending {Abbr} Queue` |
| Status Based Routing | `Pending {Abbr} Queue Routing2` | Case Status = 2nd "pending" status from Step 0.3; Queue Id = `Pending {Abbr} Queue` |
| Email Address Config | `Auto Ack {Abbr}` | Record Type Id = `{Abbr} Case`; Email Addresses = the auto-acknowledgement sender/reply address from Step 0.3 |
| Email Address Config | `Other {Abbr} Notifications` | Record Type Id = `{Abbr} Case`; Email Addresses = other notification recipients from Step 0.3 |
| Send Reminder Excluded Emails | `{Abbr} Mailbox` | Record Type Id = `{Abbr} Case`; Email Addresses = this mailbox's own inbound address (so it never reminds itself) |
| Record Types to Profiles Map | `{Abbr} Agent Record Type` | Record Type Id = `{Abbr} Case`; Profile Id = the Profile/PSG confirmed in Step 0.3 |
| Custom Notifications Template Mapping | `Notification_to_{Abbr}_Agent` | Record Type Id = `{Abbr} Case`; Email Template Id = the notification template confirmed in Step 0.3 |
| Reminder Template Merge Field | `{Abbr} Case Agency` | Email Template Id = `{Abbr} Reminder To Agency`; Field on Template / Merge Field per Step 0.3 |
| Reminder Template Merge Field | `{Abbr} Case MOP First` | Email Template Id = `{Abbr} Reminder To MOP First`; Field on Template / Merge Field per Step 0.3 |
| Reminder Template Merge Field | `{Abbr} Case MOP Second` | Email Template Id = `{Abbr} Reminder To MOP Second`; Field on Template / Merge Field per Step 0.3 |
| Reminder Template Merge Field | `{Abbr} Case MOP Third` | Email Template Id = `{Abbr} Reminder To MOP Third`; Field on Template / Merge Field per Step 0.3 |
| Reminder Template Merge Field | `{Abbr} Case MOP Fourth` | Email Template Id = `{Abbr} Reminder To MOP Fourth`; Field on Template / Merge Field per Step 0.3 |

---

## Phase 5 — Activate Email-to-Case
This is last on purpose: it wires together the Record Type, Queue, and templates from every
prior phase and turns the mailbox live.

14. **Email-to-Case**: `{Name}` — set the routing address to the mailbox address from Step 0.3;
    default Case Record Type = `{Abbr} Case` (Phase 2); default Case Owner = `Email {Abbr} Queue`
    (Phase 1); auto-response template = `{Abbr}_Auto_Acknowledgement` (Phase 1). Activate the
    email service only after confirming every referenced component above deployed successfully.

---

## Completion checklist
Before reporting the run as done, confirm all of the following exist and are correctly
cross-referenced:
- [ ] All Phase 1 components created (Business Hours, 3 Public Groups, 2 Queues, 7 templates,
      1 quick action)
- [ ] `{Abbr} Case` Record Type exists and the `{Name}` picklist value is active on it
- [ ] Entitlement Process, Presence Configuration, Routing Configuration, both Permission Sets,
      and both Sharing Settings created and pointing at the right Record Type/Queues/Groups
- [ ] All 7 Custom Metadata Types exist in the org (created once, shared) and all 15 records for
      `{Abbr}` are inserted with real Ids (no literal placeholder text left in any field)
- [ ] Email-to-Case for `{Name}` is active and routes to `{Abbr} Case` / `Email {Abbr} Queue`
- [ ] Report back to the user the final `{Abbr}` used and a one-line summary of anything you had
      to assume rather than being told explicitly
