# SCIM Integration

<Callout variant="gated-feature">
SCIM support is available on the <a href="/pricing">Enterprise plan</a>. Contact <a href="mailto:sales@modal.com">sales@modal.com</a> for more information.
</Callout>

[SCIM (System for Cross-domain Identity Management)](https://datatracker.ietf.org/doc/html/rfc7643)
is a protocol that identity providers (IdPs) use to automate user management in
connected apps.

Modal supports SCIM for automatic provisioning and deprovisioning of users and
[user groups](/docs/guide/user-groups).

## Prerequisites

* A Workspace that's on an [Enterprise](/pricing) plan, with SCIM enabled
* The Workspace Owner or Workspace Manager Role in the Workspace you want to
  configure with SCIM
* Admin privileges for your IdP

## Connecting an IdP

### Step 1: Generate a SCIM token

1. Open the **Identity and Provisioning** tab on the
   [Workspace Management settings page](/settings/workspace-management/identity-and-provisioning).
   If SCIM is enabled for your Workspace, a **SCIM Tokens** section appears
   below the **Single Sign-On (SSO)** section. If you don't see it, contact
   <support@modal.com> to enable SCIM for your
   Workspace.
2. Click **New SCIM Token**, then click **Create Token**.
3. Copy the value from the **Token Secret** box and store it somewhere secure.
   The dialog also shows the **SCIM Endpoint** URL for your Workspace, which
   some IdPs require.

   This is the only time Modal shows the token secret. After you click **Done**,
   you can't view it again; if you lose it, generate a new token.

### Step 2: IdP configuration

#### Okta

1. Create a new SCIM integration or select your existing custom app.

   If you use the [Modal catalog app](https://www.okta.com/integrations/modal/)
   for [Okta SSO](/docs/guide/okta-sso), create a separate private SCIM
   integration. Your existing Modal app can continue to handle SSO; don't add
   SSO to the new SCIM integration.

   If you use a custom app for SSO, you can reuse it for SCIM provisioning.
   Select your existing app in the Okta Admin Console and continue to step 2.

   To create a new integration in the Okta Admin Console:

   1. Go to **Applications > Applications**.
   2. Click **Create a new app integration**.
   3. Select **Okta Integration Wizard**.
   4. Choose **Provisioning** as the capability.
   5. Choose **SCIM 2.0** as the provisioning method.

2. Configure the integration with your Modal SCIM credentials.

   In the new integration wizard or your existing custom app's provisioning
   settings, enter the following values. Replace `<workspace>` with your
   Modal Workspace name.

   | Okta setting                      | Modal value                                           |
   | --------------------------------- | ----------------------------------------------------- |
   | SCIM connector base URL           | `https://modal.com/api/<workspace>/scim/v2`           |
   | Unique identifier field for users | `userName`                                            |
   | Authentication mode               | HTTP Header                                           |
   | Authorization                     | The full SCIM token generated in step 1               |
   | Supported provisioning actions    | Push New Users, Push Profile Updates, and Push Groups |

   Click **Test API Credentials**. If you created a new integration, review and
   deploy it. When prompted, add an app instance from your organization's
   **Private apps** catalog.

   In the app instance's **Provisioning > To App** settings, enable
   **Create Users**, **Update User Attributes**, and **Deactivate Users**.
   Assign the people and groups that Okta should provision to Modal.

   For more information, see Okta's
   [Okta Integration Wizard documentation](https://help.okta.com/en-us/Content/Topics/Apps/oiw/create-app-integration.htm).

#### Microsoft Entra ID

1. Create or select an enterprise application.

   In the [Microsoft Entra admin center](https://entra.microsoft.com/):

   * If you already have a Modal enterprise application that you use for
     [Microsoft Entra SSO](/docs/guide/entra-sso), you can reuse it for SCIM
     provisioning. Go to **Entra ID > Enterprise apps** and select the
     application.
   * Otherwise, go to **Entra ID > Enterprise apps** and create an application:
     1. Select **New application > Create your own application**.
     2. Enter a name such as `Modal SCIM`.
     3. Select **Integrate any other application you don't find in the gallery
        (Non-gallery)** and create the application.

2. Configure the application with your Modal SCIM credentials.

   Open the enterprise application, select **Provisioning > New configuration**,
   and enter the following values. Replace `<workspace>` with your Modal
   Workspace name.

   | Entra setting | Modal value                                 |
   | ------------- | ------------------------------------------- |
   | Tenant URL    | `https://modal.com/api/<workspace>/scim/v2` |
   | Secret Token  | The full SCIM token generated in step 1     |

   Select **Test Connection**, then create the provisioning configuration.
   Review the user attribute mappings and ensure that an email address is mapped
   to `userName`. Assign the users and groups that Entra should provision, then
   select **Start provisioning**.

   For more information, see Microsoft's
   [SCIM provisioning documentation](https://learn.microsoft.com/en-us/entra/identity/app-provisioning/use-scim-to-provision-users-and-groups#integrate-your-scim-endpoint-with-the-microsoft-entra-provisioning-service).

#### Other IdPs

1. Create a custom SCIM integration.

   Create a custom or non-gallery application that supports outbound SCIM 2.0
   provisioning. Name it something recognizable, such as `Modal SCIM`. An
   existing SSO integration can continue to handle authentication; whether the
   SCIM integration must be a separate app depends on your IdP.

2. Configure the integration with your Modal SCIM credentials.

   Find your IdP's equivalent settings and enter the following values.
   Replace `<workspace>` with your Modal Workspace name.

   | Setting                | Modal value                                 |
   | ---------------------- | ------------------------------------------- |
   | SCIM version           | 2.0                                         |
   | SCIM base URL          | `https://modal.com/api/<workspace>/scim/v2` |
   | Authorization method   | Bearer token                                |
   | Token                  | The full SCIM token generated in step 1     |
   | Unique user identifier | Email address in `userName`                 |

   Enable creating, updating, and deactivating users. You can also enable group
   provisioning. Test the connection, assign the users and groups that your IdP
   should provision, and start provisioning.

Modal supports the following SCIM capabilities:

| Capability                         | Supported | Notes                         |
| ---------------------------------- | --------- | ----------------------------- |
| SCIM 2.0                           | Yes       |                               |
| Pagination                         | Yes       |                               |
| Create, update, and remove users   | Yes       |                               |
| Create, update, and delete groups  | Yes       |                               |
| Update group membership with PATCH | Yes       |                               |
| Generate temporary passwords       | No        | Modal authentication uses SSO |

Your IdP may also ask which user attributes Modal supports:

| SCIM user attribute | Modal support | Notes                                           |
| ------------------- | ------------- | ----------------------------------------------- |
| externalId          | Yes           |                                                 |
| userName            | Yes           | Required; must contain the user's email address |
| displayName         | Yes           |                                                 |
| name.familyName     | Yes           |                                                 |
| name.givenName      | Yes           |                                                 |
| emails              | Read-only     | The primary email is derived from `userName`    |
| active              | Yes           |                                                 |
| addresses           | No            |                                                 |
| profileUrl          | No            |                                                 |

## Managing tokens

Only Workspace Owners and Workspace Managers can manage SCIM tokens.

Up to two SCIM tokens can be active at a time, so you can rotate tokens without
dropping updates:

1. Generate a new token.
2. Replace the old token with the new one in your IdP.
3. Revoke the old token.

Outside of a rotation, keep only one SCIM token active as a security best
practice.

## Troubleshooting

### Your IdP can't authenticate with Modal

Confirm that you copied the full token. It has the form
`si-XXXXXXXXXXXXXXXXXXXXXX:ss-XXXXXXXXXXXXXXXXXXXXXX`.

### A group push fails with an "already exists" error

Your Workspace already has a group with the same name, ignoring case. Group
names must be unique across custom and SCIM groups, so rename one of the
conflicting groups before retrying the push. See
[Group name conflicts](/docs/guide/user-groups#group-name-conflicts) for
details.

### Other issues

If you have any issues with or questions about SCIM integration, reach out via
[Slack](/slack) or email us at <support@modal.com>.
