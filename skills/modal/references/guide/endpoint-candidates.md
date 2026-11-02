# Endpoint candidates

A [Dedicated Endpoint](/docs/guide/dedicated-endpoints) serves traffic from its
**production** deployment. Create **candidates** to test changes to your model
or weights without changing production. Each candidate has its own URL and
containers.

## Create a candidate

Open your Endpoint in the [dashboard](https://modal.com/endpoints), then open
the **Deployment** dropdown and choose **Create candidate**.

An Endpoint can have up to five candidates at once. Choose a
[Dedicated Endpoint model](/docs/guide/supported-models#dedicated-endpoint-models) with the same task type as
production: text generation or embeddings. To use custom weights, select **Custom weights**, then provide a
Hugging Face repository and revision or a Modal Volume and path. The weights
must be compatible with the selected base model; see
[Serve custom weights](/docs/guide/dedicated-endpoints#serve-custom-weights).

Changes to the source weights do not update an existing candidate. Promotion
uses the same weights you tested.

Candidates start with the serving recipe's autoscaling defaults, not
production's settings.

## Test a candidate

Select the candidate in the **Deployment** dropdown and wait for provisioning
to finish. Copy its URL from the dashboard to
[send test requests](/docs/guide/endpoints#call-an-endpoint). Candidates use
production's [model name](/docs/guide/endpoints#model-names) and authentication
settings.

## Mirror production traffic

Traffic mirroring copies production requests to a candidate. Clients receive
production's responses; candidate responses are discarded.

Select a provisioned candidate, click **Mirror traffic**, and choose the
percentage of traffic to copy. You can mirror to multiple candidates, each with
its own percentage. To disable it, open the mirroring control and click
**Stop mirroring**.

Mirrored requests can scale up the candidate and incur compute charges.

## Promote a candidate

Select the candidate and click **Promote**. Promotion starts a new production
rollout using the candidate's model, weights, and serving recipe. The production
URL and request model name stay the same.

Production keeps its minimum, maximum, and buffer container settings and its
scale-up and scale-down windows. Candidate autoscaling changes do not carry
over to production.

Promotion removes the candidate when the rollout starts and stops its mirrored
traffic. Its URL is no longer available; other candidates are unchanged.

To change back after a successful promotion, create and promote a new candidate
using the previous model or weights.

## Delete a candidate

Select the candidate and click **Delete candidate**. Deletion stops its
containers and any mirrored traffic to it. Production and other candidates are
unaffected.

Stopping the Endpoint stops all its candidates.

## Pricing

You pay for the [compute resources](/pricing) each candidate's containers use.
A candidate scaled to zero does not incur compute charges.
