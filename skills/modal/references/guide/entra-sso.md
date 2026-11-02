# Microsoft Entra SSO

<Callout variant="gated-feature">
Microsoft Entra SSO is available on the <a href="/pricing">Enterprise plan</a>. Contact <a href="mailto:sales@modal.com">sales@modal.com</a> for more information.
</Callout>

## Prerequisites

* A Workspace that's on an [Enterprise](/pricing) plan
* Admin access to the Workspace you want to configure with
  Microsoft Entra Single-Sign-On (SSO)
* Admin privileges for your Microsoft Entra organization, such as the Cloud
  Application Administrator or Application Administrator role

## Supported features

* Identity Provider (IdP) initiated SSO
* Service Provider (SP) initiated SSO
* Just-In-Time account provisioning

## Configuration

### Read this before you enable "Require SSO"

Enabling "Require SSO" will force all users to sign in via Microsoft Entra.
Ensure that you have admin access to your Modal Workspace through a
Microsoft Entra account before enabling.

### Configuration steps

#### Step 1: Add Modal app to Microsoft Entra Applications

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com/).
2. Navigate to "Entra ID > Enterprise apps > All applications" and select
   "New application".
3. Select "Create your own application".
4. Name the application `Modal`, select "Integrate any other application you
   don't find in the gallery (Non-gallery)", and create the application.
5. Open "Single sign-on" for the application and select "SAML".

For more information, see Microsoft's guides to
[adding an enterprise application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal)
and
[enabling SAML SSO](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso).

#### Step 2: Configure the Modal SAML settings

In "Basic SAML Configuration", enter the following values. Replace
`<workspace>` with your Modal Workspace name.

| Setting                            | Value                                               |
| ---------------------------------- | --------------------------------------------------- |
| Identifier (Entity ID)             | `https://www.modal.com`                             |
| Reply URL (Assertion Consumer URL) | `https://modal.com/api/okta/saml/sso/<workspace>`   |
| Sign on URL                        | `https://modal.com/login/sso?workspace=<workspace>` |

Save the configuration. The sign-on URL gives users an SP-initiated login path
for the configured Workspace.

#### Step 3: Configure SAML attributes and claims

In "Attributes & Claims", add or edit claims so the SAML assertion includes
the following attributes. Enter each attribute name exactly as shown and leave
its "Namespace" blank.

| Name      | Value          |
| --------- | -------------- |
| email     | user.mail      |
| firstName | user.givenname |
| lastName  | user.surname   |

If `user.mail` isn't populated for every user, map `email` from the Microsoft
Entra attribute that contains the email address your users use with Modal. For
example, some organizations use `user.userprincipalname` as their email source.

See Microsoft's documentation on
[adding attributes to token claims](https://learn.microsoft.com/en-us/entra/external-id/customers/how-to-add-attributes-to-token)
for details about configuring attributes and claims.

#### Step 4: Link your Workspace to Microsoft Entra Modal application

1. Navigate back to your Modal application in the Microsoft Entra admin center.
2. In the application's SAML configuration, find "SAML
   Certificates" and copy the "App Federation Metadata URL".
3. Sign in to https://modal.com and visit your [Workspace Management](/settings/workspace-management/identity-and-provisioning) page's "Identity and Provisioning" tab.
4. Paste the App Federation Metadata URL in the input and click "Save Changes".

#### Step 5: Assign users / groups and test the integration

1. Navigate back to your Modal application in the Microsoft Entra admin center.
2. Open "Users and groups" and assign the appropriate people or groups. See
   Microsoft's guide to
   [assigning users and groups](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/assign-user-or-group-access-portal)
   for detailed steps.
3. To test the integration, sign in as one of the users you assigned in the
   previous step.
4. Click on the Modal application in the
   [My Apps portal](https://myapps.microsoft.com/) to initiate Single Sign-On.
5. Confirm that the user is added to the expected Modal Workspace before
   enabling "Require SSO".

## SP-initiated SSO

The sign-in process is initiated from https://modal.com/login/sso

1. Enter your workspace name in the input
2. Click "continue with SSO" to authenticate with Microsoft Entra

## Troubleshooting

### Modal reports a missing SAML attribute

Confirm that the assertion contains `email`, `firstName`, and `lastName` with
the exact capitalization shown above. Each claim must have an empty namespace,
and its source attribute must contain a value for the affected user.

### A user can't open the application

Confirm that the user is assigned directly or through a supported group. Group
assignment requires Microsoft Entra ID P1 or P2, and assignments don't include
members of nested groups.

### Modal can't load the identity provider metadata

Confirm that you copied the "App Federation Metadata URL", rather than the
Login URL, Microsoft Entra Identifier, or a local certificate file.
