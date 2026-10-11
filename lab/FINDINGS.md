# Findings — Part 4 debug lab

## Defect 1 — Numeric non-root user missing

**Symptom** (actual output):

```text
FAIL  deployment backend: 0/1 ready
FAIL  deployment gateway: 0/1 ready
FAIL  deployment worker: 0/1 ready
FAIL  deployment reporter: 0/1 ready
FAIL  deployment metrics: 0/1 ready
```

Pod events explained why the containers could not start:

```text
Error: container has runAsNonRoot and image has non-numeric user (nonroot),
cannot verify user is non-root
```

The same event occurred for the migration pod.

**Cause**: The image declares a named user, `nonroot`. The chart set
`runAsNonRoot: true` but did not specify a numeric UID, so Kubernetes refused
to start the container because it could not verify the named image user was
non-root.

**Fix**: Set `runAsUser: 65532` in the container security context for the
migration Job and each Deployment. The image's `/etc/passwd` maps `nonroot` to
UID `65532`. This retains the non-root security requirement rather than
disabling it.

**How I found it**: Ran `./scenario.sh verify`, then inspected the affected
pods with `kubectl -n debug-lab describe pod ...`. The repeated kubelet event
identified the shared security-context cause. After assigning the numeric UID,
the Deployments became Ready in subsequent verification runs.

## Defect 2 — Invalid migration Job restart policy

**Symptom** (actual Helm output):

```text
Job.batch "migrate" is invalid: spec.template.spec.restartPolicy: Required value:
valid values: "OnFailure", "Never"
```

**Cause**: The Job template used `restartPolicy: Always`, which Kubernetes
does not allow for Jobs.

**Fix**: Set the Job's pod `restartPolicy` to `Never`, so the migration process
can terminate and the Job controller can record its completion.

**How I found it**: After resetting the namespace and running `./scenario.sh
up`, Helm rejected the rendered Job. The validation message names the invalid
field and the permitted values. Re-running `up` after correcting the policy
installed the release.

## Defect 3 — Migration Job overrides the image entrypoint with a missing shell

**Symptom**: The migration Job did not complete when its template set
`command: ["sh", "-c"]` and an `echo` argument. The image does not contain a
shell; running it with `/bin/sh` as the entrypoint produced:

```text
exec: "/bin/sh": stat /bin/sh: no such file or directory
```

**Cause**: The Job replaced the image's executable entrypoint with `sh`, which
is not present in this minimal application image.

**Fix**: Remove the shell command and arguments, and let the image's own
entrypoint run with `APP_MODE=migrate`. This avoids depending on a shell that
the image does not ship.

**How I found it**: Inspected the Job template and tested whether `/bin/sh`
exists in the image. After removing the command override and fixing the
container's numeric UID, the migration Job completed.

## Defect 4 — Worker cache path is on a read-only filesystem

**Symptom** (actual worker log):

```text
FATAL: worker could not initialise its cache: mkdir /var/cache/app: read-only
file system — the process needs a writable directory at /var/cache/app
```

**Cause**: The worker sets `CACHE_DIR=/var/cache/app` while its root
filesystem is read-only, but the pod template did not mount writable storage at
that path.

**Fix**: Mount an `emptyDir` volume at `/var/cache/app` and set pod
`fsGroup: 65532` so the non-root worker can write to the mounted directory.
The cache is runtime state, so an ephemeral volume is appropriate.

**How I found it**: After resolving the worker's container startup error, I
checked its logs. The explicit `mkdir` error pointed to the unwritable cache
directory. After adding the volume mount, the worker reached `Running` and
`1/1 Ready`.

## Defect 5 — Reporter RoleBinding targets the wrong ServiceAccount

**Symptom** (actual verification output):

```text
FAIL  ServiceAccount debug-lab/reporter cannot list pods
```

The reporter log also showed a Kubernetes API `403 Forbidden` stating that
`system:serviceaccount:debug-lab:reporter` could not list pods.

**Cause**: The RoleBinding granted the `reporter-read` Role to the `default`
ServiceAccount, while the reporter Deployment runs as the `reporter` account.

**Fix**: Change the RoleBinding subject from `default` to `reporter`, retaining
the existing namespace-scoped Role and its `get`/`list` permissions on pods.

**How I found it**: Compared `serviceAccountName` in the reporter Deployment
with the RoleBinding subject, then checked permission using
`kubectl auth can-i list pods -n debug-lab
--as=system:serviceaccount:debug-lab:reporter`. After changing the subject,
the verification check passed.

## Defect 6 — Reporter remains unready when its pod-list response is parsed

**Symptom** (actual reporter log and verification output):

```text
pod list failed: parse pod list: unexpected end of JSON input
GET /healthz -> 503
```

```text
FAIL  deployment reporter: 0/1 ready
FAIL  reporter /report does not return a pod count
```

**Cause**: Not confirmed. The RoleBinding fix made
`kubectl auth can-i list pods` return `yes`. A separate probe using the
reporter's ServiceAccount and UID successfully received and parsed a Kubernetes
`PodList` (`HTTP 200`, eight pods), while the reporter application continued to
log an unexpected EOF. The available evidence does not establish why the
application's own request gets an empty or incomplete body.

**Fix**: Unresolved; no speculative readiness or RBAC change was made to mask
the failing `/report` behavior.

**How I found it**: Read the reporter logs after correcting its ServiceAccount
binding, verified its namespace and projected token mount, and tested pod
listing as the same ServiceAccount. Next, I would capture the reporter's exact
request URL, HTTP status, response headers, and response-body byte count from
the application path, then compare those with the successful direct API probe.

## Submission note

The findings above describe the defects and fixes investigated during the lab
session. The requested `Downloads/eb-devops-takehome-v2. (1)` copy of the chart
was still at its original state when this file was prepared; make sure the
corresponding chart fixes and your terminal recording are present in the copy
you submit. The reporter issue remains unresolved, so the lab has not reached
`ALL GREEN`.