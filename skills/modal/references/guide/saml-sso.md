# Custom SAML SSO

<Callout variant="gated-feature">
Custom SAML SSO is available on the <a href="/pricing">Enterprise plan</a>. Contact <a href="mailto:sales@modal.com">sales@modal.com</a> for more information.
</Callout>

If you use an identity provider (IdP) other than Okta, you can configure custom SAML SSO for your Modal Workspace.

For provider-specific setup, see our [Okta SSO documentation](/docs/guide/okta-sso)
or [Microsoft Entra SSO documentation](/docs/guide/entra-sso).

## Prerequisites

* A Workspace that's on an [Enterprise](/pricing) plan
* Admin access to the Workspace you want to configure with SSO
* Admin privileges for your identity provider

## Supported features

* Identity Provider (IdP) initiated SSO
* Service Provider (SP) initiated SSO
* Just-In-Time account provisioning

## Configuration

### Modal SAML settings

Configure your IdP with the following settings:

| Setting   | Value                                             |
| --------- | ------------------------------------------------- |
| Entity ID | `https://www.modal.com`                           |
| ACS URL   | `https://modal.com/api/okta/saml/sso/<workspace>` |

Replace `<workspace>` with your Modal Workspace name. If you later
[rename your Workspace](/docs/guide/workspaces#renaming-a-workspace), update
the ACS URL and the login URL below to the new name.

### Required SAML attributes

Your IdP must send the following SAML attributes:

| Attribute | Description          |
| --------- | -------------------- |
| email     | User's email address |
| firstName | User's first name    |
| lastName  | User's last name     |

### Configuration steps

#### Step 1: Configure your IdP

1. Create a new SAML application in your identity provider
2. Set the Entity ID to `https://www.modal.com`
3. Set the ACS URL to `https://modal.com/api/okta/saml/sso/<workspace>` (replace `<workspace>` with your Workspace name)
4. Configure the required SAML attributes (email, firstName, lastName)
5. Ensure your IdP signs SAML assertions

#### Step 2: Link your Workspace to your IdP

1. Obtain the SAML Metadata URL from your IdP
2. Sign in to https://modal.com and visit your [Workspace Management](/settings/workspace-management/identity-and-provisioning) page's `Identity and Provisioning` tab
3. Paste the Metadata URL in the input and click "Save Changes"

#### Step 3: Test the integration

1. Assign users in your IdP
2. Test IdP-initiated SSO by clicking the Modal application in your IdP dashboard
3. Test SP-initiated SSO by visiting the login URL below

#### Step 4: Read this before you enable "Require SSO"

Enabling "Require SSO" will force all users to sign in via SSO. Ensure that you
have admin access to your Modal Workspace through your identity provider before
enabling.

## Login URL

This URL can be used so that users can sign-in to the correct workspace from your IdP.

`https://modal.com/login/sso?workspace=<workspace>` (replace `<workspace>` with your workspace name)
